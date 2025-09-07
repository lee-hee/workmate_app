import 'package:flutter/material.dart';

class ResponsiveJournalUtils {
  static bool isWideScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  static EdgeInsets getPagePadding(BuildContext context) {
    return isWideScreen(context)
        ? const EdgeInsets.symmetric(horizontal: 80.0, vertical: 20.0)
        : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0);
  }

  static double getFieldSpacing(BuildContext context) {
    return isWideScreen(context) ? 24.0 : 12.0;
  }

  static double getTextFieldHeight(BuildContext context) {
    return isWideScreen(context) ? 80.0 : 60.0;
  }

  static double getImageHeight(BuildContext context) {
    return isWideScreen(context) ? 200.0 : 150.0;
  }

  static double getMaxWidth(BuildContext context) {
    return isWideScreen(context) ? 800.0 : double.infinity;
  }

  static Alignment getAlignment(BuildContext context) {
    return isWideScreen(context) ? Alignment.center : Alignment.topLeft;
  }
}
