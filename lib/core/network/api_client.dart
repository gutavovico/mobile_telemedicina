import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../storage/secure_storage_service.dart';
import 'api_exceptions.dart';
import '../config/api_config.dart';

class ApiClient {
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
    }

    final tenantId = await _storage.getTenantId();
    if (tenantId != null && tenantId.isNotEmpty) {
      headers['X-Tenant-ID'] = tenantId;
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  Future<dynamic> get(String url, {bool includeAuth = true}) async {
    try {
      final headers = await _buildHeaders(includeAuth: includeAuth);
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

  Future<dynamic> patch(String url, {dynamic body, bool includeAuth = true}) async {
    try {
      final headers = await _buildHeaders(includeAuth: includeAuth);
      final response = await _client
          .patch(
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

  Future<dynamic> put(String url, {dynamic body, bool includeAuth = true}) async {
    try {
      final headers = await _buildHeaders(includeAuth: includeAuth);
      final response = await _client
          .put(
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
      case 403:
        throw ForbiddenException(errorMessage);
      case 404:
        throw NotFoundException(errorMessage);
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
        if (detail is String) return detail;
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first.containsKey('msg')) {
            return first['msg'].toString();
          }
          return detail.toString();
        }
      }
      if (body.containsKey('message')) {
        return body['message'].toString();
      }
    }
    return 'Error del servidor (Código $statusCode)';
  }
}
