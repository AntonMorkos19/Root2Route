import 'package:dio/dio.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/core/services/storage_service.dart';
import 'package:root2route/features/withdrawals/data/models/withdrawal_model.dart';

/// Repository handling all withdrawal-related API calls.
/// Uses its own Dio instance with JWT injected via an interceptor,
/// matching the pattern used by other cubits (e.g., MyOrdersCubit).
class WithdrawalRepository {
  late final Dio _dio;

  WithdrawalRepository() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    // Attach the JWT token to every request automatically.
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

  // ─────────────────────────────────────────────────────────────────────────
  // Org endpoints
  // ─────────────────────────────────────────────────────────────────────────

  /// POST /api/v1/withdrawals/request
  /// Submits a new withdrawal request for the given organization.
  Future<void> requestWithdrawal({
    required String organizationId,
    required double amount,
    required String bankName,
    required String accountName,
    required String accountNumber,
    required String swiftCode,
  }) async {
    try {
      await _dio.post(
        '/withdrawals/request',
        data: {
          'organizationId': organizationId,
          'amount': amount,
          'bankName': bankName,
          'accountName': accountName,
          'accountNumber': accountNumber,
          'swiftCode': swiftCode,
        },
      );
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    } catch (e) {
      throw Exception('خطأ غير متوقع: $e');
    }
  }

  /// GET /api/v1/withdrawals/organization
  /// Returns the withdrawal history for the current organization.
  Future<List<WithdrawalModel>> fetchOrgWithdrawals() async {
    try {
      final response = await _dio.get('/withdrawals/organization');
      return _parseList(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    } catch (e) {
      throw Exception('خطأ غير متوقع: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Admin endpoints
  // ─────────────────────────────────────────────────────────────────────────

  /// GET /api/v1/withdrawals/pending
  /// Returns all pending withdrawal requests (Admin only).
  Future<List<WithdrawalModel>> fetchPendingWithdrawals() async {
    try {
      final response = await _dio.get('/withdrawals/pending');
      return _parseList(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    } catch (e) {
      throw Exception('خطأ غير متوقع: $e');
    }
  }

  /// POST /api/v1/withdrawals/approve
  /// Approves a withdrawal request (Admin only).
  Future<void> approveWithdrawal({
    required String withdrawalId,
    String adminNote = '',
  }) async {
    try {
      await _dio.post(
        '/withdrawals/approve',
        data: {'withdrawalId': withdrawalId, 'adminNote': adminNote},
      );
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    } catch (e) {
      throw Exception('خطأ غير متوقع: $e');
    }
  }

  /// POST /api/v1/withdrawals/reject
  /// Rejects a withdrawal request (Admin only).
  Future<void> rejectWithdrawal({
    required String withdrawalId,
    String adminNote = '',
  }) async {
    try {
      await _dio.post(
        '/withdrawals/reject',
        data: {'withdrawalId': withdrawalId, 'adminNote': adminNote},
      );
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    } catch (e) {
      throw Exception('خطأ غير متوقع: $e');
    }
  }

  /// POST /api/v1/withdrawals/process
  /// Processes (transfers funds for) an approved withdrawal (Admin only).
  Future<void> processWithdrawal({required String withdrawalId}) async {
    try {
      await _dio.post(
        '/withdrawals/process',
        data: {'withdrawalId': withdrawalId},
      );
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    } catch (e) {
      throw Exception('خطأ غير متوقع: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Parses the API response body into a list of [WithdrawalModel].
  /// The backend may wrap data in { data: [...] } or return a plain list.
  List<WithdrawalModel> _parseList(dynamic body) {
    dynamic raw;
    if (body is Map) {
      raw = body['data'] ?? body['Data'] ?? body;
    } else {
      raw = body;
    }

    if (raw is! List) return [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(WithdrawalModel.fromJson)
        .toList();
  }

  /// Extracts a user-friendly error message from a [DioException].
  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return (data['message'] ?? data['Message'] ?? data['title'] ?? 'حدث خطأ').toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return e.message ?? 'خطأ في الشبكة';
  }
}
