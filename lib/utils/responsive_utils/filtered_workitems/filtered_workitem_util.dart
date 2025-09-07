import 'package:flutter/material.dart';

class FilteredWorkItemUtils {
  static bool isWideScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  static double getMaxWidth(BuildContext context) {
    return FilteredWorkItemUtils.isWideScreen(context)
        ? 800.0 // web
        : double.infinity; // Full width for mobile
  }

  static Alignment getAlignment(BuildContext context) {
    return FilteredWorkItemUtils.isWideScreen(context)
        ? Alignment.topCenter // web
        : Alignment.topLeft; // mobile
  }
}
