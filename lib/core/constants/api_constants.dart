import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    try {
      if (Platform.isAndroid) {
        // 10.0.2.2 is the special alias to host localhost in Android emulator
        return 'http://10.0.2.2:3000';
      }
    } catch (_) {}
    return 'http://localhost:3000';
  }

  static String get wsUrl {
    if (kIsWeb) {
      return 'ws://localhost:3000';
    }
    try {
      if (Platform.isAndroid) {
        return 'ws://10.0.2.2:3000';
      }
    } catch (_) {}
    return 'ws://localhost:3000';
  }
}
