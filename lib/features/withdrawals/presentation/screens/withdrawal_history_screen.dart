import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/core/utils/price_formatter.dart';
import 'package:root2route/features/withdrawals/data/models/withdrawal_model.dart';
import 'package:root2route/features/withdrawals/logic/withdrawal_cubit/withdrawal_cubit.dart';
import 'package:root2route/features/withdrawals/logic/withdrawal_cubit/withdrawal_state.dart';
import 'package:root2route/features/withdrawals/presentation/widgets/withdrawal_status_badge.dart';

/// Displays the withdrawal history for the current organization.
/// Supports pull-to-refresh and shows the admin rejection note when applicable.
class WithdrawalHistoryScreen extends StatefulWidget {
  const WithdrawalHistoryScreen({super.key});

  @override
  State<WithdrawalHistoryScreen> createState() =>
      _WithdrawalHistoryScreenState();
}

class _WithdrawalHistoryScreenState extends State<WithdrawalHistoryScreen> {
  late final WithdrawalCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = WithdrawalCubit()..fetchOrgWithdrawals();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WithdrawalCubit>.value(
      value: _cubit,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'سجل طلبات السحب',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            centerTitle: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: BlocBuilder<WithdrawalCubit, WithdrawalState>(
            builder: (context, state) {
              if (state is WithdrawalInitial || state is WithdrawalLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (state is WithdrawalError) {
                return _ErrorView(
                  message: state.message,
                  onRetry: _cubit.fetchOrgWithdrawals,
                );
              }

              final withdrawals =
                  state is WithdrawalListLoaded ? state.withdrawals : <WithdrawalModel>[];

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _cubit.fetchOrgWithdrawals,
                child:
                    withdrawals.isEmpty
                        ? _EmptyView()
                        : ListView.separated(
                          padding: EdgeInsets.all(16.w),
                          itemCount: withdrawals.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) =>
                              _WithdrawalCard(withdrawal: withdrawals[index]),
                        ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Withdrawal card
// ─────────────────────────────────────────────────────────────────────────────

class _WithdrawalCard extends StatelessWidget {
  final WithdrawalModel withdrawal;

  const _WithdrawalCard({required this.withdrawal});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        withdrawal.createdAt != null
            ? '${withdrawal.createdAt!.day}/${withdrawal.createdAt!.month}/${withdrawal.createdAt!.year}'
            : '—';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: amount + status badge ───────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${PriceFormatter.format(withdrawal.amount)} جنيه',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              WithdrawalStatusBadge(status: withdrawal.status),
            ],
          ),
          SizedBox(height: 10.h),
          const Divider(height: 1),
          SizedBox(height: 10.h),

          // ── Bank name ──────────────────────────────────────────────────
          _InfoRow(
            icon: Icons.account_balance_rounded,
            label: 'البنك',
            value: withdrawal.bankName,
          ),
          SizedBox(height: 6.h),

          // ── Account number ─────────────────────────────────────────────
          _InfoRow(
            icon: Icons.credit_card_rounded,
            label: 'رقم الحساب',
            value: withdrawal.accountNumber,
          ),
          SizedBox(height: 6.h),

          // ── Date ───────────────────────────────────────────────────────
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'التاريخ',
            value: dateStr,
          ),

          // ── Admin note (only shown for rejected withdrawals) ───────────
          if (withdrawal.status == WithdrawalStatus.rejected &&
              withdrawal.adminNote != null &&
              withdrawal.adminNote!.isNotEmpty) ...[
            SizedBox(height: 10.h),
            const Divider(height: 1),
            SizedBox(height: 10.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.comment_outlined,
                  size: 16.w,
                  color: Colors.red.shade400,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سبب الرفض:',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        withdrawal.adminNote!,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15.w, color: Theme.of(context).colorScheme.outline),
        SizedBox(width: 6.w),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد طلبات سحب حتى الآن',
              style: TextStyle(
                fontSize: 18.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على الزر أدناه لتقديم طلب سحب جديد',
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 60, color: Colors.red.shade300),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
