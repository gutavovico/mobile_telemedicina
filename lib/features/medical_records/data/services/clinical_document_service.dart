import 'dart:typed_data';
import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_client_interface.dart';
import '../models/clinical_document_model.dart';

class ClinicalDocumentService {
  final ApiClientInterface _apiClient;

  ClinicalDocumentService({ApiClientInterface? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Consulta `GET /api/v1/documentos/me` (solo documentos del paciente autenticado)
  Future<DocumentoPaginadoModel> getMyDocuments({
    int page = 1,
    int pageSize = 20,
    String? tipoDocumento,
    String? q,
  }) async {
    final Map<String, String> query = {'page': '$page', 'page_size': '$pageSize'};
    if (tipoDocumento != null && tipoDocumento.isNotEmpty) query['tipo_documento'] = tipoDocumento;
    if (q != null && q.trim().isNotEmpty) query['q'] = q.trim();
    final queryString = Uri(queryParameters: query).query;

    final response = await _apiClient.get('${ApiConfig.myDocumentsUrl}?$queryString');
    return DocumentoPaginadoModel.fromJson(response as Map<String, dynamic>);
  }

  /// Consulta `GET /api/v1/documentos/{id}` con el detalle completo
  Future<ClinicalDocumentModel> getDocumentById(int idDocumento) async {
    final response = await _apiClient.get(ApiConfig.documentDetailUrl(idDocumento));
    return ClinicalDocumentModel.fromJson(response as Map<String, dynamic>);
  }

  /// Genera la URL firmada temporal vía `GET /api/v1/documentos/{id}/download`
  Future<DocumentoDownloadModel> requestDownloadUrl(int idDocumento) async {
    final response = await _apiClient.get(ApiConfig.documentDownloadUrl(idDocumento));
    return DocumentoDownloadModel.fromJson(response as Map<String, dynamic>);
  }

  /// Descarga el contenido binario del documento (archivo local del tenant o URL firmada)
  Future<Uint8List> downloadDocumentBytes(int idDocumento) async {
    final download = await requestDownloadUrl(idDocumento);
    if (download.urlFirmada.isEmpty) {
      throw StateError('El servidor no devolvió una URL de descarga válida.');
    }
    return _apiClient.downloadBytes(download.urlFirmada);
  }
}