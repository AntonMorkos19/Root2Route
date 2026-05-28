import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/chat/cubit/chat_messages_cubit.dart';
import 'package:root2route/features/chat/cubit/chat_rooms_cubit.dart';
import 'package:root2route/features/chat/cubit/chat_rooms_state.dart';
import 'package:root2route/models/chat_room_model.dart';
import 'package:root2route/services/chat_service.dart';
import 'package:root2route/services/storage_service.dart';
import 'chat_details_screen.dart';

class ChatRoomsScreen extends StatefulWidget {
  const ChatRoomsScreen({Key? key}) : super(key: key);

  @override
  State<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends State<ChatRoomsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChatRoomsCubit>().fetchRooms();
  }

  Future<void> _openChat(ChatRoomModel room, String displayName) async {
    // 1. Await navigation — screen won't resume until user pops back
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => ChatMessagesCubit(ChatService()),
          child: ChatDetailsScreen(
            roomId: room.id,
            roomName: displayName,
            isClosed: room.isClosed,
            roomOrgId: room.organizationId,
          ),
        ),
      ),
    );
    // 2. Refresh rooms list to clear the badge on the tapped room
    if (mounted) {
      context.read<ChatRoomsCubit>().fetchRooms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
          ),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: BlocBuilder<ChatRoomsCubit, ChatRoomsState>(
        builder: (context, state) {
          if (state is ChatRoomsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ChatRoomsError) {
            return _buildError(state.message);
          }
          if (state is ChatRoomsLoaded) {
            if (state.rooms.isEmpty) {
              return _buildEmpty();
            }
            return RefreshIndicator(
              onRefresh: () => context.read<ChatRoomsCubit>().fetchRooms(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.rooms.length,
                itemBuilder: (context, index) =>
                    _buildRoomTile(state.rooms[index]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildRoomTile(ChatRoomModel room) {
    final hasUnread = room.unreadCount > 0;

    // No longer need isSeller since we use otherPartyName directly from backend

    // Use the backend-provided otherPartyName or chatTitle, fallback to Unknown
    final String displayName = (room.otherPartyName != null && room.otherPartyName!.isNotEmpty)
        ? room.otherPartyName!
        : (room.chatTitle.isNotEmpty ? room.chatTitle : 'Unknown');

    return InkWell(
      onTap: () => _openChat(room, displayName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.green.withValues(alpha: 0.15),
                  child: Text(
                    displayName[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 20.sp,
                    ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontWeight:
                          hasUnread ? FontWeight.bold : FontWeight.w600,
                      fontSize: 16.sp,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    room.lastMessage.isEmpty
                        ? 'No messages yet'
                        : room.lastMessage,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: hasUnread
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: hasUnread
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Unread badge
            if (hasUnread)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  room.unreadCount > 99 ? '99+' : room.unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 72, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact a seller on any product page\nto start a conversation.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.read<ChatRoomsCubit>().fetchRooms(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
