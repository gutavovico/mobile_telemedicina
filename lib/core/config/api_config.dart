import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiConfig {
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    if (kIsWeb) {
      // Backend local para desarrollo Web (Edge / Chrome)
      return 'http://127.0.0.1:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 points to host machine loopback in Android Emulator
      return 'https://backend-telemedicina.onrender.com';
    }
    // 127.0.0.1 iOS simulator / Desktop / Physical device (can be changed to LAN IP)
    return 'https://backend-telemedicina.onrender.com';
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
  static String documentDownloadUrl(int id) => '$baseUrl/api/v1/documentos/$id/download';

  // Teleconsulta y Chat de Cita Médica (CU15)
  static String teleconsultaUrl(int idCita) => '$baseUrl/api/v1/citas/$idCita/teleconsulta';
  static String get myTeleconsultaUrl => '$baseUrl/api/v1/citas/me/teleconsulta';
  static String chatMensajesUrl(int idCita) => '$baseUrl/api/v1/citas/$idCita/chat/mensajes';

  // CU22/CU27 reportes; el backend resuelve id_clinica desde la sesión.
  static String get reportCatalogUrl => '$baseUrl/analytics/reportes/catalogo';
  static String get reportOptionsUrl => '$baseUrl/analytics/reportes/opciones';
  static String get reportQueryUrl => '$baseUrl/analytics/reportes/consulta';
  static String get reportExportUrl => '$baseUrl/analytics/reportes/exportar';
  static String get reportInterpretUrl => '$baseUrl/analytics/reportes/interpretar';
  static String get reportTranscribeUrl => '$baseUrl/analytics/reportes/transcribir';
  // Fila virtual y tiempos de espera (CU08)
  static String get liveQueueUrl => '$baseUrl/api/v1/cola';
  static String get miTurnoUrl => '$baseUrl/api/v1/cola/mi-turno';
  static String avanzarColaUrl(int idCita) => '$baseUrl/api/v1/cola/$idCita/avanzar';
  static String perdidaColaUrl(int idCita) => '$baseUrl/api/v1/cola/$idCita/perdida';
  static String get pausasColaUrl => '$baseUrl/api/v1/cola/pausas';

  // Request timeout duration
  static const Duration timeoutDuration = Duration(seconds: 15);
  static const Duration reportExportTimeoutDuration = Duration(seconds: 60);
  static const Duration reportTranscriptionTimeoutDuration = Duration(seconds: 60);
}
