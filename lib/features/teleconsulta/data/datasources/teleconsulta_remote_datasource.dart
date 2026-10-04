import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/chat_message_model.dart';
import '../models/teleconsulta_model.dart';

class TeleconsultaRemoteDataSource {
  final ApiClient _apiClient = ApiClient();

  Future<TeleconsultaViewModel> getTeleconsulta(int idCita) async {
    final response = await _apiClient.get(ApiConfig.teleconsultaUrl(idCita));
    if (response is Map<String, dynamic>) {
      return TeleconsultaViewModel.fromJson(response);
    }
    throw Exception('Formato de respuesta inválido al cargar teleconsulta');
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
    final body = <String, dynamic>{
      'idCita': idCita,
      'contenido': contenido,
    };
    if (adjuntoNombre != null) body['adjuntoNombre'] = adjuntoNombre;
    if (adjuntoTamano != null) body['adjuntoTamano'] = adjuntoTamano;
    if (adjuntoUrl != null) body['adjuntoUrl'] = adjuntoUrl;

    final response = await _apiClient.post(
      ApiConfig.chatMensajesUrl(idCita),
      body: body,
    );

    if (response is Map<String, dynamic>) {
      return ChatMessageModel.fromJson(response);
    }
    throw Exception('Respuesta inesperada al enviar mensaje');
  }
}
