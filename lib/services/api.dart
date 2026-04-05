import 'dart:io';
 import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/models/user_model.dart';
import 'package:root2route/services/storage_service.dart';
//offline mode
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
          return handler.next(options);
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
        );

        await StorageService().saveIsVerified(isVerified);

        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
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
      return {"success": true, "message": "Success"};
    } on DioException catch (e) {
      return {"success": false, "message": _extractApiError(e)};
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
        "message": response.data['message'] ?? "Verification code sent successfully",
      };
    } on DioException catch (e) {
      return {"success": false, "message": _extractApiError(e)};
    } catch (err) {
      return {"success": false, "message": "An unexpected error occurred: $err"};
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
      return {"success": false, "message": "An unexpected error occurred: $err"};
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
        'Type': type,
        if (logo != null)
          'Logo': MultipartFile.fromBytes(
            await logo.readAsBytes(),
            filename:
                logo.name.isNotEmpty
                    ? logo.name
                    : 'logo_${DateTime.now().millisecondsSinceEpoch}.png',
          ),
      });

      final response = await _dio.post('/organizations', data: formData);

      return {
        "success": true,
        "data": response.data,
        "message": "Organization created successfully",
      };
    } on DioException catch (e) {
      return {"success": false, "message": _extractApiError(e)};
    } catch (e) {
      return {"success": false, "message": "An unexpected error occurred"};
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

      if (errorData['errors'] != null && errorData['errors'] is Map) {
        final errors = errorData['errors'] as Map;
        if (errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            message = firstError[0].toString();
          } else {
            message = firstError.toString();
          }
        }
      }
    } else if (errorData is String) {
      message = errorData;
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
}
