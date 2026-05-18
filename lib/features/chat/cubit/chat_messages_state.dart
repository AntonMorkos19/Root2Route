import 'package:root2route/models/chat_message_model.dart';

abstract class ChatMessagesState {}

class ChatMessagesInitial extends ChatMessagesState {}

class ChatMessagesLoading extends ChatMessagesState {}

class ChatMessagesLoaded extends ChatMessagesState {
  final List<ChatMessageModel> messages;
  final bool isSending;

  ChatMessagesLoaded(this.messages, {this.isSending = false});
}

class ChatMessagesError extends ChatMessagesState {
  final String message;

  ChatMessagesError(this.message);
}
