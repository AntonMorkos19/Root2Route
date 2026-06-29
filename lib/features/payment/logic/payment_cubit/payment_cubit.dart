import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/payment/data/repositories/payment_repository.dart';
import 'package:root2route/features/payment/logic/payment_cubit/payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository _repository;

  PaymentCubit(this._repository) : super(const PaymentInitial());

  Future<void> createPayment(String orderId) async {
    emit(const PaymentLoading());
    try {
      final result = await _repository.createPayment(orderId);
      emit(
        PaymentWebViewReady(
          redirectUrl: result.redirectUrl,
          transactionReference: result.transactionReference,
        ),
      );
    } on DioException catch (e) {
      print("🚀🚀🚀 ====== FULL API DEBUG ERROR ======");
      print("Request Path: ${e.requestOptions.path}");
      print(
        "Request Headers: ${e.requestOptions.headers}",
      ); // This will show if the token is missing
      print("Response Status: ${e.response?.statusCode}");
      print(
        "Response Data: ${e.response?.data}",
      ); // This will show the real backend error message
      print("========================================");
      emit(
        PaymentFailed("خطأ في الاتصال: ${e.response?.statusCode ?? 'Unknown'}"),
      );
    } catch (e) {
      emit(PaymentFailed(e.toString()));
    }
  }

  // في PaymentCubit — verifyPayment
  Future<void> verifyPayment(String transactionReference) async {
    emit(const PaymentVerifying());
    try {
      final result = await _repository.verifyPayment(transactionReference);
      print('=== VERIFY STATUS FROM MODEL: ${result.status} ===');
      final status = result.status.toLowerCase().trim();
      if (status == 'captured' ||
          status == 'a' ||
          status == 'paid' ||
          status == 'approved') {
        emit(const PaymentCaptured());
      } else {
        emit(PaymentFailed('حالة الدفع: ${result.status}'));
      }
    } catch (e) {
      print('=== VERIFY CUBIT CATCH: $e ===');
      emit(PaymentFailed(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
