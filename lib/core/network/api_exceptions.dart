class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException({
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException([String message = 'No se pudo conectar con el servidor. Verifica tu conexión a internet.'])
      : super(message: message, statusCode: null);
}

class TimeoutException extends ApiException {
  TimeoutException([String message = 'Tiempo de espera agotado. El servidor tardó demasiado en responder.'])
      : super(message: message, statusCode: 408);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = 'Sesión expirada o credenciales inválidas.'])
      : super(message: message, statusCode: 401);
}

class ValidationException extends ApiException {
  ValidationException(String message, {super.details})
      : super(message: message, statusCode: 422);
}

class ServerException extends ApiException {
  ServerException([String message = 'Error interno en el servidor. Por favor intenta más tarde.'])
      : super(message: message, statusCode: 500);
}
