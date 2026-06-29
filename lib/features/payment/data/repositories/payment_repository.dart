import 'package:dio/dio.dart';
import 'package:root2route/core/services/storage_service.dart';
import 'package:root2route/features/payment/data/models/payment_result_model.dart';
import 'package:root2route/core/constants.dart';

class PaymentRepository {
  late final Dio _dio;

  PaymentRepository() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    // Attach the JWT token to every request automatically (Identical to withdrawal_repository)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = StorageService().token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          final orgId = StorageService().organizationId;
          if (orgId != null && orgId.isNotEmpty) {
            options.headers['X-Organization-Id'] = orgId;
          }
          
          options.headers['Content-Type'] = 'application/json';
          return handler.next(options);
        },
      ),
    );
  }

  Future<PaymentResultModel> createPayment(String orderId) async {
    // 🔥 Debugging: نجلب التوكن هنا مباشرة لنرى إذا كان فارغاً أم لا من الـ Storage
    final currentToken = StorageService().token;
    
    print('=== PayTabs Create Request ===');
    print('orderId: $orderId');
    print('URL: ${_dio.options.baseUrl}/payment/paytabs/create/$orderId');
    print('Stored Token (from StorageService): $currentToken'); // 👈 سيطبع التوكن الحقيقي هنا

    try {
      final response = await _dio.post(
        '/payment/paytabs/create/$orderId',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data['data'] ?? response.data;
        return PaymentResultModel.fromJson(data);
      } else {
        throw Exception(response.data['message'] ?? 'فشل إنشاء عملية الدفع');
      }
    } on DioException catch (e) {
      print('=== PayTabs Error ===');
      print('Error type: ${e.runtimeType}');
      print('Status code: ${e.response?.statusCode}');
      print('Response data: ${e.response?.data}');
      print('Message: ${e.message}');

      if (e.response != null) {
        final errorMsg = e.response?.data['message'] ??
            e.response?.data['Message'] ??
            'حدث خطأ أثناء الاتصال. (الرمز: ${e.response?.statusCode})';
        throw Exception(errorMsg);
      }
      throw Exception('تعذر الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت.');
    } catch (e) {
      print('=== PayTabs Error ===');
      print('Error type: ${e.runtimeType}');
      print('Message: $e');
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  Future<PaymentVerifyModel> verifyPayment(String transactionReference) async {
    try {
      final response = await _dio.get(
        '/payment/paytabs/verify/$transactionReference',
      );

      print('=== VERIFY RESPONSE STATUS: ${response.statusCode} ===');
      print('=== VERIFY RESPONSE DATA: ${response.data} ===');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data['data'] ?? response.data;
        return PaymentVerifyModel.fromJson(data);
      } else {
        throw Exception(response.data['message'] ?? 'فشل التحقق من حالة الدفع');
      }
    } on DioException catch (e) {
      print('=== VERIFY DIO ERROR: ${e.response?.data} ===');
      if (e.response != null) {
        final errorMsg = e.response?.data['message'] ??
            e.response?.data['Message'] ??
            'حدث خطأ أثناء التحقق. (الرمز: ${e.response?.statusCode})';
        throw Exception(errorMsg);
      }
      throw Exception('تعذر الاتصال بالخادم أثناء التحقق من الدفع.');
    } catch (e) {
      print('=== VERIFY CATCH ERROR: $e ===');
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }
}
