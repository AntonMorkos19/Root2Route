import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/features/shipments/cubit/shipment_state.dart';
import 'package:root2route/features/shipments/data/models/shipment_address_model.dart';
import 'package:root2route/core/services/storage_service.dart';

/// Cubit that manages shipment addresses for the current user.
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
          final storage = StorageService();
          final token = storage.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          final orgId = storage.organizationId;
          if (orgId != null && orgId.isNotEmpty) {
            options.headers['X-Organization-Id'] = orgId;
          }
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

  void _emitSafe(ShipmentState state) {
    if (!isClosed) emit(state);
  }

  /// Loads all shipment addresses saved by the current user.
  Future<void> fetchAddresses() async {
    _emitSafe(const ShipmentLoading());
    try {
      final response = await _dio.get(
        '/shipments/addresses',
        options: Options(
          validateStatus: (status) => status != null && status <= 400,
        ),
      );
      final respBody = response.data;

      if (respBody is Map && respBody['succeeded'] == true) {
        final rawList = respBody['data'] as List?;
        final addresses = rawList
                ?.whereType<Map<String, dynamic>>()
                .map(ShipmentAddressModel.fromJson)
                .toList() ??
            <ShipmentAddressModel>[];
        _emitSafe(ShipmentAddressesLoaded(addresses));
      } else {
        final msg = respBody is Map ? respBody['message'] : 'Unexpected response format';
        _emitSafe(ShipmentError(msg?.toString() ?? 'Unexpected response format'));
      }
    } on DioException catch (e) {
      _emitSafe(ShipmentError(_extractError(e)));
    } catch (e) {
      _emitSafe(ShipmentError('Unexpected error: $e'));
    }
  }

  /// Saves a new shipment [address] and reloads the address list on success.
  Future<void> addAddress(ShipmentAddressModel address) async {
    _emitSafe(const ShipmentLoading());
    try {
      final response = await _dio.post(
        '/shipments/addresses',
        data: address.toJson(),
        options: Options(
          validateStatus: (status) => status != null && status <= 400,
        ),
      );
      final respBody = response.data;
      if (respBody is Map && respBody['succeeded'] == true) {
        final message = respBody['message']?.toString() ?? 'Address saved successfully';
        _emitSafe(ShipmentActionSuccess(message));
        await fetchAddresses();
      } else {
        final message = respBody is Map ? respBody['message'] : 'Failed to save address';
        _emitSafe(ShipmentError(message?.toString() ?? 'Failed to save address'));
      }
    } on DioException catch (e) {
      debugPrint('[ShipmentAddressCubit] addAddress DioException data: ${e.response?.data}');
      _emitSafe(ShipmentError(_extractError(e)));
    } catch (e) {
      debugPrint('[ShipmentAddressCubit] addAddress Unexpected error: $e');
      _emitSafe(ShipmentError('Unexpected error: $e'));
    }
  }

  String _extractError(DioException e) {
    final response = e.response;
    if (response == null) return "Network connection error";
    
    final data = response.data;
    debugPrint('[ShipmentAddressCubit] _extractError raw data: $data');

    if (data is Map) {
      // 1. Check common message keys
      final message = data['message'] ?? data['Message'] ?? data['msg'] ?? data['Msg'];
      if (message != null && message.toString().isNotEmpty) return message.toString();

      // 2. Check for validation errors (ASP.NET style)
      if (data['errors'] != null) {
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstErrorList = errors.values.first;
          if (firstErrorList is List && firstErrorList.isNotEmpty) {
            return firstErrorList[0].toString();
          }
          return firstErrorList.toString();
        }
        if (errors is List && errors.isNotEmpty) {
          return errors[0].toString();
        }
      }

      // 3. Check for ProblemDetails 'title'
      if (data['title'] != null) return data['title'].toString();
      
      // 4. Check for 'error' key
      if (data['error'] != null) return data['error'].toString();
    }

    if (data is String && data.isNotEmpty) return data;

    return e.message ?? 'Unknown server error';
  }
}
