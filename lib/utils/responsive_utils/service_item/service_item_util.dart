import 'package:flutter/material.dart';

class ResponsiveServiceItemScreenUtils {
  static bool isWideScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  static double getMaxWidth(BuildContext context) {
    return ResponsiveServiceItemScreenUtils.isWideScreen(context)
        ? 800.0 // web
        : double.infinity; // mobile
  }

  static Alignment getAlignment(BuildContext context) {
    return ResponsiveServiceItemScreenUtils.isWideScreen(context)
        ? Alignment.center // Center on web
        : Alignment.topLeft; // mobile
  }
}
