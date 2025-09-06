// lib/config/backend_config.dart

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class BackendConfig {
  // Set this per developer
  // Android emulator: 10.0.2.2
  // Web / Mac / iOS simulator: localhost
  static const int port = 8080;

  static String get host {
    if (kIsWeb) {
      return "localhost"; // For Chrome (Flutter Web)
    } else if (Platform.isAndroid) {
      return "10.0.2.2"; // For Android Emulator
    } else if (Platform.isIOS || Platform.isMacOS) {
      return "localhost"; // iOS simulator or macOS
    } else {
      return "localhost"; // Windows/Linux desktop
    }
  }

  // Helper to build Uri for a path
  static Uri getUri(String path, [Map<String, String>? queryParams]) {
    return Uri.http("$host:$port", path, queryParams);
  }
}
