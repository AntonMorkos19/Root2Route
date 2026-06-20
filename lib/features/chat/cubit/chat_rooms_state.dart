import 'package:root2route/features/chat/data/models/chat_room_model.dart';

abstract class ChatRoomsState {}

class ChatRoomsInitial extends ChatRoomsState {}

class ChatRoomsLoading extends ChatRoomsState {}

class ChatRoomsLoaded extends ChatRoomsState {
  final List<ChatRoomModel> rooms;

  ChatRoomsLoaded(this.rooms);
}

class ChatRoomsError extends ChatRoomsState {
  final String message;

  ChatRoomsError(this.message);
}
