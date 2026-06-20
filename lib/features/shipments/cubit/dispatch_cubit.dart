import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/features/shipments/cubit/shipment_state.dart';
import 'package:root2route/core/services/storage_service.dart';

/// Cubit that dispatches a shipment for a confirmed order.
///
/// POST /api/v1/shipments/dispatch
///
/// Expected payload:
/// ```json
/// {
///   "orderId": "uuid",
///   "addressId": 1,        // optional if address fields are provided inline
///   "trackingNumber": "",  // optional
///   "notes": ""            // optional
/// }
/// ```
class DispatchCubit extends Cubit<ShipmentState> {
  late final Dio _dio;

  DispatchCubit() : super(const ShipmentInitial()) {
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

  // ── POST /api/v1/shipments/dispatch ──────────────────────────

   
  Future<void> dispatchShipment({
    required String orderId,
    int? addressId,
    String trackingNumber = '',
    String notes = '',
    String carrierName = '',
    String driverPhone = '',
  }) async {
    _emitSafe(const ShipmentLoading());
    try {
      final payload = <String, dynamic>{
        'orderId': orderId,
        if (addressId != null) 'addressId': addressId,
        if (trackingNumber.isNotEmpty) 'trackingNumber': trackingNumber,
        if (notes.isNotEmpty) 'notes': notes,
        if (carrierName.isNotEmpty) 'carrierName': carrierName,
        if (driverPhone.isNotEmpty) 'driverPhone': driverPhone,
      };

      final response = await _dio.post(
        '/shipments/dispatch',
        data: payload,
        options: Options(
          validateStatus: (status) => status != null && status <= 400,
        ),
      );

      final respBody = response.data;
      final message =
          (respBody is Map ? respBody['message']?.toString() : null) ?? '';

      final isSuccess = response.statusCode == 200 ||
          response.statusCode == 201 ||
          (respBody is Map && respBody['succeeded'] == true) ||
          message.toLowerCase().contains('dispatched');

      if (isSuccess) {
        _emitSafe(ShipmentActionSuccess(
            message.isNotEmpty ? message : 'Shipment dispatched successfully'));
      } else {
        _emitSafe(ShipmentError(
            message.isNotEmpty ? message : 'Failed to dispatch shipment'));
      }
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
