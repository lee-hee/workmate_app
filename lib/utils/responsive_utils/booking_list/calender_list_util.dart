import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveBookingListUtils {
  static bool isWideScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  static double getCalendarWidthRatio(BuildContext context) {
    return 0.6; // 60% width for calendar
  }

  static double getTaskListWidthRatio(BuildContext context) {
    return 0.4; // 40% width for task list
  }

  static EdgeInsets getSectionPadding(BuildContext context) {
    return const EdgeInsets.all(16);
  }

  // Calendar Header
  static EdgeInsets getHeaderPadding(BuildContext context) {
    return kIsWeb
        ? const EdgeInsets.symmetric(vertical: 4.0)
        : const EdgeInsets.symmetric(vertical: 8.0);
  }

  // Booking description
  static EdgeInsets getDescriptionPadding(BuildContext context) {
    return ResponsiveBookingListUtils.isWideScreen(context)
        ? const EdgeInsets.all(8.0) // web
        : const EdgeInsets.all(12.0); // mobile
  }

  static double getItemHeight(BuildContext context) {
    return ResponsiveBookingListUtils.isWideScreen(context)
        ? 120.0 // web
        : 100.0; // mobile
  }
}
