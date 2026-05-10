import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/features/shipments/cubit/shipment_state.dart';
import 'package:root2route/models/shipment_address_model.dart';
import 'package:root2route/services/storage_service.dart';

/// Cubit that manages shipment addresses for the current user.
///
/// GET  /api/v1/shipments/addresses  — fetch saved addresses
/// POST /api/v1/shipments/addresses  — add a new address
class ShipmentAddressCubit extends Cubit<ShipmentState> {
  late final Dio _dio;

  ShipmentAddressCubit() : super(const ShipmentInitial()) {
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

  // ── GET /api/v1/shipments/addresses ──────────────────────────

  /// Loads all shipment addresses saved by the current user.
  Future<void> fetchAddresses() async {
    _emitSafe(const ShipmentLoading());
    try {
      final response = await _dio.get('/shipments/addresses');
      final respBody = response.data;

      if (respBody is Map) {
        final rawList = respBody['data'] as List?;
        final addresses = rawList
                ?.whereType<Map<String, dynamic>>()
                .map(ShipmentAddressModel.fromJson)
                .toList() ??
            <ShipmentAddressModel>[];
        _emitSafe(ShipmentAddressesLoaded(addresses));
      } else {
        _emitSafe(const ShipmentError('Unexpected response format'));
      }
    } on DioException catch (e) {
      _emitSafe(ShipmentError(_extractError(e)));
    } catch (e) {
      _emitSafe(ShipmentError('Unexpected error: $e'));
    }
  }

  // ── POST /api/v1/shipments/addresses ─────────────────────────

  /// Saves a new shipment [address] and reloads the address list on success.
  Future<void> addAddress(ShipmentAddressModel address) async {
    _emitSafe(const ShipmentLoading());
    try {
      final response = await _dio.post(
        '/shipments/addresses',
        data: address.toJson(),
      );
      final respBody = response.data;
      final message =
          (respBody is Map ? respBody['message']?.toString() : null) ??
              'Address saved successfully';
      _emitSafe(ShipmentActionSuccess(message));

      // Refresh addresses list after adding
      await fetchAddresses();
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
