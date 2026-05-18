import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:root2route/services/storage_service.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/models/chat_room_model.dart';
import 'package:root2route/models/chat_message_model.dart';

class ChatService {
  late final Dio _dio;

  ChatService() {
    _dio = Dio(BaseOptions(baseUrl: baseUrl));
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

  Future<String> startChat({
    required String organizationId,
    required String productId,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/start',
        data: {'organizationId': organizationId, 'productId': productId},
      );
      return response.data['data'] as String;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> &&
            responseData['succeeded'] == true) {
          return responseData['data'] as String;
        }
      }
      throw _handleError(e);
    }
  }

  //  Future<ChatMessageModel> sendMessage({
  //   required String chatRoomId,
  //   required String content,
  //   required String currentUserId,
  //   int type = 0,
  //   double? proposedPrice,
  //   int? proposedQuantity,
  //   String? imageFilePath,
  // }) async {
  //   try {
  //     final formFields = <String, dynamic>{
  //       'ChatRoomId': chatRoomId,
  //       'Content': content,
  //       'Type': type,
  //       'CurrentUserId': currentUserId,
  //     };
  //     if (proposedPrice != null) formFields['ProposedPrice'] = proposedPrice;
  //     if (proposedQuantity != null)
  //       formFields['ProposedQuantity'] = proposedQuantity;
  //     if (imageFilePath != null && imageFilePath.isNotEmpty) {
  //       formFields['ImageFile'] = await MultipartFile.fromFile(imageFilePath);
  //     }

  //     final response = await _dio.post(
  //       '/chat/send',
  //       data: FormData.fromMap(formFields),
  //     );
  //     final data = _extractData(response.data);
  //     return ChatMessageModel.fromJson(data);
  //   } on DioException catch (e) {
  //     if (e.response != null && e.response?.data != null) {
  //       final responseData = e.response!.data;
  //       if (responseData is Map<String, dynamic> &&
  //           responseData['succeeded'] == true) {
  //         return ChatMessageModel.fromJson(_extractData(responseData));
  //       }
  //     }
  //     throw _handleError(e);
  //   }
  // }
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
      // 1. تحويل الأرقام لـ Strings عشان الـ FormData ساعات بترفض الأرقام وترمي 400
      final formFields = <String, dynamic>{
        'ChatRoomId': chatRoomId,
        'Content': content,
        'Type': type.toString(),
        'CurrentUserId': currentUserId,
      };

      if (proposedPrice != null)
        formFields['ProposedPrice'] = proposedPrice.toString();
      if (proposedQuantity != null)
        formFields['ProposedQuantity'] = proposedQuantity.toString();

      if (imageFilePath != null && imageFilePath.isNotEmpty) {
        formFields['ImageFile'] = await MultipartFile.fromFile(imageFilePath);
      }

      // كشاف عشان نشوف الداتا وهي طالعة سليمة ولا لأ
      debugPrint('🚀 SENDING MESSAGE PAYLOAD: $formFields');

      final response = await _dio.post(
        '/chat/send',
        data: FormData.fromMap(formFields),
      );

      // 2. كمين الـ 200 الوهمي (لو رجع 200 بس الباك-إند رافض العملية)
      if (response.data is Map<String, dynamic>) {
        if (response.data['succeeded'] == false) {
          final errorMessage =
              response.data['message'] ??
              response.data['errors']?.toString() ??
              'Failed to send message.';
          throw Exception(errorMessage); // ده هيروح للـ Cubit يعرضه
        }
      }

      final data = _extractData(response.data);
      return ChatMessageModel.fromJson(data);
    } on DioException catch (e) {
      // 3. كشافات فضح الإيرور الـ 400 من الباك-إند
      debugPrint('🔥 SEND ERROR STATUS: ${e.response?.statusCode}');
      debugPrint('🔥 SEND ERROR DATA: ${e.response?.data}');

      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          // لو السيرفر رامي 400 بس العملية نجحت (Fake Error)
          if (responseData['succeeded'] == true) {
            return ChatMessageModel.fromJson(_extractData(responseData));
          }
          // لو السيرفر رامي 400 والعملية فشلت بجد، نقرأ رسالته
          else {
            final errorMessage =
                responseData['message'] ??
                responseData['errors']?.toString() ??
                'Validation Error from server';
            throw Exception(errorMessage);
          }
        }
      }
      throw _handleError(e); // لو إيرور شبكة أو حاجة تانية خالص
    }
  }

   Future<void> acceptOffer(String messageId) async {
    try {
      await _dio.post(
        '/chat/accept-offer',
        data: {'offerMessageId': messageId},
      );
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> &&
            responseData['succeeded'] == true) {
          return;
        }
      }
      throw _handleError(e);
    }
  }

   Future<void> rejectOffer(String messageId) async {
    try {
      await _dio.post(
        '/chat/reject-offer',
        data: {'offerMessageId': messageId},
      );
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> &&
            responseData['succeeded'] == true) {
          return;
        }
      }
      throw _handleError(e);
    }
  }

   Future<List<ChatRoomModel>> getMyRooms({
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/chat/my-rooms',
        queryParameters: {'pageNumber': pageNumber, 'pageSize': pageSize},
      );

      final rawList = _extractList(response.data);
      return rawList
          .map((e) => ChatRoomModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> &&
            responseData['succeeded'] == true) {
          final rawList = _extractList(responseData);
          return rawList
              .map(
                (json) => ChatRoomModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
      }
      throw _handleError(e);
    }
  }

   Future<List<ChatMessageModel>> getChatHistory(
    String chatRoomId, {
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/chat/$chatRoomId/history',
        queryParameters: {'pageNumber': pageNumber, 'pageSize': pageSize},
      );

      final rawList = _extractList(response.data);
      return rawList
          .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> &&
            responseData['succeeded'] == true) {
          final rawList = _extractList(responseData);
          return rawList
              .map(
                (json) =>
                    ChatMessageModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
      }
      throw _handleError(e);
    }
  }

   Future<ChatRoomModel> getChatRoomDetails(String roomId) async {
    try {
      final response = await _dio.get('/chat/$roomId/details');
      final data = _extractData(response.data);
      return ChatRoomModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> &&
            responseData['succeeded'] == true) {
          return ChatRoomModel.fromJson(_extractData(responseData));
        }
      }
      throw _handleError(e);
    }
  }

   Future<void> markRoomAsRead(String roomId) async {
    try {
      await _dio.put('/chat/$roomId/read');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> &&
            responseData['succeeded'] == true) {
          return;
        }
      }
      throw _handleError(e);
    }
  }

   Future<void> closeChatRoom(String roomId) async {
    try {
      await _dio.put('/chat/$roomId/close');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> &&
            responseData['succeeded'] == true) {
          return;
        }
      }
      throw _handleError(e);
    }
  }

   Future<void> deleteMessage(String messageId) async {
    try {
      await _dio.delete('/chat/messages/$messageId');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> &&
            responseData['succeeded'] == true) {
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
      final data =
          responseData['data'] ??
          responseData['Data'] ??
          responseData['items'] ??
          responseData['Items'];
      if (data is List) {
        return data;
      }
    } else if (responseData is List) {
      return responseData;
    }
    return [];
  }

  Exception _handleError(DioException e) {
    debugPrint('🔥 DIO ERROR STATUS: ${e.response?.statusCode}');
    debugPrint('🔥 DIO ERROR DATA: ${e.response?.data}');

    if (e.response != null && e.response!.data != null) {
      final data = e.response!.data;
      
      // Handle ASP.NET Core Validation Errors (Status 400)
      if (data is Map) {
        if (data.containsKey('errors') && data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return Exception(firstError.first.toString());
          }
          return Exception(errors.toString());
        }
        
        // Handle custom backend message
        if (data.containsKey('message')) {
          return Exception(data['message'].toString());
        }
      }
      
      if (data is String) {
        if (data.contains('System.InvalidOperationException:')) {
          String cleanMsg = data.split('\n').first.replaceAll('System.InvalidOperationException:', '').trim();
          return Exception(cleanMsg);
        }
        String cleanMsg = data.split('\n').first.split('at ').first.trim();
        return Exception(cleanMsg);
      }
      return Exception('Server Error: ${e.response!.statusCode}');
    }
    return Exception(e.message ?? 'Unknown network error');
  }
}
