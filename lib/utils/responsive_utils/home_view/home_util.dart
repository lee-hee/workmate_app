import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveHomeUtils {
  static EdgeInsets getGridPadding(BuildContext context) {
    // Center content and reduce margins for web
    if (kIsWeb) {
      return const EdgeInsets.fromLTRB(
          96, 12, 96, 24); // Asymmetric padding for web
    } else {
      return const EdgeInsets.all(24); // mobile
    }
  }

  static double getGridCrossAxisCount(BuildContext context) {
    // Fixed 2x2 grid for both mobile and web
    return 2;
  }

  static double getGridChildAspectRatio(BuildContext context) {
    // Smaller grid boxes for web
    if (kIsWeb) {
      return 5 / 2; // web
    } else {
      return 3 / 2; // mobile
    }
  }

  static double getGridSpacing(BuildContext context) {
    // Reduce spacing between grid items for web
    if (kIsWeb) {
      return 30.0; // web
    } else {
      return 20.0; // mobile
    }
  }
}
