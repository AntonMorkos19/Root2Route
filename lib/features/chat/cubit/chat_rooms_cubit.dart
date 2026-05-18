import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/services/chat_service.dart';
import 'chat_rooms_state.dart';

class ChatRoomsCubit extends Cubit<ChatRoomsState> {
  final ChatService _chatService;

  ChatRoomsCubit(this._chatService) : super(ChatRoomsInitial());

  /// Fetch (or re-fetch) the list of chat rooms. Keeps previous data
  /// visible during refresh by NOT emitting Loading if already loaded.
  Future<void> fetchRooms({int pageNumber = 1, int pageSize = 20}) async {
    if (state is! ChatRoomsLoaded) {
      emit(ChatRoomsLoading());
    }
    try {
      final rooms = await _chatService.getMyRooms(
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      emit(ChatRoomsLoaded(rooms));
    } catch (e, stackTrace) {
      print("ERROR fetching rooms: $e");
      print("STACK: $stackTrace");
      emit(ChatRoomsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // Alias kept for backward compat
  Future<void> fetchMyRooms({int pageNumber = 1, int pageSize = 20}) =>
      fetchRooms(pageNumber: pageNumber, pageSize: pageSize);
}
