import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/services/chat_service.dart';
import 'package:root2route/models/chat_message_model.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/services/chat_hub_service.dart';
import 'chat_messages_state.dart';

class ChatMessagesCubit extends Cubit<ChatMessagesState> {
  final ChatService _chatService;
  final ChatHubService _chatHubService = ChatHubService();
  StreamSubscription? _messageSubscription;
  String? _currentRoomId;

  ChatMessagesCubit(this._chatService) : super(ChatMessagesInitial());

  Future<void> fetchHistory(String roomId,
      {int pageNumber = 1, int pageSize = 50, bool isSilent = false}) async {
    _currentRoomId = roomId;
    if (!isSilent) emit(ChatMessagesLoading());
    try {
      final messages = await _chatService.getChatHistory(
        roomId,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      emit(ChatMessagesLoaded(messages));

      // Mark room as read immediately so backend clears the unread counter
      _markAsRead(roomId);

      // Connect to SignalR for real-time messages
      final token = StorageService().token;
      if (token != null && token.isNotEmpty) {
        await _chatHubService.connect(token);
        await _chatHubService.joinRoom(roomId);

        _messageSubscription?.cancel();
        _messageSubscription =
            _chatHubService.onMessageReceived.listen((newMessage) {
          if (state is ChatMessagesLoaded) {
            final currentState = state as ChatMessagesLoaded;
            final exists =
                currentState.messages.any((m) => m.id == newMessage.id);
            if (!exists) {
              final updated =
                  List<ChatMessageModel>.from(currentState.messages)
                    ..add(newMessage);
              emit(ChatMessagesLoaded(updated,
                  isSending: currentState.isSending));
            } else {
              // If the message already exists, it might be an update (like offer status changed)
              final updated = currentState.messages
                  .map((m) => m.id == newMessage.id ? newMessage : m)
                  .toList();
              emit(ChatMessagesLoaded(updated,
                  isSending: currentState.isSending));
            }
          }
        });
      }
    } catch (e, stackTrace) {
      debugPrint("ERROR fetching history: $e");
      debugPrint("STACK: $stackTrace");
      if (!isSilent) {
        emit(ChatMessagesError("Failed to load messages. Please try again."));
      } else {
        emit(ChatMessagesActionError("Failed to refresh messages."));
        // restore state if we failed silently
        if (state is ChatMessagesLoaded) {
          emit(ChatMessagesLoaded((state as ChatMessagesLoaded).messages, isSending: (state as ChatMessagesLoaded).isSending));
        }
      }
    }
  }

  /// Silently mark the room as read – errors are swallowed so they
  /// don't disrupt the chat UI.
  void _markAsRead(String roomId) {
    _chatService.markRoomAsRead(roomId).catchError((e) {
      debugPrint("markRoomAsRead failed (non-critical): $e");
    });
  }

  /// Optimistic send: immediately append a temporary message to the list,
  /// then replace it with the confirmed server response.
  Future<void> sendMessage(
    String roomId,
    String content, {
    int type = 0,
    double? proposedPrice,
    int? proposedQuantity,
    String? imageFilePath,
  }) async {
    final currentUserId = StorageService().currentUserId ?? '';

    // Build an optimistic placeholder message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = ChatMessageModel(
      id: tempId,
      roomId: roomId,
      senderId: currentUserId,
      text: content,
      createdAt: DateTime.now(),
      type: type,
    );

    List<ChatMessageModel> currentMessages = [];
    if (state is ChatMessagesLoaded) {
      currentMessages = List.from((state as ChatMessagesLoaded).messages);
    }

    // Append optimistic message and set isSending = true
    emit(ChatMessagesLoaded(
      [...currentMessages, optimisticMsg],
      isSending: true,
    ));

    try {
      final confirmedMsg = await _chatService.sendMessage(
        chatRoomId: roomId,
        content: content,
        currentUserId: currentUserId,
        type: type,
        proposedPrice: proposedPrice,
        proposedQuantity: proposedQuantity,
        imageFilePath: imageFilePath,
      );

      // Deduplicate: If SignalR arrived first, remove temp. Otherwise, replace temp.
      final currentState = state as ChatMessagesLoaded;
      final alreadyExists = currentState.messages.any((m) => m.id == confirmedMsg.id);
      
      List<ChatMessageModel> updated;
      if (alreadyExists) {
        updated = currentState.messages.where((m) => m.id != tempId).toList();
      } else {
        updated = currentState.messages
            .map((m) => m.id == tempId ? confirmedMsg : m)
            .toList();
      }
      
      emit(ChatMessagesLoaded(
        updated,
        isSending: false,
        isClosed: currentState.isClosed,
      ));
    } catch (e, stackTrace) {
      debugPrint("ERROR sending message: $e");
      debugPrint("STACK: $stackTrace");
      // Remove the failed optimistic message and restore previous list
      currentMessages.removeWhere((m) => m.id == tempId);
      
      final errorMsg = e.toString().replaceAll('Exception: ', '').trim();
      
      if (errorMsg == 'This chat room is closed.') {
        // Trigger UI lockdown dynamically instead of showing an error
        emit(ChatMessagesLoaded(currentMessages, isSending: false, isClosed: true));
      } else {
        // Emit action error for SnackBar, then restore Loaded state for UI
        emit(ChatMessagesActionError(errorMsg));
        emit(ChatMessagesLoaded(currentMessages, isSending: false));
      }
    }
  }

