import 'package:flutter/material.dart';
import '../../data/models/patient_model.dart';
import '../../data/services/patient_service.dart';
import '../../../../core/network/api_exceptions.dart';

class PatientProvider extends ChangeNotifier {
  final PatientService _patientService = PatientService();

  PatientModel? _currentPatient;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  PatientModel? get currentPatient => _currentPatient;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Carga el perfil del paciente desde el backend
  Future<void> fetchPatientProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentPatient = await _patientService.getMyPatientProfile();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error inesperado al cargar el perfil del paciente.';
      notifyListeners();
    }
  }

  /// Actualiza los datos de contacto y emergencia del paciente
  Future<bool> updatePatientProfile({
    required String telefono,
    String? correo,
    String? direccion,
    String? ciudad,
    String? contactoEmergenciaNombre,
    String? contactoEmergenciaTelefono,
    String? contactoEmergenciaParentesco,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final Map<String, dynamic> patchData = {
      'telefono': telefono.trim(),
    };

    if (correo != null && correo.trim().isNotEmpty) {
      patchData['correo'] = correo.trim();
    }
    if (direccion != null && direccion.trim().isNotEmpty) {
      patchData['direccion'] = direccion.trim();
    }
    if (ciudad != null && ciudad.trim().isNotEmpty) {
      patchData['ciudad'] = ciudad.trim();
    }
    if (contactoEmergenciaNombre != null && contactoEmergenciaNombre.trim().isNotEmpty) {
      patchData['contacto_emergencia_nombre'] = contactoEmergenciaNombre.trim();
    }
    if (contactoEmergenciaTelefono != null && contactoEmergenciaTelefono.trim().isNotEmpty) {
      patchData['contacto_emergencia_telefono'] = contactoEmergenciaTelefono.trim();
    }
    if (contactoEmergenciaParentesco != null && contactoEmergenciaParentesco.trim().isNotEmpty) {
      patchData['contacto_emergencia_parentesco'] = contactoEmergenciaParentesco.trim();
    }

    try {
      _currentPatient = await _patientService.updateMyPatientProfile(patchData);
      _isLoading = false;
      _successMessage = 'Datos de contacto y emergencia actualizados con éxito.';
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al actualizar los datos.';
      notifyListeners();
      return false;
    }
  }
}
