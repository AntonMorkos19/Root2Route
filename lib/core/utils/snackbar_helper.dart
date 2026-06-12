import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/core/navigator_service.dart';

class CustomSnackBar {
  static void showSuccess(BuildContext? context, String message) {
    QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
      context: context ?? NavigatorService.navigatorKey.currentContext!,
      type: QuickAlertType.success,
      text: message,
      title: 'نجاح',
    );
  }

  static void showError(BuildContext? context, String message) {
    QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
      context: context ?? NavigatorService.navigatorKey.currentContext!,
      type: QuickAlertType.error,
      text: message,
      title: 'خطأ',
    );
  }

  static void showLoading(BuildContext? context, String message) {
    QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
      context: context ?? NavigatorService.navigatorKey.currentContext!,
      type: QuickAlertType.loading,
      text: message,
      title: 'جاري التحميل',
      disableBackBtn: true,
    );
  }
}
