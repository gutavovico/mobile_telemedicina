import 'dart:typed_data';

/// Contrato mínimo del cliente HTTP usado por los servicios de datos (CU12).
/// Permite inyectar fakes en pruebas unitarias.
abstract class ApiClientInterface {
  Future<dynamic> get(String url, {bool includeAuth = true, String? authToken});

  Future<Uint8List> downloadBytes(String url, {bool includeAuth = true});
}