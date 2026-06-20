import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/features/shipments/cubit/shipment_state.dart';
import 'package:root2route/core/services/storage_service.dart';

class ConfirmDeliveryCubit extends Cubit<ShipmentState> {
  late final Dio _dio;

  ConfirmDeliveryCubit() : super(const ShipmentInitial()) {
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

  void _emitSafe(ShipmentState state) {
    if (!isClosed) emit(state);
  }

  // ── PUT /api/v1/shipments/{id}/status ────────────────────────

  /// Updates the shipment identified by [shipmentId] to [status].
  ///
  /// Typically called with [status] = 3 (Delivered) when the buyer
  /// confirms receipt.
  ///
  /// [notes] — optional confirmation notes.
  Future<void> confirmDelivery({
    required int shipmentId,
    required int status,
    String notes = '',
  }) async {
    _emitSafe(const ShipmentLoading());
    try {
      final payload = <String, dynamic>{
        'status': status,
        if (notes.isNotEmpty) 'notes': notes,
      };

      final response = await _dio.put(
        '/shipments/$shipmentId/status',
        data: payload,
      );

      final respBody = response.data;
      final message =
          (respBody is Map ? respBody['message']?.toString() : null) ??
              'Delivery confirmed successfully';

      _emitSafe(ShipmentActionSuccess(message));
    } on DioException catch (e) {
      _emitSafe(ShipmentError(_extractError(e)));
    } catch (e) {
      _emitSafe(ShipmentError('Unexpected error: $e'));
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
