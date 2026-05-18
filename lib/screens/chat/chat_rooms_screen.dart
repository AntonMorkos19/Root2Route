import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/chat/cubit/chat_rooms_cubit.dart';
import 'package:root2route/features/chat/cubit/chat_rooms_state.dart';
import 'package:root2route/features/chat/cubit/chat_messages_cubit.dart';
import 'package:root2route/services/chat_service.dart';
import 'chat_screen.dart';

class ChatRoomsScreen extends StatefulWidget {
  const ChatRoomsScreen({Key? key}) : super(key: key);

  @override
  State<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends State<ChatRoomsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChatRoomsCubit>().fetchMyRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Rooms'),
      ),
      body: BlocBuilder<ChatRoomsCubit, ChatRoomsState>(
        builder: (context, state) {
          if (state is ChatRoomsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ChatRoomsError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is ChatRoomsLoaded) {
            if (state.rooms.isEmpty) {
              return const Center(child: Text('No chat rooms available.'));
            }
            return RefreshIndicator(
              onRefresh: () async {
                await context.read<ChatRoomsCubit>().fetchMyRooms();
              },
              child: ListView.separated(
                itemCount: state.rooms.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final room = state.rooms[index];
                  final participantName = room.participants.isNotEmpty 
                      ? room.participants.join(', ') 
                      : 'Unknown User';

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(participantName.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(
                      participantName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      room.lastMessage.isEmpty ? 'No messages yet' : room.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: room.unreadCount > 0
                        ? Badge(
                            label: Text(room.unreadCount.toString()),
                            backgroundColor: Colors.red,
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (_) => ChatMessagesCubit(ChatService()),
                            child: ChatScreen(roomId: room.id),
                          ),
                        ),
                      ).then((_) {
                        context.read<ChatRoomsCubit>().fetchMyRooms();
                      });
                    },
                  );
                },
              ),
            );
          }
          return const Center(child: Text('Initializing...'));
        },
      ),
    );
  }
}
