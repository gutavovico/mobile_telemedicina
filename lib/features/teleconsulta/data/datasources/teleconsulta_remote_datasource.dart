import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/chat_message_model.dart';
import '../models/teleconsulta_model.dart';

class TeleconsultaRemoteDataSource {
  final ApiClient _apiClient = ApiClient();

  static String? _resolvedBaseUrl;

  static final List<String> _candidateBaseUrls = [
    ApiConfig.baseUrl,
    'http://192.168.101.70:8000',
    'http://192.168.101.70:4200/backend-api',
    'http://10.0.2.2:8000',
    'http://localhost:8000',
    'http://127.0.0.1:8000',
  ];

  static List<String> get _orderedBaseUrls {
    if (_resolvedBaseUrl != null) {
      return [
        _resolvedBaseUrl!,
        ..._candidateBaseUrls.where((u) => u != _resolvedBaseUrl),
      ];
    }
    return _candidateBaseUrls;
  }

  Future<TeleconsultaViewModel> getTeleconsulta(int idCita) async {
    TeleconsultaViewModel? vm;
    try {
      final response = await _apiClient.get(ApiConfig.teleconsultaUrl(idCita));
      if (response is Map<String, dynamic>) {
        vm = TeleconsultaViewModel.fromJson(response);
      }
    } catch (_) {}

    final realtimeMsgs = await obtenerMensajesRealtime(idCita);
    final convertidos = <ChatMessageModel>[];
    for (final rm in realtimeMsgs) {
      final texto = (rm['texto'] ?? '').toString();
      final archNombre = rm['archivoNombre']?.toString();
      if (texto.isEmpty && (archNombre == null || archNombre.isEmpty)) continue;
      final esDoc = rm['esDoctor'] == true;
      convertidos.add(
        ChatMessageModel(
          idMensaje: rm['id'].hashCode.abs(),
          idRemitente: esDoc ? 42 : 10,
          nombreRemitente: (rm['remitente'] ?? (esDoc ? 'Doctor' : 'Paciente')).toString(),
          rolRemitente: esDoc ? 'MEDICO' : 'PACIENTE',
          contenido: texto,
          horaDisplay: '${rm['hora'] ?? 'Ahora'} h',
          esPropio: !esDoc,
          leido: true,
          adjuntoNombre: archNombre,
          adjuntoTamano: rm['archivoTamano']?.toString(),
          adjuntoUrl: rm['archivoUrl']?.toString(),
        ),
      );
    }

    if (vm != null) {
      if (convertidos.isNotEmpty) {
        final existentes = List<ChatMessageModel>.from(vm.mensajes);
        for (final cm in convertidos) {
          final yaEsta = existentes.any(
            (m) => m.contenido == cm.contenido && m.adjuntoNombre == cm.adjuntoNombre,
          );
          if (!yaEsta) {
            existentes.add(cm);
          }
        }
        return TeleconsultaViewModel(
          nombreClinica: vm.nombreClinica,
          usuarioActivo: vm.usuarioActivo,
          paciente: vm.paciente,
          cita: vm.cita,
          medico: vm.medico,
          mensajes: existentes,
        );
      }
      return vm;
    }

    // Fallback local si el endpoint principal requirió sesión remota pero el canal realtime local respondió
    return TeleconsultaViewModel(
      nombreClinica: 'Clínica Norte',
      usuarioActivo: const {
        'idUsuario': 10,
        'nombre': 'Paciente',
        'iniciales': 'PA',
      },
      paciente: const PatientSummaryModel(
        idPaciente: 10,
        nombreCompleto: 'Paciente',
        identificacionId: 'N/A',
        inicialesAvatar: 'PA',
        seguroProveedor: 'Seguro Médico',
        seguroPoliza: 'POL-001',
      ),
      cita: AppointmentDetailsModel(
        idCita: idCita,
        nombreMedico: 'Dr. Roberto Gómez Flores',
        especialidad: 'Cardiología',
        rangoFechas: 'Hoy',
        horaTeleconsulta: '10:30 h',
        modalidad: 'TELEMEDICINA',
        estado: 'EN_CURSO',
      ),
      medico: const DoctorProfileSummaryModel(
        idMedico: 42,
        nombreCompleto: 'Dr. Roberto Gómez Flores',
        cargoEtiqueta: 'Médico Especialista',
        biografia: 'Especialista en atención médica por teleconsulta.',
        estadoDisponibilidad: 'DISPONIBLE',
      ),
      mensajes: convertidos,
    );
  }

  Future<TeleconsultaViewModel> getMiTeleconsultaActiva() async {
    final response = await _apiClient.get(ApiConfig.myTeleconsultaUrl);
    if (response is Map<String, dynamic>) {
      return TeleconsultaViewModel.fromJson(response);
    }
    throw Exception('Formato de respuesta inválido al cargar teleconsulta activa');
  }

