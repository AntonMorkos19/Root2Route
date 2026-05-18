import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/services/chat_service.dart';
import 'chat_rooms_state.dart';

class ChatRoomsCubit extends Cubit<ChatRoomsState> {
  final ChatService _chatService;

  ChatRoomsCubit(this._chatService) : super(ChatRoomsInitial());

  Future<void> fetchMyRooms({int pageNumber = 1, int pageSize = 20}) async {
    emit(ChatRoomsLoading());
    try {
      final rooms = await _chatService.getMyRooms(
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      emit(ChatRoomsLoaded(rooms));
    } catch (e) {
      emit(ChatRoomsError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
