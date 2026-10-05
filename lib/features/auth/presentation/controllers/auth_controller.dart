import 'package:flutter/foundation.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/auth_models.dart';

class AuthController extends ChangeNotifier {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _storageService;

  AuthController({
    AuthRemoteDataSource? remoteDataSource,
    SecureStorageService? storageService,
  }) : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource(),
       _storageService = storageService ?? SecureStorageService();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isCheckingAuth = true;
  String? _errorMessage;
  String? _successMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isCheckingAuth => _isCheckingAuth;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isPatient => _currentUser?.isPatient ?? false;

  Future<void> _saveTenantFromProfile(UserModel user) async {
    final tenantId = user.tenantId;
    if (tenantId != null && tenantId.isNotEmpty) {
      await _storageService.saveTenantId(tenantId);
    } else {
      await _storageService.clearTenantId();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setSuccessMessage(String msg) {
    _successMessage = msg;
    _errorMessage = null;
    notifyListeners();
  }

  void setErrorMessage(String msg) {
    _errorMessage = msg;
    _successMessage = null;
    notifyListeners();
  }

  // Check saved session on app launch
  Future<bool> checkAuthStatus() async {
    _isCheckingAuth = true;
    notifyListeners();

    try {
      final token = await _storageService.getAccessToken();
      if (token == null || token.isEmpty) {
        ApiClient().clearSessionAccessToken();
        _currentUser = null;
        _isCheckingAuth = false;
        notifyListeners();
        return false;
      }

      // A cached role is never sufficient to open patient-only routes.
      ApiClient().setSessionAccessToken(token);
      final user = await _remoteDataSource.getMe();
      await _saveTenantFromProfile(user);
      await _storageService.saveUser(user.toJson());
      _currentUser = user;

      _isCheckingAuth = false;
      notifyListeners();
      return _currentUser != null;
    } catch (_) {
      ApiClient().clearSessionAccessToken();
      _currentUser = null;
      _isCheckingAuth = false;
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login(
    String correo,
    String password, {
    bool rememberMe = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    var tokenIssued = false;
    try {
      final request = LoginRequest(correo: correo, password: password);
      final tokenResponse = await _remoteDataSource.login(request);
      if (tokenResponse.accessToken.isEmpty) {
        throw const FormatException(
          'El backend no devolvió un token de acceso',
        );
      }
      tokenIssued = true;
      await _storageService.clearSession();
      ApiClient().setSessionAccessToken(tokenResponse.accessToken);

      if (rememberMe) {
        await _storageService.saveTokens(
          accessToken: tokenResponse.accessToken,
          refreshToken: tokenResponse.refreshToken,
        );
      }
      await _storageService.setRememberMe(rememberMe);

      // Fetch user details
      final user = await _remoteDataSource.getMe();
      await _saveTenantFromProfile(user);
      _currentUser = user;
      if (rememberMe) {
        await _storageService.saveUser(user.toJson());
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      if (tokenIssued) {
        ApiClient().clearSessionAccessToken();
        await _storageService.clearSession();
      }
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      if (tokenIssued) {
        ApiClient().clearSessionAccessToken();
        await _storageService.clearSession();
      }
      _errorMessage = 'Ocurrió un error inesperado al iniciar sesión.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String nombres,
    required String apellidos,
    required String correo,
    required String password,
    String? telefono,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final request = RegisterRequest(
        nombres: nombres,
        apellidos: apellidos,
        correo: correo,
        password: password,
        telefono: telefono,
      );

      await _remoteDataSource.register(request);

      _isLoading = false;
      _successMessage =
          '¡Cuenta creada con éxito! Por favor inicia sesión para continuar.';
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Ocurrió un error inesperado al registrar el usuario.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Forgot Password
  Future<bool> forgotPassword(String correo) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final request = ForgotPasswordRequest(correo: correo);
      final response = await _remoteDataSource.forgotPassword(request);

      _isLoading = false;
      final detail = response.detail;
      if (response.debugCode != null) {
        _successMessage = '$detail (Código dev: ${response.debugCode})';
      } else {
        _successMessage = detail;
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Ocurrió un error inesperado al solicitar el código.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset Password
  Future<bool> resetPassword(
    String correo,
    String codigo,
    String nuevaPassword,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final request = ResetPasswordRequest(
        correo: correo,
        codigo: codigo,
        nuevaPassword: nuevaPassword,
      );
      await _remoteDataSource.resetPassword(request);

      _isLoading = false;
      _successMessage =
          'Contraseña restablecida exitosamente. Por favor inicia sesión.';
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage =
          'Ocurrió un error inesperado al restablecer la contraseña.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // Best-effort remote token invalidation
    }
    ApiClient().clearSessionAccessToken();
    await _storageService.clearSession();
    _currentUser = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
