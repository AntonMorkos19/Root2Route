import 'package:dio/dio.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/models/chat_room_model.dart';
import 'package:root2route/models/chat_message_model.dart';

class ChatService {
  late final Dio _dio;

  ChatService() {
    _dio = Dio(BaseOptions(baseUrl: baseUrl));
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

  // 1. POST /api/v1/chat/start
  Future<String> startChat({
    required String organizationId,
    required String productId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/chat/start',
        data: {
          'organizationId': organizationId,
          'productId': productId,
        },
      );
      return response.data['data'] as String;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> && responseData['succeeded'] == true) {
          return responseData['data'] as String;
        }
      }
      throw _handleError(e);
    }
  }

  // 2. POST /api/v1/chat/send  (multipart/form-data)
  Future<ChatMessageModel> sendMessage({
    required String chatRoomId,
    required String content,
    required String currentUserId,
    int type = 0,
    double? proposedPrice,
    int? proposedQuantity,
    String? imageFilePath,
  }) async {
    try {
      final formFields = <String, dynamic>{
        'ChatRoomId': chatRoomId,
        'Content': content,
        'Type': type,
        'CurrentUserId': currentUserId,
      };
      if (proposedPrice != null) formFields['ProposedPrice'] = proposedPrice;
      if (proposedQuantity != null) formFields['ProposedQuantity'] = proposedQuantity;
      if (imageFilePath != null && imageFilePath.isNotEmpty) {
        formFields['ImageFile'] = await MultipartFile.fromFile(imageFilePath);
      }

      final response = await _dio.post(
        '/api/v1/chat/send',
        data: FormData.fromMap(formFields),
      );
      final data = _extractData(response.data);
      return ChatMessageModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> && responseData['succeeded'] == true) {
          return ChatMessageModel.fromJson(_extractData(responseData));
        }
      }
      throw _handleError(e);
    }
  }

  // 3. POST /api/v1/chat/accept-offer
  Future<void> acceptOffer(String messageId) async {
    try {
      await _dio.post(
        '/api/v1/chat/accept-offer',
        data: {'offerMessageId': messageId},
      );
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> && responseData['succeeded'] == true) {
          return;
        }
      }
      throw _handleError(e);
    }
  }

  // 4. POST /api/v1/chat/reject-offer
  Future<void> rejectOffer(String messageId) async {
    try {
      await _dio.post(
        '/api/v1/chat/reject-offer',
        data: {'offerMessageId': messageId},
      );
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> && responseData['succeeded'] == true) {
          return;
        }
      }
      throw _handleError(e);
    }
  }

  // 5. GET /api/v1/chat/my-rooms
  Future<List<ChatRoomModel>> getMyRooms({int pageNumber = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.get(
        '/api/v1/chat/my-rooms',
        queryParameters: {
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );
      
      final rawList = _extractList(response.data);
      return rawList.map((e) => ChatRoomModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> && responseData['succeeded'] == true) {
          final rawList = _extractList(responseData);
          return rawList.map((json) => ChatRoomModel.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      throw _handleError(e);
    }
  }

  // 6. GET /api/v1/chat/{chatRoomId}/history
  Future<List<ChatMessageModel>> getChatHistory(String chatRoomId, {int pageNumber = 1, int pageSize = 50}) async {
    try {
      final response = await _dio.get(
        '/api/v1/chat/$chatRoomId/history',
        queryParameters: {
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );
      
      final rawList = _extractList(response.data);
      return rawList.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> && responseData['succeeded'] == true) {
          final rawList = _extractList(responseData);
          return rawList.map((json) => ChatMessageModel.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      throw _handleError(e);
    }
  }

  // 7. GET /api/v1/chat/{roomId}/details
  Future<ChatRoomModel> getChatRoomDetails(String roomId) async {
    try {
      final response = await _dio.get('/api/v1/chat/$roomId/details');
      final data = _extractData(response.data);
      return ChatRoomModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> && responseData['succeeded'] == true) {
          return ChatRoomModel.fromJson(_extractData(responseData));
        }
      }
      throw _handleError(e);
    }
  }

  // 8. PUT /api/v1/chat/{roomId}/read
  Future<void> markRoomAsRead(String roomId) async {
    try {
      await _dio.put('/api/v1/chat/$roomId/read');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> && responseData['succeeded'] == true) {
          return;
        }
      }
      throw _handleError(e);
    }
  }

  // 9. PUT /api/v1/chat/{roomId}/close
  Future<void> closeChatRoom(String roomId) async {
    try {
      await _dio.put('/api/v1/chat/$roomId/close');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> && responseData['succeeded'] == true) {
          return;
        }
      }
      throw _handleError(e);
    }
  }

  // 10. DELETE /api/v1/chat/messages/{messageId}
  Future<void> deleteMessage(String messageId) async {
    try {
      await _dio.delete('/api/v1/chat/messages/$messageId');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> && responseData['succeeded'] == true) {
          return;
        }
      }
      throw _handleError(e);
    }
  }

  dynamic _extractData(dynamic responseData) {
    if (responseData is Map) {
      return responseData['data'] ?? responseData['Data'] ?? responseData;
    }
    return responseData;
  }

  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is Map) {
      final data = responseData['data'] ?? responseData['Data'] ?? responseData['items'] ?? responseData['Items'];
      if (data is List) {
        return data;
      }
    } else if (responseData is List) {
      return responseData;
    }
    return [];
  }

  Exception _handleError(DioException e) {
    if (e.response != null && e.response!.data != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        return Exception(data['message'].toString());
      }
      if (data is String) {
        String cleanMsg = data.split('\n').first.split('at ').first.trim();
        return Exception(cleanMsg);
      }
      return Exception('Server Error: ${e.response!.statusCode}');
    }
    return Exception(e.message ?? 'Unknown network error');
  }
}
