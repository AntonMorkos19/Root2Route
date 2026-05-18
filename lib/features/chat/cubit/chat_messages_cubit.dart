import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/services/chat_service.dart';
import 'package:root2route/models/chat_message_model.dart';
import 'package:root2route/services/storage_service.dart';
import 'chat_messages_state.dart';

class ChatMessagesCubit extends Cubit<ChatMessagesState> {
  final ChatService _chatService;

  ChatMessagesCubit(this._chatService) : super(ChatMessagesInitial());

  Future<void> fetchHistory(String roomId, {int pageNumber = 1, int pageSize = 50}) async {
    emit(ChatMessagesLoading());
    try {
      final messages = await _chatService.getChatHistory(
        roomId,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      emit(ChatMessagesLoaded(messages));
    } catch (e) {
      emit(ChatMessagesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> sendMessage(
    String roomId,
    String content, {
    int type = 0,
    double? proposedPrice,
    int? proposedQuantity,
    String? imageFilePath,
  }) async {
    final currentState = state;
    List<ChatMessageModel> currentMessages = [];

    if (currentState is ChatMessagesLoaded) {
      currentMessages = List.from(currentState.messages);
      emit(ChatMessagesLoaded(currentMessages, isSending: true));
    } else {
      emit(ChatMessagesLoading());
    }

    final currentUserId = StorageService().currentUserId ?? '';

    try {
      final newMessage = await _chatService.sendMessage(
        chatRoomId: roomId,
        content: content,
        currentUserId: currentUserId,
        type: type,
        proposedPrice: proposedPrice,
        proposedQuantity: proposedQuantity,
        imageFilePath: imageFilePath,
      );

      currentMessages.add(newMessage);
      emit(ChatMessagesLoaded(currentMessages, isSending: false));
    } catch (e) {
      if (currentState is ChatMessagesLoaded) {
        emit(ChatMessagesLoaded(currentMessages, isSending: false));
      }
      emit(ChatMessagesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> acceptOffer(String roomId, String messageId) async {
    try {
      await _chatService.acceptOffer(messageId);
      _updateMessageStatus(messageId, 'accepted');
    } catch (e) {
      emit(ChatMessagesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> rejectOffer(String roomId, String messageId) async {
    try {
      await _chatService.rejectOffer(messageId);
      _updateMessageStatus(messageId, 'rejected');
    } catch (e) {
      emit(ChatMessagesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> closeRoom(String roomId) async {
    try {
      await _chatService.closeChatRoom(roomId);
    } catch (e) {
      emit(ChatMessagesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _updateMessageStatus(String messageId, String newStatus) {
    if (state is ChatMessagesLoaded) {
      final currentState = state as ChatMessagesLoaded;
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == messageId) {
          return ChatMessageModel(
            id: msg.id,
            roomId: msg.roomId,
            senderId: msg.senderId,
            text: msg.text,
            isOffer: msg.isOffer,
            offerStatus: newStatus,
            createdAt: msg.createdAt,
          );
        }
        return msg;
      }).toList();

      emit(ChatMessagesLoaded(updatedMessages, isSending: currentState.isSending));
    }
  }
}
