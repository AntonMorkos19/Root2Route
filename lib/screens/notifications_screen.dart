import 'package:quickalert/quickalert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/notifications/cubit/notification_cubit.dart';
import 'package:root2route/features/notifications/cubit/notification_state.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/core/utils/snackbar_helper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _invitations = [];
  bool _isLoadingInvitations = true;

  @override
  void initState() {
    super.initState();
    context.read<NotificationCubit>().fetchNotifications();
    _fetchInvitations();
  }

  Future<void> _fetchInvitations() async {
    setState(() => _isLoadingInvitations = true);
    final result = await _api.getMyInvitations();
    if (mounted) {
      setState(() {
        _invitations = result['success'] ? (result['data'] ?? []) : [];
        // Optional: filter out already accepted/rejected invites if the API doesn't do it
        _invitations = _invitations.where((inv) => inv['status'] == 0 || inv['Status'] == 0).toList();
        _isLoadingInvitations = false;
      });
    }
  }

  Future<void> _handleAccept(String invitationId) async {
    try {
      QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', context: context, type: QuickAlertType.loading, title: 'جاري التحميل', text: 'جاري قبول الدعوة...');
      final result = await _api.acceptInvitation(invitationId);
      if (mounted) // hideCurrentSnackBar removed for QuickAlert
      
      if (result['success']) {
        if (mounted) QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', context: context, type: QuickAlertType.success, title: 'نجاح', text: 'تم قبول الدعوة بنجاح!');
        _fetchInvitations();
      } else {
        if (mounted) QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', context: context, type: QuickAlertType.error, title: 'خطأ', text: result['message'] ?? 'فشل قبول الدعوة');
      }
    } catch (e) {
      debugPrint('Error accepting invitation: $e');
      if (mounted) {
        // hideCurrentSnackBar removed for QuickAlert
        QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', context: context, type: QuickAlertType.error, title: 'خطأ', text: e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _handleReject(String invitationId) async {
    QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', context: context, type: QuickAlertType.loading, title: 'جاري التحميل', text: 'جاري رفض الدعوة...');
    final result = await _api.rejectInvitation(invitationId);
    // hideCurrentSnackBar removed for QuickAlert
    
    if (result['success']) {
      QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', context: context, type: QuickAlertType.success, title: 'نجاح', text: 'تم رفض الدعوة');
      _fetchInvitations();
    } else {
      QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', context: context, type: QuickAlertType.error, title: 'خطأ', text: result['message'] ?? 'فشل رفض الدعوة');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "الإشعارات",
          style: TextStyle(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              context.read<NotificationCubit>().markAllAsRead();
            },
            child: const Text(
              "تحديد الكل كمقروء",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        iconTheme: IconThemeData(
          color: Theme.of(context).appBarTheme.iconTheme?.color,
        ),
      ),
      body: Column(
        children: [
          if (_isLoadingInvitations)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_invitations.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.centerRight,
              child: const Text(
                'دعوات الانضمام',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _invitations.length,
              itemBuilder: (context, index) {
                final invite = _invitations[index];
                return _buildInvitationCard(invite);
              },
            ),
            const Divider(thickness: 2),
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.centerRight,
              child: const Text(
                'الإشعارات الأخرى',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          Expanded(
            child: BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, state) {
                if (state is NotificationLoading || state is NotificationInitial) {
                  return const Center(child: CircularProgressIndicator());
          } else if (state is NotificationError) {
            return Center(child: Text(state.message));
          } else if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return const Center(child: Text("لا توجد إشعارات حتى الآن"));
            }

            return ListView.separated(
              itemCount: state.notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return InkWell(
                  onTap: () {
                    if (!notification.isRead) {
                      context.read<NotificationCubit>().markAsRead(
                        notification.id,
                      );
                    }
                  },
                  child: Container(
                    color:
                        notification.isRead
                            ? Colors.transparent
                            : AppColors.primary.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              notification.isRead
                                  ? Colors.grey.shade300
                                  : AppColors.primary,
                          child: Icon(
                            Icons.notifications,
                            color:
                                notification.isRead
                                    ? Colors.grey.shade600
                                    : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight:
                                      notification.isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.message,
                                style: TextStyle(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (notification.createdAt != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  "${notification.createdAt!.day}/${notification.createdAt!.month}/${notification.createdAt!.year} ${notification.createdAt!.hour}:${notification.createdAt!.minute.toString().padLeft(2, '0')}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: Text("حالة غير معروفة"));
        },
      ),
          ),
        ],
      ),
    ));
  }

  Widget _buildInvitationCard(dynamic invite) {
    final String orgName = invite['organizationName'] ?? invite['OrganizationName'] ?? 'شركة غير معروفة';
    final String invId = invite['id']?.toString() ?? invite['Id']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.business, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'دعوة للانضمام',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'قامت $orgName بدعوتك للانضمام.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAccept(invId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('قبول'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleReject(invId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('رفض'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
