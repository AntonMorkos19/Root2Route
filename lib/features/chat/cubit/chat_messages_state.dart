import 'package:root2route/models/chat_message_model.dart';

abstract class ChatMessagesState {}

class ChatMessagesInitial extends ChatMessagesState {}

class ChatMessagesLoading extends ChatMessagesState {}

class ChatMessagesLoaded extends ChatMessagesState {
  final List<ChatMessageModel> messages;
  final bool isSending;
  final bool isClosed;

  ChatMessagesLoaded(this.messages, {
    this.isSending = false,
    this.isClosed = false,
  });
}

class ChatMessagesError extends ChatMessagesState {
  final String message;

  ChatMessagesError(this.message);
}

/// Emitted when an action (send/accept/reject) fails, so the BlocBuilder 
/// can ignore it (keeping the message list visible) while the BlocListener shows a SnackBar.
class ChatMessagesActionError extends ChatMessagesState {
  final String message;

  ChatMessagesActionError(this.message);
}

