import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/chat/cubit/chat_messages_cubit.dart';
import 'package:root2route/features/chat/cubit/chat_messages_state.dart';
import 'package:root2route/models/chat_message_model.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/features/chat/widgets/negotiation_offer_card.dart';
import 'package:root2route/features/chat/widgets/negotiation_dialog.dart';
import 'package:root2route/core/utils/price_formatter.dart';
class ChatDetailsScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final bool isClosed;
  final String roomOrgId;
  final bool allowNegotiation;

  const ChatDetailsScreen({
    Key? key,
    required this.roomId,
    this.roomName = 'Chat',
    this.isClosed = false,
    this.roomOrgId = '',
    this.allowNegotiation = false,
  }) : super(key: key);

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;
  int _previousMessageCount = 0;
  late bool _isClosed; // local mirror so UI updates instantly after closing

  @override
  void initState() {
    super.initState();
    _isClosed = widget.isClosed;
    _currentUserId = StorageService().currentUserId;
    context.read<ChatMessagesCubit>().fetchHistory(widget.roomId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (_containsContactInfo(text)) {
      _showContactInfoError();
      return;
    }
    _messageController.clear();
    context.read<ChatMessagesCubit>().sendMessage(widget.roomId, text);
    _scrollToBottom();
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

  void _showContactInfoError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'عفواً، لا يُسمح بمشاركة أرقام الهواتف أو البريد الإلكتروني حفاظاً على سياسة المنصة.',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showNegotiationDialog() {
    final chatCubit = context.read<ChatMessagesCubit>();
    showNegotiationDialog(context, (price, quantity) {
      final String offerContent =
          'عرض: $quantity عنصر مقابل ${PriceFormatter.format(price)} جنيه';
      if (_containsContactInfo(offerContent)) {
        _showContactInfoError();
        return;
      }
      chatCubit.sendMessage(
        widget.roomId,
        offerContent,
        type: 3,
        proposedPrice: price,
        proposedQuantity: quantity,
      );
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatMessagesCubit, ChatMessagesState>(
              listener: (context, state) {
                if (state is ChatMessagesLoaded) {
                  if (state.isClosed && !_isClosed) {
                    setState(() => _isClosed = true);
                  }

                  if (state.messages.length > _previousMessageCount) {
                    _previousMessageCount = state.messages.length;
                    _scrollToBottom();
                  }
                }
                if (state is ChatMessagesError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red.shade400,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
                if (state is ChatMessagesActionError) {
                  String displayMsg = state.message;
                  if (displayMsg.contains('Insufficient product stock') && displayMsg.contains('available for negotiation')) {
                    final match = RegExp(r'Only (\d+) available').firstMatch(displayMsg);
                    final availableStock = match != null ? match.group(1) : '';
                    displayMsg = 'الكمية غير كافية. المتاح للتفاوض هو $availableStock فقط.';
                  } else if (displayMsg.contains('Insufficient product stock')) {
                    displayMsg = 'الكمية غير كافية.';
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        displayMsg,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.orange.shade800,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              buildWhen:
                  (previous, current) => current is! ChatMessagesActionError,
              builder: (context, state) {
                if (state is ChatMessagesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Full-screen error only for initial load failure (no prior messages loaded)
                if (state is ChatMessagesError) {
                  return _buildError(state.message);
                }
                if (state is ChatMessagesLoaded) {
                  if (state.messages.isEmpty && !state.isSending) {
                    return _buildEmpty();
                  }
                  return _buildMessageList(state.messages, state.isSending);
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0.5,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          size: 20,
          color: Theme.of(context).iconTheme.color,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.green.withValues(alpha: 0.15),
            child: Text(
              widget.roomName.isNotEmpty
                  ? widget.roomName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.roomName,
              style: TextStyle(
                color: Theme.of(context).textTheme.titleMedium?.color,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        if (!_isClosed)
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).iconTheme.color,
            ),
            onSelected: (value) {
              if (value == 'close') _confirmCloseRoom();
            },
            itemBuilder:
                (_) => [
                  const PopupMenuItem(
                    value: 'close',
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('End Chat', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Closed',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmCloseRoom() async {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      title: 'End Conversation?',
      text: 'This will close the chat. Neither party will be able to send new messages.',
      barrierDismissible: false,
      showCancelBtn: true,
      cancelBtnText: 'Cancel',
      confirmBtnText: 'End Chat',
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        Navigator.pop(context); // Close dialog
        if (mounted) {
          await context.read<ChatMessagesCubit>().closeRoom(widget.roomId);
          if (mounted) setState(() => _isClosed = true);
        }
      },
    );
  }

  void _showDeleteDialog(String messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Delete Message',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<ChatMessagesCubit>().deleteMessage(messageId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  Widget _buildMessageList(List<ChatMessageModel> messages, bool isSending) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<ChatMessagesCubit>().fetchHistory(
          widget.roomId,
          isSilent: true,
        );
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        itemCount: messages.length + (isSending ? 1 : 0),
        itemBuilder: (context, index) {
          // Sending indicator at the end
          if (isSending && index == messages.length) {
            return Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8, right: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }

          final message = messages[index];
          final isMe = message.senderId == _currentUserId;
          final showDate =
              index == 0 ||
              _shouldShowDateDivider(messages[index - 1], message);

          return Column(
            children: [
              if (showDate) _buildDateDivider(message.createdAt),
              _buildBubble(message, isMe),
            ],
          );
        },
      ),
    );
  }

  bool _shouldShowDateDivider(ChatMessageModel prev, ChatMessageModel current) {
    if (prev.createdAt == null || current.createdAt == null) return false;
    return prev.createdAt!.day != current.createdAt!.day ||
        prev.createdAt!.month != current.createdAt!.month;
  }

  Widget _buildDateDivider(DateTime? date) {
    if (date == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final label =
        (date.year == now.year &&
                date.month == now.month &&
                date.day == now.day)
            ? 'Today'
            : '${date.day}/${date.month}/${date.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Theme.of(context).dividerColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Theme.of(context).dividerColor)),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessageModel message, bool isMe) {
    // Temp messages (optimistic) have ids starting with 'temp_'
    final isOptimistic = message.id.startsWith('temp_');

    String displayText = message.text;
    if (displayText.startsWith('Offer Accepted. Order Generated:')) {
      displayText = 'Offer accepted ✅';
    } else if (displayText.isEmpty) {
      displayText = '📎 Attachment';
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 6,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              // Long-press on own confirmed messages shows delete option
              onLongPress:
                  isMe && !isOptimistic
                      ? () => _showDeleteDialog(message.id)
                      : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.type == 3)
                      NegotiationOfferCard(
                        price: message.proposedPrice ?? 0.0,
                        quantity: message.proposedQuantity ?? 0,
                        offerStatus: message.offerStatus,
                        isMe: isMe,
                        onAccept:
                            () => context.read<ChatMessagesCubit>().acceptOffer(
                              widget.roomId,
                              message.id,
                            ),
                        onReject:
                            () => context.read<ChatMessagesCubit>().rejectOffer(
                              widget.roomId,
                              message.id,
                            ),
                      )
                    else
                      Text(
                        displayText,
                        style: TextStyle(
                          color:
                              isMe
                                  ? Colors.white
                                  : Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                          fontSize: 16.sp,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isOptimistic ? Icons.access_time : Icons.done_all,
                    size: 14,
                    color:
                        isOptimistic
                            ? Colors.grey.shade400
                            : Colors.green.shade400,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    if (_isClosed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'This conversation is closed.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final String currentOrgId = StorageService().currentUserOrgId ?? '';
    final bool isSeller =
        currentOrgId.isNotEmpty && currentOrgId == widget.roomOrgId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (!isSeller && widget.allowNegotiation)
              IconButton(
                icon: const Icon(Icons.handshake_outlined, color: Colors.blue),
                onPressed: () {
                  debugPrint("DEBUG: Handshake clicked!");
                  _showNegotiationDialog();
                },
              ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: "اكتب رسالة...",
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
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
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Say hello to start the conversation!',
            style: TextStyle(
              fontSize: 15.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed:
                  () => context.read<ChatMessagesCubit>().fetchHistory(
                    widget.roomId,
                  ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
