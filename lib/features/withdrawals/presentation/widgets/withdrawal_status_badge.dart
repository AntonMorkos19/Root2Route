import 'package:flutter/material.dart';
import 'package:root2route/features/withdrawals/data/models/withdrawal_model.dart';

/// A small colored chip widget that reflects a withdrawal's current status.
/// Kept as a pure presentational widget — no cubit dependency.
class WithdrawalStatusBadge extends StatelessWidget {
  final WithdrawalStatus status;

  const WithdrawalStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _badgeConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: config.foreground),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              color: config.foreground,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Maps each [WithdrawalStatus] to its visual configuration.
  _BadgeConfig _badgeConfig(WithdrawalStatus status) {
    switch (status) {
      case WithdrawalStatus.pending:
        return _BadgeConfig(
          label: 'قيد الانتظار',
          icon: Icons.hourglass_empty_rounded,
          background: Colors.grey.shade200,
          foreground: Colors.grey.shade700,
        );
      case WithdrawalStatus.approved:
        return _BadgeConfig(
          label: 'موافق عليه',
          icon: Icons.check_circle_outline_rounded,
          background: Colors.blue.shade50,
          foreground: Colors.blue.shade700,
        );
      case WithdrawalStatus.processed:
        return _BadgeConfig(
          label: 'تمت المعالجة',
          icon: Icons.done_all_rounded,
          background: Colors.green.shade50,
          foreground: Colors.green.shade700,
        );
      case WithdrawalStatus.rejected:
        return _BadgeConfig(
          label: 'مرفوض',
          icon: Icons.cancel_outlined,
          background: Colors.red.shade50,
          foreground: Colors.red.shade700,
        );
    }
  }
}

/// Internal configuration holder for a badge's appearance.
class _BadgeConfig {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  const _BadgeConfig({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });
}
