import 'dart:io';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/features/account/models/change_password_request_model.dart';
import 'package:root2route/models/auction_model.dart';
import 'package:root2route/models/user_model.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/models/plant_step_model.dart';
import 'package:root2route/models/plant_details_response.dart';
import 'package:root2route/core/navigator_service.dart';
import 'package:flutter/material.dart';
import 'package:root2route/screens/auth/login_screen.dart';

class ApiService {
  final Dio _dio = Dio();

  ApiService() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = StorageService().token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // Inject active org context so backend knows which org we're in
          final orgId = StorageService().organizationId;
          if (orgId != null && orgId.isNotEmpty) {
            options.headers['X-Organization-Id'] = orgId;
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 &&
              !e.requestOptions.path.contains('/refresh-token')) {
            final storage = StorageService();
            final currToken = storage.token;
            final currRefresh = storage.refreshToken;
            final currOrg = storage.organizationId;

            if (currToken != null && currRefresh != null) {
              try {
                final refreshResponse = await _dio.post(
                  '/refresh-token',
                  data: {
                    "accessToken": currToken,
                    "refreshToken": currRefresh,
                    "organizationId": currOrg ?? "",
                  },
                );

                if (refreshResponse.statusCode == 200 &&
                    refreshResponse.data != null) {
                  final newAccess =
                      refreshResponse.data['accessToken'] ?? currToken;
                  final newRefresh =
                      refreshResponse.data['refreshToken'] ?? currRefresh;

                  await storage.saveTokens(
                    accessToken: newAccess,
                    refreshToken: newRefresh,
                  );

                  // Update the failed request with the new token
                  final opts = e.requestOptions;
                  opts.headers['Authorization'] = 'Bearer $newAccess';

                  // Retry the original request
                  final retryResponse = await _dio.fetch(opts);
                  return handler.resolve(retryResponse);
                }
              } catch (err) {
                // Refresh token also failed/expired
                await storage.logout();
                NavigatorService.navigatorKey.currentState
                    ?.pushNamedAndRemoveUntil(
                      LoginScreen.id,
                      (Route<dynamic> route) => false,
                    );
                return handler.next(e);
              }
            } else {
              // Missing refresh token, force logout
              await storage.logout();
              NavigatorService.navigatorKey.currentState
                  ?.pushNamedAndRemoveUntil(
                    LoginScreen.id,
                    (Route<dynamic> route) => false,
                  );
            }
          }
          return handler.next(e);
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );
  }

  Future<void> registerUser(UserModel user) async {
    try {
      final response = await _dio.post('/auth/register', data: user.toJson());
      print("Register Success: ${response.data}");
    } on DioException catch (e) {
      throw Exception(_extractApiError(e));
    }
  }

  Future<void> loginUser(String userName, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          "userName": userName,
          "password": password,
          "isRememberMe": true,
        },
      );

      final data = response.data['data'];
      if (data != null) {
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];
        final fullName = data['fullName'];
        final expireAt = data['expireAt'];

        final userId = _extractUserIdFromToken(accessToken);
        final isVerified = data['user']?['isVerified'] ?? true;

        await StorageService().saveAuthData(
          token: accessToken,
          userId: userId,
          email: userName,
          fullName: fullName ?? '',
          expireAt: expireAt ?? '',
          refreshToken: refreshToken,
        );

        await StorageService().saveIsVerified(isVerified);

        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
        debugPrint("Login success. Token: $accessToken");
        await Future.delayed(const Duration(milliseconds: 500));

        final hasOrganization = await _checkUserHasOrganizations();
        await StorageService().saveHasOrganization(hasOrganization);

        // 🔔 Send FCM token to backend after successful login
        await sendFcmToken();

        print("Login Successfully!");
      } else {
        throw Exception("Invalid login response format");
      }
    } on DioException catch (e) {
      throw Exception(_extractApiError(e));
    } catch (e) {
      throw Exception("An unexpected error occurred: $e");
    }
  }

  /// Sends the device's FCM token to the backend so the server can deliver
  /// push notifications to this specific device.
  ///
  /// - Endpoint : POST /api/v1/users/fcm-token
  /// - Auth     : Bearer token is injected automatically by the Dio interceptor.
  /// - Silent   : Errors are caught and logged — they never bubble up to the UI.
  Future<void> sendFcmToken() async {
    try {
      // Require an authenticated session before sending the token.
      final bearerToken = StorageService().token;
      if (bearerToken == null || bearerToken.isEmpty) {
        debugPrint('[FCM] Skipping token upload — user is not logged in.');
        return;
      }

      // firebase_messaging is imported in main.dart; we call getToken() via
      // the static FirebaseMessaging instance here to keep api.dart decoupled
      // from firebase_messaging. We import it only for this method.
      final fcmToken = await _getFcmToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint(
          '[FCM] Could not retrieve FCM device token. Skipping upload.',
        );
        return;
      }

      await _dio.post('/users/fcm-token', data: {"fcmToken": fcmToken});

      debugPrint('[FCM] ✅ FCM token sent to backend successfully.');
    } on DioException catch (e) {
      // Non-critical — log and continue. Never throw from here.
      debugPrint(
        '[FCM] ⚠️ Failed to send FCM token (DioException): ${_extractApiError(e)}',
      );
    } catch (e) {
      debugPrint('[FCM] ⚠️ Failed to send FCM token (unexpected): $e');
    }
  }

  /// Internal helper that retrieves the current FCM token from Firebase.
  /// Returns null if Firebase Messaging is unavailable or the token cannot
  /// be fetched (e.g. no network, permissions denied).
  Future<String?> _getFcmToken() async {
    try {
      // Import kept local to avoid a hard dependency on firebase_messaging
      // in every file that imports api.dart.
      final messaging = _firebaseMessagingInstance;
      return await messaging?.call();
    } catch (e) {
      debugPrint('[FCM] _getFcmToken error: $e');
      return null;
    }
  }

  // A late-bound callback so that api.dart does not need to import
  // firebase_messaging directly. main.dart injects the provider once
  // Firebase is fully initialised via [setFcmTokenProvider].
  static Future<String?> Function()? _firebaseMessagingInstance;

  /// Call this once in main.dart (after Firebase.initializeApp) to register
  /// the FCM token provider. Example:
  ///
  /// ```dart
  /// ApiService.setFcmTokenProvider(
  ///   () => FirebaseMessaging.instance.getToken(),
  /// );
  /// ```
  static void setFcmTokenProvider(Future<String?> Function() provider) {
    _firebaseMessagingInstance = provider;
  }

  Future<void> resendOTP({required String email}) async {
    try {
      await _dio.post('/auth/resend-otp', data: {"email": email});
    } catch (e) {
      throw Exception("Failed to resend code");
    }
  }

  Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otpCode,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verify-otp',
        data: {"email": email.trim(), "otp": otpCode.trim()},
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      debugPrint("OTP Verification Response: ${response.data}");

      final data = response.data['data'];
      if (data != null && data['accessToken'] != null) {
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];
        final fullName = data['fullName'];
        final expireAt = data['expireAt'];
        final userId = _extractUserIdFromToken(accessToken);
        final isVerified = data['user']?['isVerified'] ?? true;

        await StorageService().saveAuthData(
          token: accessToken,
          userId: userId,
          email: email,
          fullName: fullName ?? '',
          expireAt: expireAt ?? '',
          refreshToken: refreshToken,
        );
        await StorageService().saveIsVerified(isVerified);
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';

        return {"success": true, "message": "Success", "hasToken": true};
      }

      return {"success": true, "message": "Success", "hasToken": false};
    } on DioException catch (e) {
      debugPrint("OTP Verification Failed: ${e.response?.data}");
      return {"success": false, "message": _extractApiError(e)};
    } catch (e) {
      debugPrint("OTP Verification Error: $e");
      return {
        "success": false,
        "message": "Unexpected error during verification: $e",
      };
    }
  }

  Future<Map<String, dynamic>> forgetPassword(String email) async {
    try {
      final response = await _dio.post(
        '/auth/forget-password',
        data: {"email": email.trim().toLowerCase()},
        options: Options(headers: {"Content-Type": "application/json"}),
      );
      return {
        "success": true,
        "message":
            response.data['message'] ?? "Verification code sent successfully",
      };
    } on DioException catch (e) {
      return {"success": false, "message": _extractApiError(e)};
    } catch (err) {
      return {
        "success": false,
        "message": "An unexpected error occurred: $err",
      };
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {
          "email": email.trim().toLowerCase(),
          "otp": otp.trim(),
          "newPassword": newPassword,
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.data != null && response.data is Map) {
        if (response.data['success'] == false ||
            response.data['isSuccess'] == false) {
          return {
            "success": false,
            "message": response.data['message'] ?? "Failed to change password.",
          };
        }
      }

      return {
        "success": true,
        "message": response.data['message'] ?? "Password changed successfully",
      };
    } on DioException catch (e) {
      return {"success": false, "message": _extractApiError(e)};
    } catch (err) {
      return {
        "success": false,
        "message": "An unexpected error occurred: $err",
      };
    }
  }

  Future<bool> _checkUserHasOrganizations() async {
    try {
      final token = StorageService().token;
      final response = await _dio.get(
        '/organizations/my',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data != null && response.data['data'] != null) {
        final organizations = response.data['data'];
        if (organizations is List && organizations.isNotEmpty) {
          // Persist the first organization's ID so it's available everywhere
          final firstOrg = organizations.first;
          if (firstOrg is Map) {
            final orgId =
                firstOrg['id']?.toString() ??
                firstOrg['organizationId']?.toString() ??
                firstOrg['OrganizationId']?.toString() ??
                '';
            if (orgId.isNotEmpty) {
              await StorageService().saveOrganizationId(orgId);
              debugPrint('[Login] Saved organizationId: $orgId');
            }

            final orgType = firstOrg['type'] ?? firstOrg['Type'];
            if (orgType != null) {
              int typeVal;
              if (orgType is int) {
                typeVal = orgType;
              } else {
                typeVal = int.tryParse(orgType.toString()) ?? 0;
              }
              await StorageService().saveOrganizationType(typeVal);
              debugPrint('[Login] Saved organizationType: $typeVal');
            }
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> createOrganization({
    required String name,
    required int type,
    required File complianceFile,
    String? description,
    String? address,
    String? contactEmail,
    String? contactPhone,
    XFile? logo,
  }) async {
    try {
      final ownerId = StorageService().userId;
      if (ownerId == null || ownerId.isEmpty) {
        throw Exception("User not logged in");
      }

      final formData = FormData.fromMap({
        'OwnerId': ownerId,
        'Name': name,
        'Type': type.toString(),
        if (description != null && description.isNotEmpty)
          'Description': description,
        if (address != null && address.isNotEmpty)
          'Address': address,
        if (contactEmail != null && contactEmail.isNotEmpty)
          'ContactEmail': contactEmail,
        if (contactPhone != null && contactPhone.isNotEmpty)
          'ContactPhone': _formatPhoneNumber(contactPhone),
        'ComplianceFile': await MultipartFile.fromFile(
          complianceFile.path,
          filename: complianceFile.path.split(Platform.pathSeparator).last,
        ),
        if (logo != null)
          'Logo': MultipartFile.fromBytes(
            await logo.readAsBytes(),
            filename: () {
              String name = logo.name;
              if (name.isEmpty)
                return 'logo_${DateTime.now().millisecondsSinceEpoch}.png';
              if (!name.contains('.')) return '$name.png';
              return name;
            }(),
          ),
      });

      final response = await _dio.post('/organizations', data: formData);

      return {
        "success": true,
        "data": response.data,
        "message": "Organization created successfully",
      };
    } on DioException catch (e) {
      debugPrint("Create Org Failed: ${e.response?.data}");
      return {"success": false, "message": _extractApiError(e)};
    } catch (e) {
      debugPrint("Create Org Unexpected Error: $e");
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> updateOrganization({
    required String organizationId,
    required String name,
    required String description,
    required String address,
    required String contactEmail,
    required String contactPhone,
    required int type,
    File? logo,
  }) async {
    try {
      final ownerId = StorageService().userId;
      if (ownerId == null || ownerId.isEmpty)
        throw Exception("User not logged in");
      if (organizationId.isEmpty)
        return {"success": false, "message": "Organization ID is missing!"};

      String formattedPhone = _formatPhoneNumber(contactPhone);
      final formData = FormData.fromMap({
        'OrganizationId': organizationId,
        'OwnerId': ownerId,
        'Name': name,
        'Description': description,
        'Address': address,
        'ContactEmail': contactEmail,
        'ContactPhone': formattedPhone,
        'Type': type.toString(),
        if (logo != null)
          'Logo': await MultipartFile.fromFile(
            logo.path,
            filename: 'logo_${DateTime.now().millisecondsSinceEpoch}.png',
          ),
      });

      final response = await _dio.put('/organizations', data: formData);

      return {
        "success": true,
        "data": response.data,
        "message": "Organization updated successfully",
      };
    } on DioException catch (e) {
      return {"success": false, "message": _extractApiError(e)};
    } catch (e) {
      return {"success": false, "message": "An unexpected error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> getOrganizations() async {
    try {
      final response = await _dio.get('/organizations');
      final data = response.data;
      return {
        "success": data['succeeded'] ?? true,
        "data": data['data'] ?? [],
        "message": data['message'] ?? 'Success',
      };
    } on DioException catch (e) {
      return {"success": false, "message": _extractApiError(e)};
    }
  }

  Future<Map<String, dynamic>> getMyOrganizations() async {
    try {
      final response = await _dio.get('/organizations/my');
      final data = response.data;
      return {
        "success": data['succeeded'] ?? true,
        "data": data['data'] ?? [],
        "message": data['message'] ?? 'Success',
      };
    } on DioException catch (e) {
      return {"success": false, "message": _extractApiError(e)};
    }
  }

  Future<Map<String, dynamic>> getMyInvitations() async {
    try {
      final token = StorageService().token;
      final response = await _dio.get(
        '/organization-invitations/my',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      return {
        "success": data['succeeded'] ?? true,
        "data": data['data'] ?? [],
        "message": data['message'] ?? 'Success',
      };
    } on DioException catch (e) {
      return {"success": false, "message": _extractApiError(e)};
    }
  }

  Future<Map<String, dynamic>> acceptInvitation(String invitationId) async {
    try {
      final token = StorageService().token;

      // الـ Swagger طالب الـ InvitationId والـ token كـ queryParameters
      // وبما إن الـ Curl كان فيه -d '' ، ده معناه إننا نبعت body فاضي
      final response = await _dio.post(
        '/organization-invitations/accept', // تأكد من المسار الكامل هنا
        queryParameters: {'InvitationId': invitationId, 'token': token},
        data: {},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final responseData = response.data;

      // فحص النتيجة بناءً على الـ API structure
      if (responseData is Map && responseData['succeeded'] == false) {
        throw Exception(responseData['message'] ?? 'فشل في قبول الدعوة');
      }

      return {
        "success": true,
        "message": responseData['message'] ?? "تم قبول الدعوة بنجاح",
        "data": responseData,
      };
    } on DioException catch (e) {
      // استخراج الرسالة من السيرفر لو موجودة، بدل الرسالة العامة
      String errorMessage = _extractApiError(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> rejectInvitation(String invitationId) async {
    try {
      final token = StorageService().token;
      final response = await _dio.put(
        '/organization-invitations/$invitationId/reject',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {"success": true, "message": "Invitation rejected successfully"};
    } on DioException catch (e) {
      return {"success": false, "message": _extractApiError(e)};
    }
  }

  Future<Map<String, dynamic>> getOrganizationById(String id) async {
    try {
      final response = await _dio.get('/organizations/$id');
      final data = response.data;
      return {
        "success": data['succeeded'] ?? true,
        "data": data['data'],
        "message": data['message'] ?? 'Success',
      };
    } on DioException catch (e) {
      return {"success": false, "message": _extractApiError(e)};
    }
  }

  Future<Map<String, dynamic>> getOrganizationStatistics(String id) async {
    try {
      final response = await _dio.get('/organizations/$id/statistics');
      final data = response.data;
      return {
        "success": data['succeeded'] ?? true,
        "data": data['data'],
        "message": data['message'] ?? 'Success',
      };
    } on DioException catch (e) {
      return {"success": false, "message": _extractApiError(e)};
    }
  }

  Future<Map<String, dynamic>> deleteOrganization(String id) async {
    try {
      final response = await _dio.delete('/organizations/$id');
      return {
        "success": true,
        "data": response.data,
        "message": "Organization deleted successfully",
      };
    } on DioException catch (e) {
      return {"success": false, "message": _extractApiError(e)};
    }
  }

  Future<Map<String, dynamic>> changeOrganizationOwner({
    required String organizationId,
    required String newOwnerId,
  }) async {
    try {
      final response = await _dio.put(
        '/organizations/$organizationId/change-owner',
        data: '"$newOwnerId"',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return {
        "success": true,
        "data": response.data,
        "message": "The transfer of ownership was successful.",
      };
    } on DioException catch (e) {
      return {"success": false, "message": _extractApiError(e)};
    }
  }

  Future<Map<String, dynamic>?> analyzeCropImage(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "ImageFile": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });

      final response = await _dio.post(
        '/model-analysis/analyze',
        data: formData,
        options: Options(
          validateStatus: (status) => status! < 501,
          headers: {"accept": "*/*", "Content-Type": "multipart/form-data"},
        ),
      );

      if (response.data is Map<String, dynamic>) return response.data;
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> PalntInfoAll() async {
    try {
      final response = await _dio.get('/plant-info/all');
      final data = response.data;
      return {
        "success": data['succeeded'] ?? true,
        "data": data['data'],
        "message": data['message'] ?? 'Success',
      };
    } on DioException catch (e) {
      return {"success": false, "message": _extractApiError(e)};
    }
  }

  String _extractApiError(DioException e) {
    if (e.response == null) {
      return "No Internet Connection - Please check your network";
    }

    dynamic errorData = e.response?.data;
    String message = "Something went wrong";

    if (errorData is Map) {
      message =
          errorData['message'] ??
          errorData['msg'] ??
          errorData['error'] ??
          errorData['title'] ??
          message;

      if (errorData['errors'] != null) {
        final errors = errorData['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            message = firstError[0].toString();
          } else {
            message = firstError.toString();
          }
        } else if (errors is List && errors.isNotEmpty) {
          message = errors[0].toString();
        }
      }
    } else if (errorData is String && errorData.isNotEmpty) {
      message = errorData;
    } else if (e.response?.statusMessage != null) {
      message =
          "Server Error: ${e.response?.statusMessage} (${e.response?.statusCode})";
    }

    // fallback to raw representation if "Something went wrong" persisted
    if (message == "Something went wrong" && errorData != null) {
      message = "Error: ${errorData.toString()}";
    }

    return message;
  }

  String _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return '';

      String payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final decodedBytes = Uri.decodeComponent(payload);
      final jsonString = utf8.decode(base64Url.decode(decodedBytes));
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      return jsonData['sub'] ??
          jsonData['id'] ??
          jsonData['uid'] ??
          jsonData['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
          '';
    } catch (e) {
      return '';
    }
  }

  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '+2$cleaned';
    } else if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }
    return cleaned;
  }

  String? getToken() => StorageService().token;
  String? getUserId() => StorageService().userId;
  bool isLoggedIn() => StorageService().isLoggedIn;

  Future<bool> refreshAuthToken() async {
    final String? accToken = StorageService().token;
    final String? refToken = StorageService().refreshToken;
    final String? orgId = StorageService().organizationId;

    if (accToken == null || refToken == null) return false;

    try {
      final response = await _dio.post(
        '/refresh-token',
        data: {
          "accessToken": accToken,
          "refreshToken": refToken,
          "organizationId": orgId ?? "",
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final newAccess = response.data['accessToken'] ?? accToken;
        final newRefresh = response.data['refreshToken'] ?? refToken;

        await StorageService().saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh,
        );
        return true;
      }
    } catch (e) {
      debugPrint('Silent token refresh failed: $e');
    }
    return false;
  }

  Future<void> logout() async {
    await StorageService().logout();
    print("User logged out and token cleared.");
  }

  Future<void> deleteMyAccount() async {
    try {
      final token = StorageService().token;
      if (token == null || token.isEmpty) {
        throw Exception('User is not authenticated.');
      }

      await _dio.delete(
        '/users/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // Clear local storage after successful deletion
      await StorageService().logout();
      print("User account deleted and local data cleared.");
    } on DioException catch (e) {
      throw Exception(_extractApiError(e));
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  Future<void> changePassword(ChangePasswordRequestModel request) async {
    try {
      final token = StorageService().token;
      if (token == null || token.isEmpty) {
        throw Exception('User is not authenticated.');
      }

      final response = await _dio.post(
        '/auth/change-password',
        data: request.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data != null && response.data is Map) {
        if (response.data['success'] == false ||
            response.data['isSuccess'] == false ||
            response.data['succeeded'] == false) {
          throw Exception(
            response.data['message'] ?? 'Failed to change password.',
          );
        }
      }
    } on DioException catch (e) {
      throw Exception(_extractApiError(e));
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  Future<Map<String, dynamic>> addProduct({
    required String organizationId,
    required String name,
    String description = '',
    required int stockQuantity,
    bool isAvailableForDirectSale = false,
    double directSalePrice = 0.0,
    bool isAvailableForAuction = false,
    double startBiddingPrice = 0.0,
    String? expiryDate,
    String? barcode,
    int weightUnit = 0,
    int productType = 0,
    List<XFile> images = const [],
  }) async {
    try {
      final token = StorageService().token;

      final Map<String, dynamic> dataMap = {
        'OrganizationId': organizationId,
        'Name': name,
        'Description': description,
        'StockQuantity': stockQuantity.toString(),
        'IsAvailableForDirectSale': isAvailableForDirectSale.toString(),
        'DirectSalePrice': directSalePrice.toString(),
        'IsAvailableForAuction': isAvailableForAuction.toString(),
        'StartBiddingPrice': startBiddingPrice.toString(),
        'WeightUnit': weightUnit.toString(),
        'ProductType': productType.toString(),
      };

      if (expiryDate != null && expiryDate.isNotEmpty) {
        dataMap['ExpiryDate'] = expiryDate;
      }

      if (barcode != null && barcode.isNotEmpty) {
        dataMap['Barcode'] = barcode;
      }

      // Attach image files
      if (images.isNotEmpty) {
        final List<MultipartFile> multipartFiles = [];
        for (int i = 0; i < images.length; i++) {
          final xfile = images[i];
          File file = File(xfile.path);

          // 1. Read the actual file bytes (Magic Numbers)
          List<int> headerBytes = [];
          try {
            headerBytes = await file.openRead(0, 12).first;
          } catch (e) {
            debugPrint("Could not read file headers: $e");
          }

          // 2. Detect MIME type from bytes
          String? mimeType = lookupMimeType(
            file.path,
            headerBytes: headerBytes,
          );
          mimeType ??= 'image/jpeg';

          // 3. Safe MIME parsing with guards
          List<String> mimeParts = mimeType.split('/');
          String type = mimeParts.isNotEmpty ? mimeParts.first : 'image';
          String subtype = mimeParts.length > 1 ? mimeParts.last : 'jpeg';

          // 4. Normalize subtype edge cases
          if (subtype.isEmpty || subtype == 'octet-stream') subtype = 'jpeg';

          // 5. Get extension safely
          String extension = subtype == 'jpeg' ? 'jpg' : subtype;
          if (extension.isEmpty) extension = 'jpg'; // ← الحل الأساسي

          // 6. Build bulletproof filename
          String cleanFileName =
              'image_${DateTime.now().millisecondsSinceEpoch}_$i.$extension';

          debugPrint('Uploading: $cleanFileName | MIME: $type/$subtype');

          // 7. Append to FormData
          multipartFiles.add(
            await MultipartFile.fromFile(
              file.path,
              filename: cleanFileName,
              contentType: MediaType(type, subtype),
            ),
          );
        }
        dataMap['Images'] = multipartFiles;
      }

      final formData = FormData.fromMap(dataMap);

      final response = await _dio.post(
        '/product/Add',
        data: formData,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      final respBody = response.data;
      if (respBody is Map) {
        final succeeded = respBody['succeeded'] ?? respBody['success'] ?? true;
        return {
          'success': succeeded,
          'data': respBody['data'],
          'message': respBody['message'] ?? 'Product added successfully',
        };
      }

      return {
        'success': true,
        'data': null,
        'message': 'Product added successfully',
      };
    } on DioException catch (e) {
      final errBody = e.response?.data;

      if (errBody is Map && errBody['succeeded'] == true) {
        return {
          'success': true,
          'data': errBody['data'],
          'message': errBody['message'] ?? 'Product added successfully',
        };
      }

      final message =
          (errBody is Map)
              ? (errBody['message'] ?? _extractApiError(e))
              : _extractApiError(e);
      return {'success': false, 'data': null, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateProduct({
    required String id,
    required String name,
    required String description,
    required int stockQuantity,
    required bool isAvailableForDirectSale,
    required double directSalePrice,
    required bool isAvailableForAuction,
    required double startBiddingPrice,
    String? expiryDate,
    String? barcode,
    required int weightUnit,
    required int productType,
  }) async {
    try {
      final token = StorageService().token;

      final response = await _dio.put(
        '/product/Update',
        data: {
          "id": id,
          "name": name,
          "description": description,
          "stockQuantity": stockQuantity,
          "isAvailableForDirectSale": isAvailableForDirectSale,
          "directSalePrice": directSalePrice,
          "isAvailableForAuction": isAvailableForAuction,
          "startBiddingPrice": startBiddingPrice,
          "expiryDate": expiryDate,
          "barcode": barcode,
          "weightUnit": weightUnit,
          "productType": productType,
        },
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      final respBody = response.data;

      if (respBody is Map) {
        final succeeded =
            respBody['succeeded'] == true || respBody['success'] == true;
        return {
          'success': succeeded,
          'data': respBody['data'],
          // Message in English
          'message':
              succeeded
                  ? 'Product updated successfully.'
                  : (respBody['message'] ?? 'Update failed.'),
        };
      }

      return {
        'success': response.statusCode == 200 || response.statusCode == 204,
        'data': null,
        'message': 'Product updated successfully.',
      };
    } on DioException catch (e) {
      final errBody = e.response?.data;

      if (errBody is Map) {
        // 👈👈👈 Solution: Catch 400 Error and check for success field inside it
        final isBackendWeirdSuccess =
            errBody['succeeded'] == true || errBody['success'] == true;

        if (isBackendWeirdSuccess) {
          return {
            'success': true, // Force application to consider it success
            'data': errBody['data'],
            'message':
                'Product updated successfully.', // 👈 Unified English message
          };
        }

        return {
          'success': false,
          'data': null,
          'message': errBody['message'] ?? _extractApiError(e),
        };
      }

      return {
        'success': false,
        'data': null,
        'message': errBody?.toString() ?? _extractApiError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteProduct(String id) async {
    try {
      final token = StorageService().token;

      final response = await _dio.delete(
        '/product/Delete/$id',
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      final respBody = response.data;
      if (respBody is Map) {
        final succeeded = respBody['succeeded'] ?? respBody['success'] ?? true;
        return {
          'success': succeeded,
          'data': null,
          'message': respBody['message'] ?? 'Product deleted successfully',
        };
      }

      return {
        'success': true,
        'data': null,
        'message': 'Product deleted successfully',
      };
    } on DioException catch (e) {
      final errBody = e.response?.data;

      if (errBody is Map && errBody['succeeded'] == true) {
        return {
          'success': true,
          'data': null,
          'message': errBody['message'] ?? 'Product deleted successfully',
        };
      }

      final message =
          (errBody is Map)
              ? (errBody['message'] ?? _extractApiError(e))
              : _extractApiError(e);
      return {'success': false, 'data': null, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  // ─── Public Auction Marketplace ──────────────────────────────────────────

  Future<Map<String, dynamic>> getActiveAuctions() async {
    try {
      final token = StorageService().token;

      final response = await _dio.get(
        '/auctions/GetActive',
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      final respBody = response.data;
      if (respBody is Map) {
        return {
          'success':
              respBody['succeeded'] == true || respBody['success'] == true,
          'data': respBody['data'] ?? respBody,
          'message': respBody['message'] ?? 'Active auctions loaded',
        };
      }
      if (respBody is List) {
        return {'success': true, 'data': respBody, 'message': ''};
      }
      return {'success': true, 'data': [], 'message': ''};
    } on DioException catch (e) {
      final errBody = e.response?.data;
      final message =
          (errBody is Map)
              ? (errBody['message'] ?? _extractApiError(e))
              : _extractApiError(e);
      return {'success': false, 'data': null, 'message': message};
    } catch (e) {
      return {'success': false, 'data': null, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCompletedAuctions() async {
    try {
      final token = StorageService().token;

      final response = await _dio.get(
        '/auctions/GetCompleted',
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      final respBody = response.data;
      if (respBody is Map) {
        return {
          'success':
              respBody['succeeded'] == true || respBody['success'] == true,
          'data': respBody['data'] ?? respBody,
          'message': respBody['message'] ?? 'Completed auctions loaded',
        };
      }
      if (respBody is List) {
        return {'success': true, 'data': respBody, 'message': ''};
      }
      return {'success': true, 'data': [], 'message': ''};
    } on DioException catch (e) {
      final errBody = e.response?.data;
      final message =
          (errBody is Map)
              ? (errBody['message'] ?? _extractApiError(e))
              : _extractApiError(e);
      return {'success': false, 'data': null, 'message': message};
    } catch (e) {
      return {'success': false, 'data': null, 'message': e.toString()};
    }
  }

  // ── Buyer Auction Dashboard ──────────────────────────────────────────────

  /// GET /api/v1/auctions/my-participated
  Future<Map<String, dynamic>> getMyParticipatedAuctions() async {
    try {
      final response = await _dio.get('/auctions/my-participated');

      final respBody = response.data;
      if (respBody is Map) {
        return {
          'success':
              respBody['succeeded'] == true || respBody['success'] == true,
          'data': respBody['data'] ?? respBody,
          'message': respBody['message'] ?? 'Participated auctions loaded',
        };
      }
      if (respBody is List) {
        return {'success': true, 'data': respBody, 'message': ''};
      }
      return {'success': true, 'data': [], 'message': ''};
    } on DioException catch (e) {
      final errBody = e.response?.data;
      final message =
          (errBody is Map)
              ? (errBody['message'] ?? _extractApiError(e))
              : _extractApiError(e);
      return {'success': false, 'data': null, 'message': message};
    } catch (e) {
      return {'success': false, 'data': null, 'message': e.toString()};
    }
  }

  /// GET /api/v1/auctions/my-won
  Future<Map<String, dynamic>> getMyWonAuctions() async {
    try {
      final response = await _dio.get('/auctions/my-won');

      final respBody = response.data;
      if (respBody is Map) {
        return {
          'success':
              respBody['succeeded'] == true || respBody['success'] == true,
          'data': respBody['data'] ?? respBody,
          'message': respBody['message'] ?? 'Won auctions loaded',
        };
      }
      if (respBody is List) {
        return {'success': true, 'data': respBody, 'message': ''};
      }
      return {'success': true, 'data': [], 'message': ''};
    } on DioException catch (e) {
      final errBody = e.response?.data;
      final message =
          (errBody is Map)
              ? (errBody['message'] ?? _extractApiError(e))
              : _extractApiError(e);
      return {'success': false, 'data': null, 'message': message};
    } catch (e) {
      return {'success': false, 'data': null, 'message': e.toString()};
    }
  }

  /// POST /api/v1/auctions/{id}/checkout
  Future<Map<String, dynamic>> checkoutAuction(String auctionId) async {
    try {
      final response = await _dio.post('/auctions/$auctionId/checkout');

      final respBody = response.data;
      if (respBody is Map) {
        final isSuccess =
            respBody['succeeded'] == true || respBody['success'] == true;
        return {
          'success': isSuccess,
          'data': respBody['data'],
          'message':
              isSuccess
                  ? (respBody['message'] ?? 'Checkout completed successfully!')
                  : (respBody['message'] ?? 'Checkout failed.'),
        };
      }
      return {
        'success': response.statusCode == 200,
        'data': null,
        'message': 'Checkout completed successfully!',
      };
    } on DioException catch (e) {
      final errBody = e.response?.data;
      if (errBody is Map) {
        final isBackendWeirdSuccess =
            errBody['succeeded'] == true || errBody['success'] == true;
        if (isBackendWeirdSuccess) {
          return {
            'success': true,
            'data': errBody['data'],
            'message': errBody['message'] ?? 'Checkout completed successfully!',
          };
        }
        return {
          'success': false,
          'data': null,
          'message': errBody['message'] ?? _extractApiError(e),
        };
      }
      return {'success': false, 'data': null, 'message': _extractApiError(e)};
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Unexpected error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getAllProducts({
    int? pageNumber,
    int? pageSize,
    int? status,
    String? search,
    int? productType,
  }) async {
    try {
      final token = StorageService().token;

      final Map<String, dynamic> params = {};
      if (pageNumber != null) params['PageNumber'] = pageNumber;
      if (pageSize != null) params['PageSize'] = pageSize;
      if (status != null) params['Status'] = status;
      if (search != null && search.isNotEmpty) params['Search'] = search;
      if (productType != null) params['ProductType'] = productType;

      final response = await _dio.get(
        '/product/GetAll',
        queryParameters: params.isEmpty ? null : params,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      final body = response.data;
      if (body is! Map) {
        return {
          'success': false,
          'data': null,
          'message': 'Unexpected response format',
        };
      }

      // Backend may wrap list in { data: { items:[...] } } or { data: [...] }
      final dynamic dataField = body['data'] ?? body;
      final List<dynamic> items;
      if (dataField is Map && dataField.containsKey('items')) {
        items = (dataField['items'] as List?) ?? [];
      } else if (dataField is List) {
        items = dataField;
      } else {
        items = [];
      }

      return {
        'success': body['succeeded'] ?? true,
        'data': items,
        'message': body['message'] ?? 'Success',
      };
    } on DioException catch (e) {
      final errBody = e.response?.data;
      final message =
          (errBody is Map)
              ? (errBody['message'] ?? _extractApiError(e))
              : _extractApiError(e);
      return {'success': false, 'data': null, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getProductById(String id) async {
    try {
      final token = StorageService().token;

      final response = await _dio.get(
        '/product/$id',
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
          validateStatus: (status) => status != null && status <= 400,
        ),
      );

      final body = response.data;
      final int statusCode = response.statusCode ?? 0;

      if (body is Map) {
        final bool isSuccess =
            (statusCode == 200) ||
            (statusCode == 400 && body['succeeded'] == true);

        if (isSuccess) {
          return {
            'success': true,
            'data': body['data'],
            'message': body['message'] ?? 'Success',
          };
        } else {
          return {
            'success': false,
            'message': body['message'] ?? 'Product not found',
          };
        }
      }

      return {'success': statusCode == 200, 'data': body, 'message': 'Success'};
    } on DioException catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  // ── 6. Get Organization Products ───────────────────────────
  Future<Map<String, dynamic>> getOrganizationProducts(
    String organizationId, {
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      final token = StorageService().token;

      final Map<String, dynamic> params = {};
      if (pageNumber != null) params['PageNumber'] = pageNumber;
      if (pageSize != null) params['PageSize'] = pageSize;

      final response = await _dio.get(
        '/product/Organization/$organizationId',
        queryParameters: params.isEmpty ? null : params,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      final body = response.data;
      if (body is! Map) {
        return {
          'success': false,
          'data': null,
          'message': 'Unexpected response format',
        };
      }

      // Backend may wrap list in { data: { items:[...] } } or { data: [...] }
      final dynamic dataField = body['data'] ?? body;
      final List<dynamic> items;
      if (dataField is Map && dataField.containsKey('items')) {
        items = (dataField['items'] as List?) ?? [];
      } else if (dataField is List) {
        items = dataField;
      } else {
        items = [];
      }

      return {
        'success': body['succeeded'] ?? true,
        'data': items,
        'message': body['message'] ?? 'Success',
      };
    } on DioException catch (e) {
      final errBody = e.response?.data;
      final message =
          (errBody is Map)
              ? (errBody['message'] ?? _extractApiError(e))
              : _extractApiError(e);
      return {'success': false, 'data': null, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  Future<Map<String, dynamic>> fetchPlantGuideSteps() async {
    try {
      final response = await _dio.get('/plant-guide-steps/all');

      if (response.statusCode == 200 && response.data['succeeded'] == true) {
        final List<dynamic> dataList = response.data['data'] ?? [];

        List<PlantStepModel> steps =
            dataList
                .map(
                  (json) =>
                      PlantStepModel.fromJson(json as Map<String, dynamic>),
                )
                .toList();

        steps.sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

        return {'success': true, 'data': steps};
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to load steps.',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data?['message'] ?? e.message ?? 'Network error.',
      };
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred.'};
    }
  }

  // Fetch plant-specific details and steps
  Future<Map<String, dynamic>> getPlantDetails(String id) async {
    try {
final response = await _dio.get('/plant-guide-step/plant-id/$id');
      // 1. نتأكد إن الداتا راجعة على هيئة Map (JSON Object)
      if (response.data is Map<String, dynamic>) {
        if (response.statusCode == 200 && response.data['succeeded'] == true) {
          final data = response.data['data'];
          if (data != null) {
            final plantDetails = PlantDetailsResponse.fromJson(data);
            return {
              'success': true,
              'data': plantDetails.steps, // Extracted pre-sorted steps array
            };
          }
        }
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to load details.',
        };
      } else {
        // لو السيرفر رجع نص غريب بدل الـ JSON
        return {
          'success': false,
          'message': 'Invalid response format from server.',
        };
      }
    } on DioException catch (e) {
      // 2. معالجة آمنة للإيرور عشان لو السيرفر رجع نص (زي صيانة السيرفر)
      String errorMessage = 'Network error.';

      if (e.response?.data is Map<String, dynamic>) {
        // لو الإيرور راجع كـ JSON
        errorMessage = e.response?.data['message'] ?? e.message ?? errorMessage;
      } else if (e.response?.data is String) {
        // لو الإيرور راجع كنص عادي أو HTML
        errorMessage = e.response?.data;
      }

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred.'};
    }
  }

  // ── CREATE AUCTION ─────────────────────────────────────
  // POST /api/v1/auctions/create
  Future<AuctionModel> createAuction({
    required String title,
    required String productId,
    required double startingPrice,
    required double minimumBidIncrement,
    required double reservePrice,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // 1. Change path to /auctions/create
      final response = await _dio.post(
        '/auctions/create',
        data: {
          "title": title,
          // 2. Convert date to ISO 8601 UTC (to add 'Z' at the end)
          "startDate": startDate.toUtc().toIso8601String(),
          "endDate": endDate.toUtc().toIso8601String(),
          // 3. Ensured keys match Swagger exactly
          "startPrice": startingPrice,
          "minimumBidIncrement": minimumBidIncrement,
          "reservePrice": reservePrice,
          "productId": productId,
        },
      );

      final data = _extractData(response.data);
      if (data is Map<String, dynamic>) {
        return AuctionModel.fromJson(data);
      }

      return AuctionModel(
        id: data?.toString() ?? '',
        title: title,
        productId: productId,
        startingPrice: startingPrice,
        minimumBidIncrement: minimumBidIncrement,
        reservePrice: reservePrice,
        startDate: startDate,
        endDate: endDate,
        status: 'Upcoming',
      );
    } on DioException catch (e) {
      // LogInterceptor will print details, but we throw correct error for UI anyway
      throw AuctionException(_extractApiError(e));
    } catch (e) {
      throw AuctionException('Failed to create auction: $e');
    }
  }

  // ── GET MY ORGANIZATION AUCTIONS ───────────────────────
  // GET /api/v1/auctions/my-organization/{organizationId}
  Future<List<AuctionModel>> getMyOrganizationAuctions(
    String organizationId,
  ) async {
    try {
      final response = await _dio.get(
        '/auctions/my-organization/$organizationId',
      );
      return _parseList(
        response.data,
      ).map((json) => AuctionModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw AuctionException(_extractApiError(e));
    } catch (e) {
      throw AuctionException('Failed to fetch auctions: $e');
    }
  }

  // ── UPDATE AUCTION ─────────────────────────────────────
  // PUT /api/v1/auctions/{auctionId}/update
  Future<AuctionModel> updateAuction({
    required String auctionId,
    required String title,
    required double startingPrice,
    required double minimumBidIncrement,
    required double reservePrice,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.put(
        '/auctions/$auctionId/update',
        data: {
          'title': title,
          'startPrice': startingPrice,
          'minimumBidIncrement': minimumBidIncrement,
          'reservePrice': reservePrice,
          'startDate': startDate.toUtc().toIso8601String(),
          'endDate': endDate.toUtc().toIso8601String(),
        },
      );
      final data = _extractData(response.data);
      if (data is Map<String, dynamic>) {
        return AuctionModel.fromJson(data);
      }
      return AuctionModel(
        id: auctionId,
        productId: '',
        title: title,
        startingPrice: startingPrice,
        minimumBidIncrement: minimumBidIncrement,
        reservePrice: reservePrice,
        startDate: startDate,
        endDate: endDate,
        status: 'upcoming',
      );
    } on DioException catch (e) {
      throw AuctionException(_extractApiError(e));
    } catch (e) {
      throw AuctionException('Failed to update auction: $e');
    }
  }

  // ── CANCEL AUCTION ─────────────────────────────────────
  // DELETE /api/v1/auctions/{auctionId}/cancel
  Future<void> cancelAuction(String auctionId) async {
    try {
      await _dio.delete('/auctions/$auctionId/cancel');
    } on DioException catch (e) {
      throw AuctionException(_extractApiError(e));
    } catch (e) {
      throw AuctionException('Failed to cancel auction: $e');
    }
  }

  // ── GET AUCTION BY ID ──────────────────────────────────
  // GET /api/v1/auctions/{id}
  Future<AuctionModel> getAuctionById(String id) async {
    try {
      final response = await _dio.get('/auctions/$id');
      final data = _extractData(response.data);
      if (data is Map<String, dynamic>) {
        return AuctionModel.fromJson(data);
      }
      throw AuctionException('Invalid response format');
    } on DioException catch (e) {
      throw AuctionException(_extractApiError(e));
    } catch (e) {
      throw AuctionException('Failed to fetch auction details: $e');
    }
  }

  // ── GET BID HISTORY ────────────────────────────────────
  // GET /api/v1/auctions/{auctionId}/bids
  Future<List<BidModel>> getBidHistory(String auctionId) async {
    try {
      final response = await _dio.get('/auctions/$auctionId/bids');
      return _parseList(
        response.data,
      ).map((json) => BidModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw AuctionException(_extractApiError(e));
    } catch (e) {
      throw AuctionException('Failed to fetch bid history: $e');
    }
  }

  // 1. Fetch Bid History (raw map)
  Future<Map<String, dynamic>> getAuctionBids(String auctionId) async {
    try {
      final token = StorageService().token;
      final response = await _dio.get(
        '/auctions/$auctionId/bids',
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      final respBody = response.data;
      if (respBody is Map) {
        return {
          'success': respBody['succeeded'] ?? respBody['success'] ?? true,
          'data': respBody['data'] ?? [],
          'message': respBody['message'] ?? 'Bids fetched successfully',
        };
      }
      return {'success': true, 'data': respBody, 'message': 'Success'};
    } on DioException catch (e) {
      final errBody = e.response?.data;
      if (errBody is Map) {
        return {
          'success': false,
          'data': null,
          'message': errBody['message'] ?? _extractApiError(e),
        };
      }
      return {'success': false, 'data': null, 'message': _extractApiError(e)};
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Unexpected error: $e',
      };
    }
  }

  // 1b. Fetch Bid History as typed BidModel list
  Future<List<BidModel>> getAuctionBidsAsBidModels(String auctionId) async {
    try {
      final response = await _dio.get('/auctions/$auctionId/bids');
      return _parseList(
          response.data,
        ).map((json) => BidModel.fromJson(json)).toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
    } on DioException catch (e) {
      throw AuctionException(_extractApiError(e));
    } catch (e) {
      throw AuctionException('Failed to fetch bids: $e');
    }
  }

  // 2. Place Bid
  // POST /auctions/{auctionId}/bid  body: { "amount": <double> }
  Future<Map<String, dynamic>> placeBid({
    required String auctionId,
    required double amount,
  }) async {
    try {
      final token = StorageService().token;

      // ── Explicitly parse to double to guarantee a JSON number, not a string ──
      final double bidAmount =
          amount; // already a double from the controller parse

      debugPrint(
        '[💰 BID] Sending to /auctions/$auctionId/bid  amount=$bidAmount',
      );

      final response = await _dio.post(
        '/auctions/$auctionId/bid',
        data: {"amount": bidAmount},
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
          // Let Dio pass ALL responses through so we can inspect the body
          validateStatus: (status) => status != null && status < 600,
          contentType: 'application/json',
        ),
      );

      final int statusCode = response.statusCode ?? 0;
      final dynamic respBody = response.data;

      debugPrint('[💰 BID] Response status: $statusCode');
      debugPrint('[💰 BID] Response body: $respBody');

      if (respBody is Map) {
        final bool isSuccess =
            (statusCode >= 200 && statusCode < 300) ||
            respBody['succeeded'] == true ||
            respBody['success'] == true;

        final String message =
            isSuccess
                ? (respBody['message']?.toString() ??
                    'تم تقديم المزايدة بنجاح!')
                : (respBody['message']?.toString() ??
                    respBody['title']?.toString() ??
                    respBody['error']?.toString() ??
                    'فشل تقديم المزايدة.');

        return {
          'success': isSuccess,
          'data': respBody['data'],
          'message': message,
          'statusCode': statusCode,
        };
      }

      // Non-map response — treat 200..299 as success
      final bool ok = statusCode >= 200 && statusCode < 300;
      return {
        'success': ok,
        'data': null,
        'message': ok ? 'تم تقديم المزايدة بنجاح!' : 'فشل تقديم المزايدة.',
        'statusCode': statusCode,
      };
    } on DioException catch (e) {
      // Should rarely reach here since validateStatus covers most codes,
      // but keep as a safety net (e.g., connection timeouts).
      debugPrint('[🔥 BID DioException] status: ${e.response?.statusCode}');
      debugPrint('[🔥 BID DioException] body: ${e.response?.data}');

      final errBody = e.response?.data;
      String message;
      if (errBody is Map) {
        message =
            errBody['message']?.toString() ??
            errBody['title']?.toString() ??
            errBody['error']?.toString() ??
            _extractApiError(e);
      } else {
        message = _extractApiError(e);
      }
      return {'success': false, 'data': null, 'message': message};
    } catch (e) {
      debugPrint('[🔥 BID unexpected] $e');
      return {
        'success': false,
        'data': null,
        'message': 'Unexpected error: $e',
      };
    }
  }

  // ── GET APPROVED PRODUCTS (for create-auction dropdown) ─
  Future<List<Map<String, dynamic>>> getApprovedProducts(
    String organizationId,
  ) async {
    try {
      final response = await _dio.get(
        '/product/Organization/$organizationId',
        queryParameters: {'Status': 1},
      );
      return _parseList(response.data);
    } on DioException catch (e) {
      throw AuctionException(_extractApiError(e));
    } catch (e) {
      throw AuctionException('Failed to fetch products: $e');
    }
  }
}

class AuctionException implements Exception {
  final String message;
  const AuctionException(this.message);

  @override
  String toString() => message;
}

dynamic _extractData(dynamic body) {
  if (body is Map) return body['data'] ?? body;
  return body;
}

List<Map<String, dynamic>> _parseList(dynamic body) {
  List<dynamic> items = [];
  if (body is Map) {
    final dataField = body['data'] ?? body;
    if (dataField is List) {
      items = dataField;
    } else if (dataField is Map && dataField.containsKey('items')) {
      items = (dataField['items'] as List?) ?? [];
    }
  } else if (body is List) {
    items = body;
  }
  return items.whereType<Map<String, dynamic>>().toList();
}
