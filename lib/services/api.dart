import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/models/user_model.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/models/plant_step_model.dart';
import 'package:root2route/models/plant_details_response.dart';
import 'package:root2route/models/create_auction_request.dart';
import 'package:root2route/models/product_model.dart';
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
          if (e.response?.statusCode == 401 && !e.requestOptions.path.contains('/refresh-token')) {
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
                
                if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
                  final newAccess = refreshResponse.data['accessToken'] ?? currToken;
                  final newRefresh = refreshResponse.data['refreshToken'] ?? currRefresh;
                  
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
                NavigatorService.navigatorKey.currentState?.pushNamedAndRemoveUntil(LoginScreen.id, (Route<dynamic> route) => false);
                return handler.next(e);
              }
            } else {
              // Missing refresh token, force logout
              await storage.logout();
              NavigatorService.navigatorKey.currentState?.pushNamedAndRemoveUntil(LoginScreen.id, (Route<dynamic> route) => false);
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
      return {"success": false, "message": "Unexpected error during verification: $e"};
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
    required String description,
    required String address,
    required String contactEmail,
    required String contactPhone,
    required int type,
    XFile? logo,
  }) async {
    try {
      final ownerId = StorageService().userId;
      if (ownerId == null || ownerId.isEmpty)
        throw Exception("User not logged in");

      String formattedPhone = _formatPhoneNumber(contactPhone);

      final formData = FormData.fromMap({
        'OwnerId': ownerId,
        'Name': name,
        'Description': description,
        'Address': address,
        'ContactEmail': contactEmail,
        'ContactPhone': formattedPhone,
        'Type': type.toString(),
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
      final formData = FormData();

      formData.fields.addAll([
        MapEntry('OrganizationId', organizationId),
        MapEntry('OwnerId', ownerId),
        MapEntry('Name', name),
        MapEntry('Description', description),
        MapEntry('Address', address),
        MapEntry('ContactEmail', contactEmail),
        MapEntry('ContactPhone', formattedPhone),
        MapEntry('Type', type.toString()),
      ]);

      if (logo != null) {
        formData.files.add(
          MapEntry(
            'Logo',
            await MultipartFile.fromFile(
              logo.path,
              filename: 'logo_${DateTime.now().millisecondsSinceEpoch}.png',
            ),
          ),
        );
      }

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
      message = "Server Error: ${e.response?.statusMessage} (${e.response?.statusCode})";
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

  Future<void> logout() async {
    await StorageService().logout();
    print("User logged out and token cleared.");
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
    String barcode = '',
    String? expiryDate,
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
        'Barcode': barcode,
        'WeightUnit': weightUnit.toString(),
        'ProductType': productType.toString(),
      };

      if (expiryDate != null && expiryDate.isNotEmpty) {
        dataMap['ExpiryDate'] = expiryDate;
      }

      // Attach image files
      if (images.isNotEmpty) {
        final List<MultipartFile> multipartFiles = [];
        for (final xfile in images) {
          String filename = xfile.name;
          if (filename.isEmpty) {
            filename = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
          } else if (!filename.contains('.')) {
            filename = '$filename.jpg'; // Ensure filename has an extension
          }
          multipartFiles.add(
            await MultipartFile.fromFile(xfile.path, filename: filename),
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

  // ── 2. Update Product ──────────────────────────────────────
  Future<Map<String, dynamic>> updateProduct({
    required String id,
    required String name,
    String description = '',
    required int stockQuantity,
    bool isAvailableForDirectSale = false,
    double directSalePrice = 0.0,
    bool isAvailableForAuction = false,
    double startBiddingPrice = 0.0,
    String barcode = '',
    String? expiryDate, // ISO-8601
    int weightUnit = 0,
    int productType = 0,
  }) async {
    try {
      final token = StorageService().token;

      final Map<String, dynamic> body = {
        'id': id,
        'name': name,
        'description': description,
        'stockQuantity': stockQuantity,
        'isAvailableForDirectSale': isAvailableForDirectSale,
        'directSalePrice': directSalePrice,
        'isAvailableForAuction': isAvailableForAuction,
        'startBiddingPrice': startBiddingPrice,
        'barcode': barcode,
        'expiryDate': expiryDate ?? '',
        'weightUnit': weightUnit,
        'productType': productType,
      };

      final response = await _dio.put(
        '/product/Update',
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      final respBody = response.data;
      if (respBody is Map) {
        final succeeded = respBody['succeeded'] ?? respBody['success'] ?? true;
        return {
          'success': succeeded,
          'data': respBody['data'],
          'message': respBody['message'] ?? 'Product updated successfully',
        };
      }

      return {
        'success': true,
        'data': null,
        'message': 'Product updated successfully',
      };
    } on DioException catch (e) {
      final errBody = e.response?.data;

      if (errBody is Map && errBody['succeeded'] == true) {
        return {
          'success': true,
          'data': errBody['data'],
          'message': errBody['message'] ?? 'Product updated successfully',
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

  // ── 3. Delete Product ──────────────────────────────────────
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

  // ── 4. Get All Products ────────────────────────────────────
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

  
  Future<List<ProductModel>> getMarketProducts({String? search}) async {
    try {
      final result = await getAllProducts(
        search: search,
        pageSize: 100,
      );

      if (result['success'] == true && result['data'] is List) {
        final rawList = result['data'] as List<dynamic>;

        final models = rawList
            .whereType<Map<String, dynamic>>()
            .map(ProductModel.fromJson)
            .where((p) => p.isAvailableForDirectSale)
            .toList();

        // Return real data if we got any
        if (models.isNotEmpty) return models;
      }
    } catch (e) {
      debugPrint('getMarketProducts real fetch failed: $e');
    }

    // ── Mock fallback ────────────────────────────────────────
    debugPrint('getMarketProducts: returning mock data');
    return _mockMarketProducts;
  }

  static final List<ProductModel> _mockMarketProducts = [
    ProductModel(
      id: 'mock-1',
      organizationId: 'org-1',
      name: 'Fresh Tomatoes',
      description: 'Sun-ripened Roma tomatoes, harvested this morning.',
      images: const [
        'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=400'
      ],
      stockQuantity: 50,
      isAvailableForDirectSale: true,
      directSalePrice: 4000,
      isAvailableForAuction: false,
      startBiddingPrice: 0,
      organizationName: 'Green Valley Farms',
    ),
    ProductModel(
      id: 'mock-2',
      organizationId: 'org-2',
      name: 'Organic Potatoes',
      description: '1kg bag of fresh organic potatoes.',
      images: const [
        'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=400'
      ],
      stockQuantity: 120,
      isAvailableForDirectSale: true,
      directSalePrice: 1500,
      isAvailableForAuction: false,
      startBiddingPrice: 0,
      organizationName: 'Nile Delta Co-op',
    ),
    ProductModel(
      id: 'mock-3',
      organizationId: 'org-3',
      name: 'Strawberries',
      description: 'Sweet and juicy strawberries, 500g punnet.',
      images: const [
        'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=400'
      ],
      stockQuantity: 30,
      isAvailableForDirectSale: true,
      directSalePrice: 6500,
      isAvailableForAuction: false,
      startBiddingPrice: 0,
      organizationName: 'Sunrise Agriculture',
    ),
    ProductModel(
      id: 'mock-4',
      organizationId: 'org-1',
      name: 'Bell Peppers Mix',
      description: 'Colourful mix of red, green, and yellow peppers.',
      images: const [
        'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=400'
      ],
      stockQuantity: 80,
      isAvailableForDirectSale: true,
      directSalePrice: 3200,
      isAvailableForAuction: false,
      startBiddingPrice: 0,
      organizationName: 'Green Valley Farms',
    ),
    ProductModel(
      id: 'mock-5',
      organizationId: 'org-4',
      name: 'Honey – Raw Wildflower',
      description: 'Pure, unfiltered wildflower honey. 500ml jar.',
      images: const [
        'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=400'
      ],
      stockQuantity: 15,
      isAvailableForDirectSale: true,
      directSalePrice: 12000,
      isAvailableForAuction: false,
      startBiddingPrice: 0,
      organizationName: 'Desert Bee Co.',
    ),
    ProductModel(
      id: 'mock-6',
      organizationId: 'org-2',
      name: 'White Onions',
      description: 'Large white onions. 2kg bag.',
      images: const [
        'https://images.unsplash.com/photo-1508747703725-719777637510?w=400'
      ],
      stockQuantity: 200,
      isAvailableForDirectSale: true,
      directSalePrice: 900,
      isAvailableForAuction: false,
      startBiddingPrice: 0,
      organizationName: 'Nile Delta Co-op',
    ),
  ];

  // ── 5. Get Product By Id ───────────────────────────────────
  Future<Map<String, dynamic>> getProductById(String id) async {
    try {
      final token = StorageService().token;

      final response = await _dio.get(
        '/product/$id',
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      final body = response.data;
      return {
        'success': body['succeeded'] ?? true,
        'data': body['data'],
        'message': body['message'] ?? 'Success',
      };
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response!.data;

        if (errorData is Map && errorData['succeeded'] == true) {
          return {
            'success': true,
            'data': errorData['data'],
            'message': errorData['message'] ?? 'Success',
          };
        }

        return {
          'success': false,
          'message': errorData['message'] ?? 'Product not found',
        };
      }
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
        
        List<PlantStepModel> steps = dataList
            .map((json) => PlantStepModel.fromJson(json as Map<String, dynamic>))
            .toList();

        steps.sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

        return {
          'success': true,
          'data': steps,
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to load steps.',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? e.message ?? 'Network error.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred.',
      };
    }
  }

  // Fetch plant-specific details and steps
  Future<Map<String, dynamic>> getPlantDetails(String id) async {
    try {
      final response = await _dio.get('/plant-guide-steps/by-plant/$id');

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
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? e.message ?? 'Network error.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred.',
      };
    }
  }

  // ── Auctions ──────────────────────────────────────────────
  Future<Map<String, dynamic>> createAuction(
      CreateAuctionRequest request) async {
    try {
      final response = await _dio.post(
        '/auctions/create',
        data: request.toJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final body = response.data;
      if (body is Map) {
        final succeeded = body['succeeded'] ?? body['success'] ?? true;
        return {
          'success': succeeded,
          'data': body['data'],
          'message': body['message'] ?? 'Auction created successfully',
        };
      }

      return {
        'success': true,
        'data': null,
        'message': 'Auction created successfully',
      };
    } on DioException catch (e) {
      final errBody = e.response?.data;

      // Handle cases where backend returns 4xx but body says succeeded: true
      if (errBody is Map && (errBody['succeeded'] == true || errBody['success'] == true)) {
        return {
          'success': true,
          'data': errBody['data'],
          'message': errBody['message'] ?? 'Auction created successfully',
        };
      }

      final message = (errBody is Map)
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

  // ── Auctions ────────────────────────────────────────────────

  /// Fetches all active auctions from the server.
  Future<Map<String, dynamic>> getAuctions() async {
    try {
      final response = await _dio.get('/api/v1/auctions/GetActive');
      print('GetActive Response: ${response.data}');
      final data = response.data;
      return {
        'success': data['succeeded'] ?? true,
        'data': data['data'] ?? [],
        'message': data['message'] ?? 'Success',
      };
    } on DioException catch (e) {
      print('GetActive Error: ${e.response?.data}');
      return {'success': false, 'data': [], 'message': _extractApiError(e)};
    } catch (e) {
      print('GetActive Exception: $e');
      return {
        'success': false,
        'data': [],
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Places a bid on an auction.
  Future<Map<String, dynamic>> placeBid({
    required String auctionId,
    required double bidAmount,
  }) async {
    try {
      final response = await _dio.post(
        '/auctions/$auctionId/bid',
        data: {'bidAmount': bidAmount},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final data = response.data;
      return {
        'success': data['succeeded'] ?? true,
        'data': data['data'],
        'message': data['message'] ?? 'Bid placed successfully',
      };
    } on DioException catch (e) {
      return {'success': false, 'data': null, 'message': _extractApiError(e)};
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }
}
