import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // Web (Chrome/Flutter web) -> localhost
      return 'http://localhost:8000';
    }
    if (Platform.isAndroid) {
      // Android Emulator -> 10.0.2.2 (host loopback)
      // Dispositivo físico -> cambia a tu IP LAN (ej: 192.168.x.x)
      return 'http://10.0.2.2:8000';
    }
    // iOS Simulator / Desktop / Physical device -> localhost
    return 'http://localhost:8000';
  }

  // Auth endpoints
  static String get loginUrl => '$baseUrl/auth/login';
  static String get registerUrl => '$baseUrl/auth/register';
  static String get meUrl => '$baseUrl/auth/me';
  static String get refreshUrl => '$baseUrl/auth/refresh';
  static String get forgotPasswordUrl => '$baseUrl/auth/forgot-password';
  static String get resetPasswordUrl => '$baseUrl/auth/reset-password';

  // Session / inactivity endpoints (CU23)
  static String get sessionUrl => '$baseUrl/auth/session';
  static String get sessionContinueUrl => '$baseUrl/auth/session/continue';
  static String get logoutUrl => '$baseUrl/auth/logout';

  // Inactivity window and warning (CU23). Must match the backend settings
  // (INACTIVITY_TIMEOUT_MINUTES / INACTIVITY_WARNING_SECONDS).
  static const int inactivityTimeoutMinutes = 15;
  static const int inactivityWarningSeconds = 60;

  // Clinical Documents endpoints (CU12)
  static String get documentsUrl => '$baseUrl/api/v1/documentos';
  static String get myDocumentsUrl => '$baseUrl/api/v1/documentos/me';
  static String patientDocumentsUrl(int patientId) => '$baseUrl/api/v1/pacientes/$patientId/documentos';
  static String documentDetailUrl(int id) => '$baseUrl/api/v1/documentos/$id';
  static String documentDownloadUrl(int id) => '$baseUrl/api/v1/documentos/$id/download';
  static String documentFileUrl(String key) => '$baseUrl/api/v1/documentos/file/$key';

  // Request timeout duration
  static const Duration timeoutDuration = Duration(seconds: 15);
  static const Duration downloadTimeoutDuration = Duration(seconds: 60);
}
