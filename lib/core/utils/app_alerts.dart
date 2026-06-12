import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/core/navigator_service.dart';

/// Global alert helper — call from anywhere without needing a [BuildContext].
///
/// Usage (context-free):
/// ```dart
/// AppAlerts.showSuccess('تمت العملية بنجاح!');
/// AppAlerts.showError('حدث خطأ، يرجى المحاولة مرة أخرى.');
/// ```
///
/// Usage (explicit context — preferred inside widgets):
/// ```dart
/// AppAlerts.showSuccess('تمت العملية بنجاح!', context: context);
/// AppAlerts.showConfirm(
///   'هل أنت متأكد؟',
///   onConfirm: () { ... },
///   context: context,
/// );
/// ```
class AppAlerts {
  AppAlerts._(); // prevent instantiation

  // ─── internal context resolver ───────────────────────────────
  static BuildContext? _resolve(BuildContext? ctx) =>
      ctx ?? NavigatorService.navigatorKey.currentContext;

  // ─── Success ──────────────────────────────────────────────────

  static void showSuccess(
    String message, {
    BuildContext? context,
    String title = 'نجاح',
    String confirmBtnText = 'حسناً',
    VoidCallback? onConfirm,
  }) {
    final ctx = _resolve(context);
    if (ctx == null) return;
    QuickAlert.show(cancelBtnText: 'إلغاء', 
      context: ctx,
      type: QuickAlertType.success,
      title: title,
      text: message,
      confirmBtnText: confirmBtnText,
      onConfirmBtnTap: onConfirm,
    );
  }

  // ─── Error ────────────────────────────────────────────────────

  static void showError(
    String message, {
    BuildContext? context,
    String title = 'خطأ',
    String confirmBtnText = 'موافق',
    VoidCallback? onConfirm,
  }) {
    final ctx = _resolve(context);
    if (ctx == null) return;
    QuickAlert.show(cancelBtnText: 'إلغاء', 
      context: ctx,
      type: QuickAlertType.error,
      title: title,
      text: message,
      confirmBtnText: confirmBtnText,
      onConfirmBtnTap: onConfirm,
    );
  }

  // ─── Warning ──────────────────────────────────────────────────

  static void showWarning(
    String message, {
    BuildContext? context,
    String title = 'تحذير',
    String confirmBtnText = 'موافق',
    VoidCallback? onConfirm,
  }) {
    final ctx = _resolve(context);
    if (ctx == null) return;
    QuickAlert.show(cancelBtnText: 'إلغاء', 
      context: ctx,
      type: QuickAlertType.warning,
      title: title,
      text: message,
      confirmBtnText: confirmBtnText,
      onConfirmBtnTap: onConfirm,
    );
  }

  // ─── Confirm (with Cancel) ────────────────────────────────────

  static void showConfirm(
    String message, {
    BuildContext? context,
    String title = 'تأكيد',
    String confirmBtnText = 'تأكيد',
    String cancelBtnText = 'إلغاء',
    Color confirmBtnColor = const Color(0xFF4CAF50),
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    final ctx = _resolve(context);
    if (ctx == null) return;
    QuickAlert.show(
      context: ctx,
      type: QuickAlertType.confirm,
      title: title,
      text: message,
      confirmBtnText: confirmBtnText,
      cancelBtnText: cancelBtnText,
      showCancelBtn: true,
      confirmBtnColor: confirmBtnColor,
      onConfirmBtnTap: onConfirm,
      onCancelBtnTap: onCancel,
    );
  }

  // ─── Info ─────────────────────────────────────────────────────

  static void showInfo(
    String message, {
    BuildContext? context,
    String title = 'معلومة',
    String confirmBtnText = 'حسناً',
    VoidCallback? onConfirm,
  }) {
    final ctx = _resolve(context);
    if (ctx == null) return;
    QuickAlert.show(cancelBtnText: 'إلغاء', 
      context: ctx,
      type: QuickAlertType.info,
      title: title,
      text: message,
      confirmBtnText: confirmBtnText,
      onConfirmBtnTap: onConfirm,
    );
  }

  // ─── Loading (no buttons) ─────────────────────────────────────

  /// Shows a loading alert. Call [Navigator.pop] to dismiss it.
  static void showLoading({
    BuildContext? context,
    String text = 'جاري التحميل...',
  }) {
    final ctx = _resolve(context);
    if (ctx == null) return;
    QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
      context: ctx,
      type: QuickAlertType.loading,
      title: 'انتظر',
      text: text,
    );
  }
}
