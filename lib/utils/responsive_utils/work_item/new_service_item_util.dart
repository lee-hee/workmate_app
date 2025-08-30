import 'package:flutter/material.dart';

class ResponsiveNewServiceItemUtils {
  static bool isWideScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  static double getMaxWidth(BuildContext context) {
    return ResponsiveNewServiceItemUtils.isWideScreen(context)
        ? 500.0 // web
        : double.infinity; // mobile
  }

  static Alignment getAlignment(BuildContext context) {
    return ResponsiveNewServiceItemUtils.isWideScreen(context)
        ? Alignment.center // Center on web
        : Alignment.topLeft; // mobile
  }
}
