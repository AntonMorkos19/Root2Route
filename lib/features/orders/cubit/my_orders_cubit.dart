import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/features/orders/cubit/order_state.dart';
import 'package:root2route/features/orders/data/models/order_model.dart';
import 'package:root2route/core/services/storage_service.dart';

/// Cubit that fetches the buyer's own order history.
/// Endpoint: GET /api/v1/order/MyOrders
class MyOrdersCubit extends Cubit<OrderState> {
  late final Dio _dio;

  MyOrdersCubit() : super(const OrderInitial()) {
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

  /// Safety wrapper — prevents state emission after cubit is closed.
  void _emitSafe(OrderState state) {
    if (!isClosed) emit(state);
  }

  /// Fetches the authenticated buyer's orders.
  Future<void> fetchMyOrders() async {
    _emitSafe(const OrderLoading());
    try {
      final response = await _dio.get(
        '/order/MyOrders',
        options: Options(
          // Some backends return 400 even on success
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
          final myUserId = StorageService().currentUserId;
          final myOrders = myUserId != null
              ? orders.where((o) => o.buyerId == myUserId).toList()
              : orders;
          _emitSafe(OrderListLoaded(myOrders));
        } else {
          _emitSafe(
            OrderError(
              respBody['message']?.toString() ?? 'فشل في تحميل الطلبات',
            ),
          );
        }
      } else {
        _emitSafe(const OrderError('تنسيق استجابة غير متوقع'));
      }
    } on DioException catch (e) {
      _emitSafe(OrderError(_extractError(e)));
    } catch (e) {
      _emitSafe(OrderError('خطأ غير متوقع: $e'));
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
    return e.message ?? 'خطأ في الشبكة';
  }
}
