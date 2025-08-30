import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveFormUtils {
  static double getMaxFormWidth(BuildContext context) {
    if (kIsWeb) {
      return 800; // web
    } else {
      return double.infinity; // Full width on mobile
    }
  }

  // Padding for form content
  static EdgeInsets getFormPadding(BuildContext context) {
    if (kIsWeb) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    } else {
      return const EdgeInsets.all(0);
    }
  }

  // Spacing between form fields
  static double getFieldSpacing(BuildContext context) {
    if (kIsWeb) return 12;
    return 12;
  }
}
