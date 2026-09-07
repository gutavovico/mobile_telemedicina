import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // localhost para navegador (Chrome / Edge)
      return 'http://127.0.0.1:8000';
    }
    if (Platform.isAndroid) {
      // 10.0.2.2 points to host machine loopback in Android Emulator
      return 'http://10.0.2.2:8000';
    }
    // iOS simulator / Desktop
    return 'http://127.0.0.1:8000';
  }

  // Auth endpoints
  static String get loginUrl => '$baseUrl/auth/login';
  static String get registerUrl => '$baseUrl/auth/register';
  static String get meUrl => '$baseUrl/auth/me';
  static String get refreshUrl => '$baseUrl/auth/refresh';

  // Citas y Consultas (Appointments)
  static String get appointmentsUrl => '$baseUrl/citas';
  static String get availableSlotsUrl => '$baseUrl/citas/horarios-disponibles';
  static String get doctorsUrl => '$baseUrl/medicos';

  // Request timeout duration
  static const Duration timeoutDuration = Duration(seconds: 15);
}
