import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/features/notifications/data/models/notification_model.dart';
import 'package:root2route/core/services/storage_service.dart';

class NotificationService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  NotificationService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = StorageService().token;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {'pageNumber': 1, 'pageSize': 50},
      );
      return _parseNotificationResponse(response.data);
    } on DioException catch (e) {
      debugPrint(
        "❌ Dio Error [${e.response?.statusCode}]: ${e.requestOptions.path}",
      );
      debugPrint("❌ Error Data: ${e.response?.data}");

      // Handle backend quirk: 400 status but successful data inside
      if (e.response != null && e.response?.data != null) {
        var data = e.response!.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }
        if (data is Map<String, dynamic> && data['succeeded'] == true) {
          return _parseNotificationResponse(data);
        }
      }

      final errorData = e.response?.data;
      String errorMessage = 'Failed to load notifications';
      if (errorData is Map && errorData.containsKey('message')) {
        errorMessage = errorData['message'].toString();
      } else if (errorData != null) {
        errorMessage =
            'Failed with status ${e.response?.statusCode}: $errorData';
      }

      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
      throw Exception('Failed to load notifications: $e');
    }
  }

  List<NotificationModel> _parseNotificationResponse(dynamic rawData) {
    var data = rawData;
    if (data is String) {
      data = jsonDecode(data);
    }

    if (data is Map) {
      if (data['succeeded'] == true || data.containsKey('data')) {
        var items = data['data'];
        if (items is Map && items.containsKey('items')) {
          items = items['items'];
        }
        if (items is List) {
          return items
              .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } else if (data is List) {
      return data
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      data is Map
          ? data['message'] ?? 'Unknown error'
          : 'Invalid response format',
    );
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
      var data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }

      if (data is Map && data.containsKey('data')) {
        return int.tryParse(data['data'].toString()) ?? 0;
      }
      return int.tryParse(data.toString()) ?? 0;
    } on DioException catch (e) {
      debugPrint(
        "Dio Error [${e.response?.statusCode}]: ${e.requestOptions.path}",
      );
      debugPrint("Error Data: ${e.response?.data}");

      // Handle the 400 status quirk
      if (e.response != null && e.response?.data != null) {
        var data = e.response!.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }
        if (data is Map && data['succeeded'] == true) {
          return int.tryParse(data['data'].toString()) ??
              0; // Extract the integer (e.g., 33)
        }
      }
      return 0;
    } catch (e) {
      debugPrint('Unknown error fetching unread count: $e');
      return 0; // Return 0 gracefully
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      final response = await _dio.put('/notifications/$id/read');
      return response.statusCode == 200 ||
          response.statusCode == 204 ||
          (response.data is Map && response.data['succeeded'] == true);
    } on DioException catch (e) {
      debugPrint(
        "❌ Dio Error [${e.response?.statusCode}]: ${e.requestOptions.path}",
      );
      debugPrint("❌ Error Data: ${e.response?.data}");
      return false;
    } catch (e) {
      debugPrint('Failed to mark as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _dio.put('/notifications/read-all');
      return response.statusCode == 200 ||
          response.statusCode == 204 ||
          (response.data is Map && response.data['succeeded'] == true);
    } on DioException catch (e) {
      debugPrint(
        "❌ Dio Error [${e.response?.statusCode}]: ${e.requestOptions.path}",
      );
      debugPrint("❌ Error Data: ${e.response?.data}");
      return false;
    } catch (e) {
      debugPrint('Failed to mark all as read: $e');
      return false;
    }
  }
}
