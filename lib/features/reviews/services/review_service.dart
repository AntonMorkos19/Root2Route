import 'package:dio/dio.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/services/storage_service.dart';

class ReviewService {
  late final Dio _dio;

  ReviewService() {
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
          final orgId = StorageService().organizationId;
          if (orgId != null && orgId.isNotEmpty) {
            options.headers['X-Organization-Id'] = orgId;
          }
          return handler.next(options);
        },
      ),
    );
  }

  /// Submits a review and returns a standardized response map.
  Future<Map<String, dynamic>> submitReview({
    required String targetOrganizationId,
    required String orderId,
    required String productId,
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await _dio.post(
        '/reviews',
        data: {
          'targetOrganizationId': targetOrganizationId,
          'orderId': orderId,
          'productId': productId,
          'rating': rating,
          'comment': comment,
        },
        options: Options(
          validateStatus: (status) => true, // Don't throw for any status code
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "message": "Review submitted successfully!",
        };
      } else if (response.statusCode == 500) {
        return {
          "success": false,
          "message": "Server is having trouble. Please try with a different order.",
        };
      } else {
        final respBody = response.data;
        String errorMsg = "Unknown error";
        if (respBody is Map) {
          errorMsg = respBody['message']?.toString() ?? "Unknown error";
        }
        return {
          "success": false,
          "message": errorMsg,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Network error: ${e.toString()}",
      };
    }
  }

  /// Fetches reviews for an organization.
  Future<Map<String, dynamic>> fetchOrganizationReviews(String orgId) async {
    try {
      final response = await _dio.get(
        '/reviews/organization/$orgId',
        options: Options(
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "data": response.data,
        };
      } else {
        final respBody = response.data;
        String errorMsg = "Failed to load reviews";
        if (respBody is Map) {
          errorMsg = respBody['message']?.toString() ?? "Failed to load reviews";
        }
        return {
          "success": false,
          "message": errorMsg,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Network error",
      };
    }
  }
}
