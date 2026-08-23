import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // 127.0.0.1 Web
      return 'http://192.168.100.30:8000';
    }
    if (Platform.isAndroid) {
      // 10.0.2.2 points to host machine loopback in Android Emulator
      return 'http://192.168.100.30:8000';
    }
    // 127.0.0.1 iOS simulator / Desktop / Physical device (can be changed to LAN IP)
    return 'http://192.168.100.30:8000';
  }

  // Auth endpoints
  static String get loginUrl => '$baseUrl/auth/login';
  static String get registerUrl => '$baseUrl/auth/register';
  static String get meUrl => '$baseUrl/auth/me';
  static String get refreshUrl => '$baseUrl/auth/refresh';

  // Request timeout duration
  static const Duration timeoutDuration = Duration(seconds: 15);
}