  Future<ChatMessageModel> enviarMensaje({
    required int idCita,
    required String contenido,
    String? adjuntoNombre,
    String? adjuntoTamano,
    String? adjuntoUrl,
  }) async {
    final now = DateTime.now();
    final horaCorta = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final ext = adjuntoNombre != null && adjuntoNombre.contains('.')
        ? adjuntoNombre.split('.').last.toUpperCase()
        : 'PDF';

    // 1. Enviar al canal en tiempo real incluyendo archivoUrl (base64) para que el médico web lo vea y descargue
    await enviarMensajeRealtime(
      idCita: idCita,
      remitente: 'Paciente (Móvil)',
      texto: contenido,
      hora: horaCorta,
      archivoNombre: adjuntoNombre,
      archivoTamano: adjuntoTamano,
      archivoTipo: ext,
      archivoUrl: adjuntoUrl,
    );

    // 2. Persistir en el endpoint estándar CU15 si está disponible
    final body = <String, dynamic>{
      'idCita': idCita,
      'contenido': contenido,
      'adjuntoNombre': ?adjuntoNombre,
      'adjuntoTamano': ?adjuntoTamano,
      'adjuntoUrl': ?adjuntoUrl,
    };

    try {
      final response = await _apiClient.post(
        ApiConfig.chatMensajesUrl(idCita),
        body: body,
      );

      if (response is Map<String, dynamic>) {
        return ChatMessageModel.fromJson(response);
      }
    } catch (_) {}

    return ChatMessageModel(
      idMensaje: now.millisecondsSinceEpoch,
      idRemitente: 10,
      nombreRemitente: 'Paciente',
      rolRemitente: 'PACIENTE',
      contenido: contenido,
      horaDisplay: '$horaCorta h',
      esPropio: true,
      leido: true,
      adjuntoNombre: adjuntoNombre,
      adjuntoTamano: adjuntoTamano,
      adjuntoUrl: adjuntoUrl,
    );
  }

  static Future<Map<String, dynamic>?> reportarPresencia({
    required int idCita,
    required String rol,
    required bool conectado,
    String? nombre,
  }) async {
    for (final base in _orderedBaseUrls) {
      try {
        final res = await http
            .post(
              Uri.parse('$base/citas/$idCita/presencia'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'rol': rol,
                'conectado': conectado,
                'nombre': ?nombre,
              }),
            )
            .timeout(const Duration(milliseconds: 1500));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          _resolvedBaseUrl = base;
          return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> obtenerMensajesRealtime(int idCita) async {
    for (final base in _orderedBaseUrls) {
      try {
        final res = await http
            .get(Uri.parse('$base/citas/$idCita/chat/realtime'))
            .timeout(const Duration(milliseconds: 1500));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          _resolvedBaseUrl = base;
          final decoded = jsonDecode(utf8.decode(res.bodyBytes));
          if (decoded is List) {
            return decoded.whereType<Map<String, dynamic>>().toList();
          }
        }
      } catch (_) {}
    }
    return [];
  }

  static Future<void> enviarMensajeRealtime({
    required int idCita,
    required String remitente,
    required String texto,
    required String hora,
    String? archivoNombre,
    String? archivoTamano,
    String? archivoTipo,
    String? archivoUrl,
  }) async {
    final payload = {
      'id': 'msg-movil-${DateTime.now().millisecondsSinceEpoch}',
      'remitente': remitente,
      'hora': hora,
      'esDoctor': false,
      'esSistema': false,
      'texto': texto,
      'archivoNombre': ?archivoNombre,
      'archivoTamano': ?archivoTamano,
      'archivoTipo': archivoTipo ?? 'PDF',
      'archivoUrl': ?archivoUrl,
    };
    for (final base in _orderedBaseUrls) {
      try {
        final res = await http
            .post(
              Uri.parse('$base/citas/$idCita/chat/realtime'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(milliseconds: 1500));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          _resolvedBaseUrl = base;
          return;
        }
      } catch (_) {}
    }
  }

  static Future<void> enviarSenalWebrtc({
    required int idCita,
    required String de,
    required String para,
    required String tipo,
    Map<String, dynamic>? data,
  }) async {
    for (final base in _orderedBaseUrls) {
      try {
        final res = await http
            .post(
              Uri.parse('$base/citas/$idCita/webrtc/signal'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'de': de,
                'para': para,
                'tipo': tipo,
                'data': data ?? {},
              }),
            )
            .timeout(const Duration(milliseconds: 1500));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          _resolvedBaseUrl = base;
          return;
        }
      } catch (_) {}
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerSenalesWebrtc({
    required int idCita,
    required String para,
  }) async {
    for (final base in _orderedBaseUrls) {
      try {
        final res = await http
            .get(Uri.parse('$base/citas/$idCita/webrtc/signal?para=$para'))
            .timeout(const Duration(milliseconds: 1500));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          _resolvedBaseUrl = base;
          final decoded = jsonDecode(utf8.decode(res.bodyBytes));
          if (decoded is List) {
            return decoded.whereType<Map<String, dynamic>>().toList();
          }
        }
      } catch (_) {}
    }
    return [];
  }
}
