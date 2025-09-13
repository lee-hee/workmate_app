import 'package:flutter/material.dart';
import 'package:animated_snack_bar/animated_snack_bar.dart';

class CustomSnackBar {
  /// Default error snackbar (backward compatible with your existing usage)
  static void showMessageSnackBar(BuildContext context, String message) {
    AnimatedSnackBar.material(
      message,
      type: AnimatedSnackBarType.error,
      mobileSnackBarPosition: MobileSnackBarPosition.top,
      desktopSnackBarPosition: DesktopSnackBarPosition.topCenter,
      duration: const Duration(seconds: 4),
    ).show(context);
  }

  /// Success snackbar
  static void showSuccess(BuildContext context, String message) {
    AnimatedSnackBar.material(
      message,
      type: AnimatedSnackBarType.success,
      mobileSnackBarPosition: MobileSnackBarPosition.top,
      desktopSnackBarPosition: DesktopSnackBarPosition.topCenter,
      duration: const Duration(seconds: 3),
    ).show(context);
  }

  /// Info snackbar
  static void showInfo(BuildContext context, String message) {
    AnimatedSnackBar.material(
      message,
      type: AnimatedSnackBarType.info,
      mobileSnackBarPosition: MobileSnackBarPosition.top,
      desktopSnackBarPosition: DesktopSnackBarPosition.topCenter,
      duration: const Duration(seconds: 3),
    ).show(context);
  }

  /// Warning snackbar
  static void showWarning(BuildContext context, String message) {
    AnimatedSnackBar.material(
      message,
      type: AnimatedSnackBarType.warning,
      mobileSnackBarPosition: MobileSnackBarPosition.top,
      desktopSnackBarPosition: DesktopSnackBarPosition.topCenter,
      duration: const Duration(seconds: 3),
    ).show(context);
  }
}
