import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/features/orders/cubit/order_state.dart';
import 'package:root2route/models/order_model.dart';
import 'package:root2route/services/storage_service.dart';

/// Cubit that fetches orders received by the seller's organization.
/// Endpoint: GET /api/v1/order/Received/{organizationId}
class ReceivedOrdersCubit extends Cubit<OrderState> {
  late final Dio _dio;

  ReceivedOrdersCubit() : super(const OrderInitial()) {
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

  /// Fetches orders received by the organization identified by [organizationId].
  Future<void> fetchReceivedOrders(String organizationId) async {
    if (organizationId.isEmpty) {
      _emitSafe(const OrderError('Organization ID is required'));
      return;
    }

    _emitSafe(const OrderLoading());
    try {
      final response = await _dio.get(
        '/order/Received/$organizationId',
        options: Options(
          // Backend sometimes returns 400 even on success
          validateStatus: (status) => status != null && status <= 400,
        ),
      );

      final respBody = response.data;
      final int statusCode = response.statusCode ?? 0;

      if (respBody is Map) {
        final bool isSuccess =
            (statusCode == 200) ||
            (statusCode == 400 && respBody['succeeded'] == true);

        if (isSuccess) {
          final rawList = respBody['data'] ?? respBody['Data'];
          final orders = _parseList(rawList);
          _emitSafe(OrderListLoaded(orders));
        } else {
          _emitSafe(
            OrderError(
              respBody['message']?.toString() ??
                  'Failed to load received orders',
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

  List<OrderModel> _parseList(dynamic rawList) {
    final orders = <OrderModel>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          orders.add(OrderModel.fromJson(item));
        }
      }
    }
    return orders;
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? 'Network error';
  }
}