  Future<void> acceptOffer(String roomId, String messageId) async {
    try {
      await _chatService.acceptOffer(messageId);
      _updateMessageStatus(messageId, 'accepted');
    } catch (e, stackTrace) {
      debugPrint("ERROR accepting offer: $e");
      debugPrint("STACK: $stackTrace");
      emit(ChatMessagesActionError("Failed to accept offer."));
      if (state is ChatMessagesLoaded) {
        emit(ChatMessagesLoaded((state as ChatMessagesLoaded).messages, isSending: (state as ChatMessagesLoaded).isSending));
      }
    }
  }

  Future<void> rejectOffer(String roomId, String messageId) async {
    try {
      await _chatService.rejectOffer(messageId);
      _updateMessageStatus(messageId, 'rejected');
    } catch (e, stackTrace) {
      debugPrint("ERROR rejecting offer: $e");
      debugPrint("STACK: $stackTrace");
      emit(ChatMessagesActionError("Failed to reject offer."));
      if (state is ChatMessagesLoaded) {
        emit(ChatMessagesLoaded((state as ChatMessagesLoaded).messages, isSending: (state as ChatMessagesLoaded).isSending));
      }
    }
  }

  Future<void> closeRoom(String roomId) async {
    try {
      await _chatService.closeChatRoom(roomId);
    } catch (e, stackTrace) {
      debugPrint("ERROR closing room: $e");
      debugPrint("STACK: $stackTrace");
      emit(ChatMessagesActionError(e.toString().replaceAll('Exception: ', '')));
      if (state is ChatMessagesLoaded) {
        emit(ChatMessagesLoaded((state as ChatMessagesLoaded).messages, isSending: (state as ChatMessagesLoaded).isSending));
      }
    }
  }

  Future<void> deleteMessage(String messageId) async {
    if (state is! ChatMessagesLoaded) return;
    final currentState = state as ChatMessagesLoaded;
    try {
      await _chatService.deleteMessage(messageId);
      // Remove message locally — no need to re-fetch
      final updated = currentState.messages
          .where((m) => m.id != messageId)
          .toList();
      emit(ChatMessagesLoaded(updated, isSending: currentState.isSending));
    } catch (e, stackTrace) {
      debugPrint("ERROR deleting message: $e");
      debugPrint("STACK: $stackTrace");
      emit(ChatMessagesActionError(e.toString().replaceAll('Exception: ', '')));
      emit(ChatMessagesLoaded(currentState.messages, isSending: currentState.isSending));
    }
  }

  void _updateMessageStatus(String messageId, String newStatus) {
    if (state is ChatMessagesLoaded) {
      final currentState = state as ChatMessagesLoaded;
      final updated = currentState.messages.map((msg) {
        if (msg.id == messageId) {
          return ChatMessageModel(
            id: msg.id,
            roomId: msg.roomId,
            senderId: msg.senderId,
            text: msg.text,
            isOffer: msg.isOffer,
            offerStatus: newStatus,
            createdAt: msg.createdAt,
            type: msg.type,
            proposedPrice: msg.proposedPrice,
            proposedQuantity: msg.proposedQuantity,
          );
        }
        return msg;
      }).toList();
      emit(ChatMessagesLoaded(updated, isSending: currentState.isSending));
    }
  }

  @override
  Future<void> close() async {
    await _cleanup();
    return super.close();
  }

  Future<void> _cleanup() async {
    _messageSubscription?.cancel();
    if (_currentRoomId != null) {
      await _chatHubService.leaveRoom(_currentRoomId!);
    }
    await _chatHubService.disconnect();
    _chatHubService.dispose();
  }
}
