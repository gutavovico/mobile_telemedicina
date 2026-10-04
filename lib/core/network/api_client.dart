import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../storage/secure_storage_service.dart';
import 'api_exceptions.dart';
import 'api_client_interface.dart';
import '../config/api_config.dart';

class ApiClient implements ApiClientInterface {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();
  final SecureStorageService _storage = SecureStorageService();

  Future<Map<String, String>> _buildHeaders({bool includeAuth = true, Map<String, String>? extraHeaders}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await _storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      // Add tenant ID if available (for multi-tenant support)
      final tenantId = await _storage.getTenantId();
      if (tenantId != null && tenantId.isNotEmpty) {
        headers['X-Tenant-ID'] = tenantId;
      }
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  @override
  Future<dynamic> get(String url, {bool includeAuth = true, String? authToken}) async {
    try {
      final headers = await _buildHeaders(includeAuth: includeAuth, extraHeaders: authToken != null ? {'Authorization': 'Bearer $authToken'} : null);
      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw TimeoutException();
    } on http.ClientException {
      throw NetworkException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Error de comunicación: ${e.toString()}');
    }
  }

  @override
  Future<dynamic> post(String url, {dynamic body, bool includeAuth = true}) async {
    try {
      final headers = await _buildHeaders(includeAuth: includeAuth);
      final response = await _client
          .post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw TimeoutException();
    } on http.ClientException {
      throw NetworkException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Error de comunicación: ${e.toString()}');
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic decodedBody;
    try {
      if (response.body.isNotEmpty) {
        decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {
      decodedBody = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    }

    final errorMessage = _extractErrorMessage(decodedBody, response.statusCode);

    switch (response.statusCode) {
      case 400:
        throw ApiException(message: errorMessage, statusCode: 400, details: decodedBody);
      case 401:
        throw UnauthorizedException(errorMessage);
      case 422:
        throw ValidationException(errorMessage, details: decodedBody);
      case 500:
      case 502:
      case 503:
        throw ServerException(errorMessage);
      default:
        throw ApiException(
          message: errorMessage,
          statusCode: response.statusCode,
          details: decodedBody,
        );
    }
  }

  String _extractErrorMessage(dynamic body, int statusCode) {
    if (body is Map<String, dynamic>) {
      if (body.containsKey('detail')) {
        final detail = body['detail'];
        if (detail is String) return _translateError(detail, statusCode);
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first.containsKey('msg')) {
            return _translateError(first['msg'].toString(), statusCode);
          }
          return _translateError(detail.toString(), statusCode);
        }
      }
      if (body.containsKey('message')) {
        return _translateError(body['message'].toString(), statusCode);
      }
    }
    return _translateError('Error del servidor (Código $statusCode)', statusCode);
  }

  String _translateError(String message, int statusCode) {
    // Translate common English error messages to Spanish
    final lower = message.toLowerCase();
    
    // FastAPI default messages
    if (lower == 'not authenticated') {
      return 'No autenticado: token inválido o ausente';
    }
    if (lower == 'not authorized') {
      return 'No autorizado';
    }
    if (lower.contains('invalid token') || lower.contains('token invalid')) {
      return 'Token inválido o expirado';
    }
    if (lower.contains('expired')) {
      return 'Sesión expirada';
    }
    if (lower.contains('unauthorized')) {
      return 'No autorizado: credenciales inválidas';
    }
    if (lower.contains('forbidden')) {
      return 'Acceso denegado';
    }
    if (lower.contains('not found')) {
      return 'Recurso no encontrado';
    }
    if (lower.contains('internal server error')) {
      return 'Error interno del servidor';
    }
    if (lower.contains('bad request')) {
      return 'Solicitud inválida';
    }
    
    // Status code fallbacks
    switch (statusCode) {
      case 401:
        return 'Sesión expirada o credenciales inválidas';
      case 403:
        return 'Acceso denegado: no tiene permisos para este recurso';
      case 404:
        return 'Recurso no encontrado';
      case 422:
        return 'Datos de entrada inválidos';
      case 500:
      case 502:
      case 503:
        return 'Error del servidor. Intente más tarde';
      default:
        return message;
    }
  }

  @override
  Future<Uint8List> downloadBytes(String url, {bool includeAuth = true}) async {
    try {
      final headers = await _buildHeaders(includeAuth: includeAuth);
      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.downloadTimeoutDuration);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }

      final errorMessage = _extractErrorMessage(response.body, response.statusCode);
      throw ApiException(message: errorMessage, statusCode: response.statusCode);
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw TimeoutException();
    } on http.ClientException {
      throw NetworkException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Error de comunicación: ${e.toString()}');
    }
  }
}
