import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/models/user_model.dart';
import 'package:root2route/services/storage_service.dart';
import 'dart:convert';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final Dio _dio = Dio();
  final String _defaultOrgId = "3fa85f64-5717-4562-b3fc-2c963f66afa6";

  ApiService._internal() {
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
          options.headers['X-Organization-Id'] = _defaultOrgId;
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
      if (e.response != null) {
        print("Server Error (${e.response?.statusCode}): ${e.response?.data}");
        dynamic data = e.response?.data;
        String message = "Something went wrong";
        if (data is Map) {
          message = data['message'] ?? data['msg'] ?? "Error occurred";
        } else if (data is String) {
          message = data;
        }
        throw Exception(message);
      } else {
        throw Exception("No Internet Connection");
      }
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

    print("📱 Login API Response: ${response.data}");

    final data = response.data['data'];
    if (data != null) {
      final accessToken = data['accessToken'];
      final fullName = data['fullName'];
      final expireAt = data['expireAt'];

      final userId = _extractUserIdFromToken(accessToken);
      final isVerified = data['user']?['isVerified'] ?? true;

      // ✅ الخطوة 1: حفظ بيانات المصادقة أولاً
      await StorageService().saveAuthData(
        token: accessToken,
        userId: userId,
        email: userName,
        fullName: fullName ?? '',
        expireAt: expireAt ?? '',
      );

      await StorageService().saveIsVerified(isVerified);

      print("✅ Auth data saved, token: $accessToken");
      
      // ✅ الخطوة 2: نضبط التوكن في الـ Dio headers بشكل مباشر
      _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      
      // ✅ الخطوة 3: ننتظر شوية عشان نتأكد إن التوكن اتثبت
      await Future.delayed(const Duration(milliseconds: 500));
      
      // ✅ الخطوة 4: نتحقق من وجود شركات
      final hasOrganization = await _checkUserHasOrganizations();
      
      // حفظ حالة وجود منظمة
      await StorageService().saveHasOrganization(hasOrganization);

      print("✅ Login Successfully!");
      print("   - User ID: $userId");
      print("   - Full Name: $fullName");
      print("   - Email: $userName");
      print("   - isVerified: $isVerified");
      print("   - hasOrganization: $hasOrganization"); // ✅ اتأكد من القيمة هنا
      print("   - Token Expiry: $expireAt");
    } else {
      print("⚠️ No data field in login response");
      throw Exception("Invalid login response format");
    }
  } on DioException catch (e) {
      print("❌ Login Error - DioException:");
      if (e.response != null) {
        print("   Status Code: ${e.response?.statusCode}");
        print("   Response Data: ${e.response?.data}");

        dynamic errorData = e.response?.data;
        String message = "Something went wrong";

        if (errorData is Map) {
          // محاولة استخراج رسالة الخطأ من أكثر من مكان
          message =
              errorData['message'] ??
              errorData['msg'] ??
              errorData['error'] ??
              errorData['title'] ??
              "Error occurred";

          // إذا كان فيه تفاصيل أكثر للخطأ
          if (errorData['errors'] != null && errorData['errors'] is Map) {
            final errors = errorData['errors'] as Map;
            if (errors.isNotEmpty) {
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                message = firstError[0].toString();
              }
            }
          }
        } else if (errorData is String) {
          message = errorData;
        }

        throw Exception(message);
      } else {
        print("   Network Error: ${e.message}");
        throw Exception("No Internet Connection - Please check your network");
      }
    } catch (e) {
      print("❌ Unexpected Login Error: $e");
      throw Exception("An unexpected error occurred: $e");
    }
  }

  Future<bool> _checkUserHasOrganizations() async {
  try {
    print("🔍 Checking user organizations...");
    
    // ✅ نضبط التوكن في الـ request headers بشكل صريح
    final token = StorageService().token;
    print("🔍 Token being used: ${token != null ? "Token exists (${token.substring(0, min(20, token.length))}...)" : "No token"}");
    
    final response = await _dio.get(
      '/organizations/my',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'X-Organization-Id': _defaultOrgId,
        },
      ),
    );
    
    print("🔍 Organizations API Response: ${response.data}");
    
    if (response.data != null && response.data['data'] != null) {
      final organizations = response.data['data'];
      
      // إذا كان فيه شركات وعددها أكبر من 0
      if (organizations is List && organizations.isNotEmpty) {
        print("✅ User has ${organizations.length} organization(s)");
        // طباعة تفاصيل أول شركة للتأكد
        print("   First organization: ${organizations[0]['name'] ?? 'No name'}");
        return true;
      } else {
        print("ℹ️ Organizations list is empty");
      }
    } else {
      print("ℹ️ No data field in response");
    }
    
    print("ℹ️ User has no organizations");
    return false;
  } on DioException catch (e) {
    print("❌ Error checking organizations: ${e.response?.data}");
    print("❌ Status code: ${e.response?.statusCode}");
    print("❌ Headers sent: ${e.requestOptions.headers}");
    
    // لو حصل خطأ، نعتبر مفيش شركات
    return false;
  } catch (e) {
    print("❌ Unexpected error checking organizations: $e");
    return false;
  }
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

      // البحث عن الـ userId في التوكن
      // حسب الـ claims اللي عندك، الـ userId موجود في 'sub' أو 'nameidentifier'
      return jsonData['sub'] ??
          jsonData['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
          '';
    } catch (e) {
      print("Error extracting userId from token: $e");
      return '';
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
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "X-Organization-Id": _defaultOrgId,
          },
        ),
      );
      return {"success": true, "message": "Success"};
    } on DioException catch (e) {
      debugPrint("  Error Data: ${e.response?.data}");
      return {
        "success": false,
        "message": e.response?.data['message'] ?? "Invalid OTP",
      };
    }
  }

  Future<Map<String, dynamic>> forgetPassword(String email) async {
    try {
      debugPrint("  Requesting OTP for: '${email.trim()}'");
      final response = await _dio.post(
        '/auth/forget-password',
        data: {"email": email.trim().toLowerCase()},
        options: Options(
          headers: {
            "X-Organization-Id": _defaultOrgId,
            "Content-Type": "application/json",
          },
        ),
      );
      return {
        "success": true,
        "message": response.data['message'] ?? "تم إرسال كود التحقق بنجاح",
      };
    } on DioException catch (e) {
      String errorMsg = "فشل إرسال الكود";
      if (e.response?.data is Map) {
        errorMsg = e.response?.data['message'] ?? errorMsg;
      }
      debugPrint(" Forget Password Server Error: ${e.response?.data}");
      return {"success": false, "message": errorMsg};
    } catch (err) {
      return {"success": false, "message": "حدث خطأ غير متوقع: $err"};
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
        options: Options(
          headers: {
            "X-Organization-Id": _defaultOrgId,
            "Content-Type": "application/json",
          },
        ),
      );
      return {
        "success": true,
        "message": response.data['message'] ?? "تم تغيير كلمة المرور بنجاح",
      };
    } on DioException catch (e) {
      String errorMsg = "فشل تغيير كلمة المرور";
      if (e.response?.data is Map) {
        errorMsg = e.response?.data['message'] ?? errorMsg;
      }
      debugPrint("🛑 Reset Password Error: ${e.response?.data}");
      return {"success": false, "message": errorMsg};
    } catch (err) {
      return {"success": false, "message": "حدث خطأ غير متوقع: $err"};
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
          // التعديل هنا: بنخلي Dio يقبل كود 400 وما يرميش Error
          validateStatus: (status) => status! < 501,
          headers: {
            "X-Organization-Id": _defaultOrgId,
            "accept": "*/*",
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      if (response.data is Map<String, dynamic>) {
        return response.data;
      }

      return null;
    } on DioException catch (e) {
      debugPrint("AI SERVER ERROR: ${e.response?.data}");
      return null;
    } catch (e) {
      debugPrint("Unexpected Error: $e");
      return null;
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

      if (ownerId == null || ownerId.isEmpty) {
        throw Exception("User not logged in");
      }

      print("  Creating organization with ownerId: $ownerId");

      // ✅ إضافة تنسيق رقم الهاتف
      String formattedPhone = _formatPhoneNumber(contactPhone);

      // إنشاء FormData
      final formData = FormData.fromMap({
        'OwnerId': ownerId,
        'Name': name,
        'Description': description,
        'Address': address,
        'ContactEmail': contactEmail,
        'ContactPhone': formattedPhone, // ✅ استخدام الرقم المنسق
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

      final response = await _dio.post(
        '/organizations',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      print("✅ Organization created successfully: ${response.data}");

      return {
        "success": true,
        "data": response.data,
        "message": "Organization created successfully",
      };
    } on DioException catch (e) {
      print("❌ Error creating organization: ${e.response?.data}");

      String errorMsg = "Failed to create organization";
      if (e.response?.data is Map) {
        final errors = e.response?.data['errors'];
        if (errors != null && errors is Map) {
          errorMsg = errors.values.first[0];
        } else {
          errorMsg =
              e.response?.data['message'] ??
              e.response?.data['title'] ??
              errorMsg;
        }
      } else if (e.response?.data is String) {
        errorMsg = e.response?.data;
      }

      return {"success": false, "message": errorMsg};
    } catch (e) {
      print("❌ Unexpected error: $e");
      return {"success": false, "message": "An unexpected error occurred"};
    }
  }

  // ✅ دالة مساعدة لتنسيق رقم الهاتف
  String _formatPhoneNumber(String phone) {
    // إزالة أي مسافات أو شرطات
    String cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');

    // إذا كان الرقم بيبدأ بـ 0، نحوله للصيغة الدولية
    if (cleaned.startsWith('0')) {
      // مثال: 01234567890 -> +201234567890
      cleaned = '+2$cleaned';
    }
    // إذا كان الرقم مش بيبدأ بـ +، نضيف +
    else if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }

    return cleaned;
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
      print("❌ Error fetching organizations: ${e.response?.data}");

      String errorMsg = "فشل جلب المنظمات";
      if (e.response?.data is Map) {
        errorMsg = e.response?.data['message'] ?? errorMsg;
      } else if (e.response?.data is String) {
        errorMsg = e.response?.data;
      }

      return {"success": false, "message": errorMsg};
    } catch (e) {
      print("❌ Unexpected error: $e");
      return {"success": false, "message": "حدث خطأ غير متوقع: $e"};
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
      print("❌ Error fetching my organizations: ${e.response?.data}");

      String errorMsg = "فشل جلب منظماتي";
      if (e.response?.data is Map) {
        errorMsg = e.response?.data['message'] ?? errorMsg;
      } else if (e.response?.data is String) {
        errorMsg = e.response?.data;
      }

      return {"success": false, "message": errorMsg};
    } catch (e) {
      print("❌ Unexpected error: $e");
      return {"success": false, "message": "حدث خطأ غير متوقع: $e"};
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
      print("❌ Error fetching organization: ${e.response?.data}");

      String errorMsg = "فشل جلب تفاصيل المنظمة";
      if (e.response?.data is Map) {
        errorMsg = e.response?.data['message'] ?? errorMsg;
      } else if (e.response?.data is String) {
        errorMsg = e.response?.data;
      }

      return {"success": false, "message": errorMsg};
    } catch (e) {
      print("❌ Unexpected error: $e");
      return {"success": false, "message": "حدث خطأ غير متوقع: $e"};
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

    if (ownerId == null || ownerId.isEmpty) {
      throw Exception("User not logged in");
    }

    print("============================================");
    print("📦 STARTING ORGANIZATION UPDATE...");
    print("📦 organizationId: '$organizationId'");
    print("📦 OwnerId: '$ownerId'");

    if (organizationId.isEmpty) {
      return {
        "success": false,
        "message": "Organization ID is missing in the app!",
      };
    }

    // تنسيق رقم الهاتف
    String formattedPhone = _formatPhoneNumber(contactPhone);

    // إنشاء FormData
    final formData = FormData();

    // إضافة الحقول النصية - ملاحظة: إضافة OrganizationId هنا!
    formData.fields.add(MapEntry('OrganizationId', organizationId)); // ✅ المفتاح
    formData.fields.add(MapEntry('OwnerId', ownerId));
    formData.fields.add(MapEntry('Name', name));
    formData.fields.add(MapEntry('Description', description));
    formData.fields.add(MapEntry('Address', address));
    formData.fields.add(MapEntry('ContactEmail', contactEmail));
    formData.fields.add(MapEntry('ContactPhone', formattedPhone));
    formData.fields.add(MapEntry('Type', type.toString()));

    // إضافة الصورة لو موجودة
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

    print("🚀 Sending to: /organizations");
    print("   OrganizationId: $organizationId"); // ✅ مطبوع للتأكد
    print("   OwnerId: $ownerId");
    print("   Name: $name");
    print("   Type: $type");

    // ✅ استخدم PUT على /organizations (بدون ID في الرابط)
    final response = await _dio.put(
      '/organizations', // ✅ هنا التغيير المهم
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    print("✅ Organization updated successfully: ${response.data}");

    return {
      "success": true,
      "data": response.data,
      "message": "تم تحديث المنظمة بنجاح",
    };
  } on DioException catch (e) {
    print("❌ Error updating organization: ${e.response?.data}");

    String errorMsg = "فشل تحديث الشركة";
    if (e.response?.data != null) {
      if (e.response?.data is Map) {
        final errors = e.response?.data['errors'];
        if (errors != null && errors is Map && errors.isNotEmpty) {
          final firstErrorKey = errors.keys.first;
          final firstErrorValue = errors[firstErrorKey];
          if (firstErrorValue is List && firstErrorValue.isNotEmpty) {
            errorMsg = firstErrorValue[0].toString();
          } else {
            errorMsg = firstErrorValue.toString();
          }
        } else {
          errorMsg = e.response?.data['message'] ??
              e.response?.data['title'] ??
              errorMsg;
        }
      } else if (e.response?.data is String) {
        errorMsg = e.response?.data;
      }
    }
    return {"success": false, "message": errorMsg};
  } catch (e) {
    print("❌ Unexpected error: $e");
    return {"success": false, "message": "حدث خطأ غير متوقع: $e"};
  }
}



  Future<Map<String, dynamic>> deleteOrganization(String id) async {
    try {
      final response = await _dio.delete('/organizations/$id');

      print("✅ Organization deleted successfully: ${response.data}");

      return {
        "success": true,
        "data": response.data,
        "message": "تم حذف المنظمة بنجاح",
      };
    } on DioException catch (e) {
      print("❌ Error deleting organization: ${e.response?.data}");

      String errorMsg = "فشل حذف المنظمة";
      if (e.response?.data is Map) {
        errorMsg = e.response?.data['message'] ?? errorMsg;
      } else if (e.response?.data is String) {
        errorMsg = e.response?.data;
      }

      return {"success": false, "message": errorMsg};
    } catch (e) {
      print("❌ Unexpected error: $e");
      return {"success": false, "message": "حدث خطأ غير متوقع: $e"};
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
      print("❌ Error fetching statistics: ${e.response?.data}");

      String errorMsg = "فشل جلب الإحصائيات";
      if (e.response?.data is Map) {
        errorMsg = e.response?.data['message'] ?? errorMsg;
      } else if (e.response?.data is String) {
        errorMsg = e.response?.data;
      }

      return {"success": false, "message": errorMsg};
    } catch (e) {
      print("❌ Unexpected error: $e");
      return {"success": false, "message": "حدث خطأ غير متوقع: $e"};
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

      print("✅ Ownership transferred successfully: ${response.data}");

      return {
        "success": true,
        "data": response.data,
        "message": "تم نقل الملكية بنجاح",
      };
    } on DioException catch (e) {
      print("❌ Error changing owner: ${e.response?.data}");

      String errorMsg = "فشل نقل الملكية";
      if (e.response?.data is Map) {
        errorMsg = e.response?.data['message'] ?? errorMsg;
      } else if (e.response?.data is String) {
        errorMsg = e.response?.data;
      }

      return {"success": false, "message": errorMsg};
    } catch (e) {
      print("❌ Unexpected error: $e");
      return {"success": false, "message": "حدث خطأ غير متوقع: $e"};
    }
  }

  // الحصول على التوكن المخزن
  String? getToken() {
    return StorageService().token;
  }

  // الحصول على معرف المستخدم (owner id)
  String? getUserId() {
    return StorageService().userId;
  }

  // التحقق من حالة تسجيل الدخول
  bool isLoggedIn() {
    return StorageService().isLoggedIn;
  }

  Future<void> logout() async {
    await StorageService().logout();
    print("User logged out and token cleared.");
  }
}
