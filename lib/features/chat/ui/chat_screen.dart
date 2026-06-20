import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/chat/cubit/chat_messages_cubit.dart';
import 'package:root2route/features/chat/cubit/chat_messages_state.dart';
import 'package:root2route/features/chat/data/models/chat_message_model.dart';
import 'package:root2route/core/services/storage_service.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;

  const ChatScreen({Key? key, required this.roomId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = StorageService().currentUserId;
    context.read<ChatMessagesCubit>().fetchHistory(widget.roomId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      if (_containsContactInfo(text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'عفواً، لا يُسمح بمشاركة أرقام الهواتف أو البريد الإلكتروني حفاظاً على سياسة المنصة.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
      context.read<ChatMessagesCubit>().sendMessage(widget.roomId, text);
      _messageController.clear();
    }
  }

  bool _containsContactInfo(String text) {
    final emailRegex = RegExp(
      r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    );
    final phoneRegex = RegExp(
      r'(\+20|0)?1[0125][0-9]{8}|\+?\d{10,15}',
    );
    return emailRegex.hasMatch(text) || phoneRegex.hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الدردشة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              context.read<ChatMessagesCubit>().closeRoom(widget.roomId);
              Navigator.pop(context);
            },
            tooltip: 'إغلاق الغرفة',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatMessagesCubit, ChatMessagesState>(
                builder: (context, state) {
                  if (state is ChatMessagesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ChatMessagesError) {
                    return Center(child: Text('خطأ: ${state.message}'));
                  } else if (state is ChatMessagesLoaded) {
                    final messages = state.messages;
                    if (messages.isEmpty) {
                      return const Center(child: Text('لا توجد رسائل حتى الآن.'));
                    }

                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length + (state.isSending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (state.isSending && index == 0) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        final msgIndex = state.isSending ? index - 1 : index;
                        final message =
                            messages[messages.length - 1 - msgIndex];
                        final isMe = message.senderId == _currentUserId;

                        return _buildMessageBubble(message, isMe, context);
                      },
                    );
                  }
                  return const Center(child: Text('جاري التهيئة...'));
                },
              ),
            ),
            _buildChatInput(),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessageModel message,
    bool isMe,
    BuildContext context,
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
            if (message.isOffer) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'حالة العرض: ${message.offerStatus.toUpperCase()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!isMe &&
                        (message.offerStatus == 'pending' ||
                            message.offerStatus == '')) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(80, 36),
                            ),
                            onPressed: () {
                              context.read<ChatMessagesCubit>().acceptOffer(
                                widget.roomId,
                                message.id,
                              );
                            },
                            child: const Text('قبول'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(80, 36),
                            ),
                            onPressed: () {
                              context.read<ChatMessagesCubit>().rejectOffer(
                                widget.roomId,
                                message.id,
                              );
                            },
                            child: const Text('رفض'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'اكتب رسالة...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
