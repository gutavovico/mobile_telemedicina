import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.endsWith('/')
          ? _configuredBaseUrl.substring(0, _configuredBaseUrl.length - 1)
          : _configuredBaseUrl;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    if (Platform.isAndroid) {
      // 10.0.2.2 points to host machine loopback in Android Emulator
      return 'http://10.0.2.2:8000';
    }
    // iOS simulator and desktop. For a physical device, pass the host LAN URL:
    // flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
    return 'http://127.0.0.1:8000';
  }

  // Auth endpoints
  static String get loginUrl => '$baseUrl/auth/login';
  static String get registerUrl => '$baseUrl/auth/register';
  static String get meUrl => '$baseUrl/auth/me';
  static String get refreshUrl => '$baseUrl/auth/refresh';
  static String get forgotPasswordUrl => '$baseUrl/auth/forgot-password';
  static String get resetPasswordUrl => '$baseUrl/auth/reset-password';

  // Pacientes endpoints (CU03)
  static String get patientsUrl => '$baseUrl/api/v1/pacientes';
  static String get myPatientProfileUrl => '$baseUrl/api/v1/pacientes/me';

  // Médicos y Especialidades endpoints (CU04)
  static String get doctorsUrl => '$baseUrl/api/v1/medicos';
  static String get specialtiesUrl => '$baseUrl/api/v1/especialidades';

  // Citas y Consultas (Appointments - CU25)
  static String get appointmentsUrl => '$baseUrl/citas';
  static String get availableSlotsUrl => '$baseUrl/citas/horarios-disponibles';

  // Fichas Clínicas (Medical Records - CU09)
  static String get fichasUrl => '$baseUrl/medical-records/fichas';

  // Documentos Clínicos (Medical Records - CU12)
  static String get myDocumentsUrl => '$baseUrl/api/v1/documentos/me';
  static String documentDetailUrl(int id) => '$baseUrl/api/v1/documentos/$id';
  static String documentDownloadUrl(int id) =>
      '$baseUrl/api/v1/documentos/$id/download';

  // Recetas Médicas Digitales (Medical Records - CU16, solo lectura paciente)
  static String get prescriptionsUrl => '$baseUrl/api/v1/recetas';
  static String prescriptionDetailUrl(int id) => '$baseUrl/api/v1/recetas/$id';
  static String prescriptionPdfUrl(int id) => '$baseUrl/api/v1/recetas/$id/pdf';

  // Request timeout duration
  static const Duration timeoutDuration = Duration(seconds: 15);
}
