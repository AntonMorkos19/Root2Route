import 'package:dio/dio.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/models/order_model.dart';

class OrderService {
  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));

  OrderService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = StorageService().token;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // ──────────────────────────────────────────────
  // 1. POST /order/Create — Create a new order
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '/order/Create',
        data: payload,
        options: Options(validateStatus: (status) => status != null && status <= 400),
      );

      final respBody = response.data;
      if (respBody is Map) {
        final isSuccess = respBody['succeeded'] == true || respBody['success'] == true;
        return {
          'success': isSuccess,
          'data': respBody['data'],
          'message': respBody['message'] ?? 'Order created successfully',
        };
      }
      return {
        'success': response.statusCode == 200,
        'data': respBody,
        'message': 'Order created successfully',
      };
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return {'success': false, 'data': null, 'message': 'Unexpected error: $e'};
    }
  }

  // ──────────────────────────────────────────────
  // 2. GET /order/MyOrders — Buyer's order list
  //    ⚠ Backend returns 400 even on success
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> getMyOrders() async {
    try {
      final response = await _dio.get(
        '/order/MyOrders',
        options: Options(validateStatus: (status) => status != null && status <= 400),
      );

      final respBody = response.data;
      final int statusCode = response.statusCode ?? 0;

      if (respBody is Map) {
        final bool isSuccess = (statusCode == 200) || 
                               (statusCode == 400 && respBody['succeeded'] == true);
        
        final rawList = respBody['data'] ?? respBody['Data'];
        final List<OrderModel> orders = _parseOrderList(rawList);
        return {
          'success': isSuccess,
          'data': orders,
          'message': respBody['message'] ?? '',
        };
      }
      return {'success': false, 'data': <OrderModel>[], 'message': 'Unexpected response format'};
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return {'success': false, 'data': <OrderModel>[], 'message': 'Unexpected error: $e'};
    }
  }

  // ──────────────────────────────────────────────
  // 3. GET /order/{id} — Order details
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      final response = await _dio.get(
        '/order/$orderId',
        options: Options(validateStatus: (status) => status != null && status <= 400),
      );

      final respBody = response.data;
      if (respBody is Map) {
        final isSuccess = respBody['succeeded'] == true || respBody['success'] == true;
        final rawData = respBody['data'] ?? respBody['Data'];
        OrderModel? order;
        if (rawData is Map<String, dynamic>) {
          order = OrderModel.fromJson(rawData);
        }
        return {
          'success': isSuccess,
          'data': order,
          'message': respBody['message'] ?? '',
        };
      }
      return {'success': false, 'data': null, 'message': 'Unexpected response format'};
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return {'success': false, 'data': null, 'message': 'Unexpected error: $e'};
    }
  }

  // ──────────────────────────────────────────────
  // 4. GET /order/Received/{organizationId} — Seller's received orders
  //    ⚠ Backend returns 400 even on success
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> getReceivedOrders(String organizationId) async {
    try {
      final response = await _dio.get(
        '/order/Received/$organizationId',
        options: Options(validateStatus: (status) => status != null && status <= 400),
      );

      final respBody = response.data;
      final int statusCode = response.statusCode ?? 0;

      if (respBody is Map) {
        final bool isSuccess = (statusCode == 200) || 
                               (statusCode == 400 && respBody['succeeded'] == true);
        
        final rawList = respBody['data'] ?? respBody['Data'];
        final List<OrderModel> orders = _parseOrderList(rawList);
        return {
          'success': isSuccess,
          'data': orders,
          'message': respBody['message'] ?? '',
        };
      }
      return {'success': false, 'data': <OrderModel>[], 'message': 'Unexpected response format'};
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return {'success': false, 'data': <OrderModel>[], 'message': 'Unexpected error: $e'};
    }
  }

  // ──────────────────────────────────────────────
  // 5. PUT /order/ChangeStatus — Seller: Accept/Reject/Ship
  //    Payload: {"orderId": "uuid", "newStatus": int, "note": "string"}
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> changeOrderStatus({
    required String orderId,
    required int newStatus,
    String note = '',
  }) async {
    try {
      final response = await _dio.put(
        '/order/ChangeStatus',
        data: {
          'orderId': orderId,
          'newStatus': newStatus,
          'note': note,
        },
        // Step 1: Prevent Dio from throwing exception on 400
        options: Options(validateStatus: (status) => status != null && status <= 400),
      );

      final respBody = response.data;
      final int statusCode = response.statusCode ?? 0;

      if (respBody is Map) {
        // Step 2: Treat as SUCCESS if statusCode is 200 OR (400 and succeeded is true)
        final bool isSuccess = (statusCode == 200) || 
                               (statusCode == 400 && respBody['succeeded'] == true);
        
        return {
          'success': isSuccess,
          'data': respBody['data'],
          'message': respBody['message'] ?? 'Status updated',
        };
      }
      
      return {
        'success': statusCode == 200,
        'data': respBody,
        'message': 'Status updated',
      };
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return {'success': false, 'data': null, 'message': 'Unexpected error: $e'};
    }
  }

  // ──────────────────────────────────────────────
  // 6. PUT /order/Cancel/{id} — Buyer cancels order
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      final safeOrderId = Uri.encodeComponent(orderId);
      final response = await _dio.put(
        '/order/Cancel/$safeOrderId',
        data: null,
        options: Options(validateStatus: (status) => status != null && status <= 400),
      );

      final respBody = response.data;
      if (respBody is Map) {
        final isSuccess = respBody['succeeded'] == true || respBody['success'] == true;
        return {
          'success': isSuccess,
          'data': respBody['data'],
          'message': respBody['message'] ?? 'Order cancelled',
        };
      }
      return {
        'success': response.statusCode == 200,
        'data': respBody,
        'message': 'Order cancelled',
      };
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return {'success': false, 'data': null, 'message': 'Unexpected error: $e'};
    }
  }

  // ──────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────
  List<OrderModel> _parseOrderList(dynamic rawList) {
    final List<OrderModel> orders = [];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          orders.add(OrderModel.fromJson(item));
        }
      }
    }
    return orders;
  }

  Map<String, dynamic> _handleError(DioException e) {
    if (e.response != null && e.response!.data != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        return {'success': false, 'data': null, 'message': data['message'].toString()};
      }
      if (data is String) {
        // Get only the first line/useful part of the error message to avoid stack traces in UI
        String cleanMsg = data.split('\n').first.split('at ').first.trim();
        return {'success': false, 'data': null, 'message': cleanMsg};
      }
      return {'success': false, 'data': null, 'message': 'Server Error: ${e.response!.statusCode}'};
    }
    return {'success': false, 'data': null, 'message': e.message ?? 'Unknown network error'};
  }
}
