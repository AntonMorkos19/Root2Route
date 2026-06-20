import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/features/orders/cubit/order_state.dart';
import 'package:root2route/features/orders/data/models/order_model.dart';
import 'package:root2route/core/services/storage_service.dart';

/// Cubit that fetches the details of a single order by its ID.
/// Endpoint: GET /api/v1/order/{id}
class OrderDetailsCubit extends Cubit<OrderState> {
  late final Dio _dio;

  OrderDetailsCubit() : super(const OrderInitial()) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
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
  }

  void _emitSafe(OrderState state) {
    if (!isClosed) emit(state);
  }

  /// Loads a specific order by [orderId].
  Future<void> fetchOrderDetails(String orderId) async {
    _emitSafe(const OrderLoading());
    try {
      final response = await _dio.get(
        '/order/$orderId',
        options: Options(
          validateStatus: (status) => status != null && status <= 400,
        ),
      );

      final respBody = response.data;
      
      print('ORDER JSON RESPONSE: $respBody');

      if (respBody is Map) {
        final rawData = respBody['data'] ?? respBody['Data'];
        if (rawData is Map<String, dynamic>) {
          _emitSafe(OrderDetailLoaded(OrderModel.fromJson(rawData)));
        } else {
          _emitSafe(
            OrderError(
              respBody['message']?.toString() ?? 'Order not found',
            ),
          );
        }
      } else {
        _emitSafe(const OrderError('Unexpected response format'));
      }
    } on DioException catch (e) {
      _emitSafe(OrderError(_extractError(e)));
    } catch (e) {
      _emitSafe(OrderError('Unexpected error: $e'));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? 'Network error';
  }
}
