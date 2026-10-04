import 'package:flutter/foundation.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/auth_models.dart';
import '../../domain/services/inactivity_service.dart';

class AuthController extends ChangeNotifier {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _storageService;
  final InactivityService _inactivityService;

  AuthController({
    AuthRemoteDataSource? remoteDataSource,
    SecureStorageService? storageService,
    InactivityService? inactivityService,
  })  : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource(),
        _storageService = storageService ?? SecureStorageService(),
        _inactivityService = inactivityService ??
            InactivityService(
              remoteDataSource: remoteDataSource,
              storageService: storageService,
            );

  /// Devuelve el `refresh_token` vigente para poder notificar el cierre al
  /// backend (CU24) antes de borrar el almacenamiento local.
  ///
  /// Se resuelve en cada llamada, y no al construir el servicio, para no
  /// retener el token en memoria mas tiempo del necesario.
  Future<String?> _pendingLogoutToken() async {
    try {
      return await _storageService.getRefreshToken();
    } catch (_) {
      return null;
    }
  }

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
  
  /// Retorna el nombre del rol del usuario actual (ej: 'paciente', 'medico', 'admin', 'recepcion')
  String? get userRole => _currentUser?.rolNombre?.toLowerCase();

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
        _currentUser = null;
        _isCheckingAuth = false;
        notifyListeners();
        return false;
      }

      // Try reading locally cached user first for faster load
      final cachedUser = await _storageService.getUser();
      if (cachedUser != null) {
        _currentUser = UserModel.fromJson(cachedUser);
        notifyListeners();
      }

      // Verify token with backend
      try {
        final user = await _remoteDataSource.getMe();
        _currentUser = user;
        await _storageService.saveUser(user.toJson());
      } catch (e) {
        // If 401, session is invalid
        if (e is UnauthorizedException) {
          await _storageService.clearSession();
          _currentUser = null;
          _isCheckingAuth = false;
          notifyListeners();
          return false;
        }
      }

      _isCheckingAuth = false;
      notifyListeners();
      return _currentUser != null;
    } catch (_) {
      _currentUser = null;
      _isCheckingAuth = false;
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login(String correo, String password, {bool rememberMe = true}) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final request = LoginRequest(correo: correo, password: password);
      final tokenResponse = await _remoteDataSource.login(request);

      // ALWAYS save tokens for the current session (needed for getMe() call)
      await _storageService.saveTokens(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
      );
      
      if (rememberMe) {
        await _storageService.setRememberMe(true);
      }

      // Fetch user details
      final user = await _remoteDataSource.getMe();
      _currentUser = user;
      
      // Save tenant ID from user profile (id_clinica)
      if (user.idClinica != null) {
        await _storageService.saveTenantId(user.idClinica.toString());
      }
      
      if (rememberMe) {
        await _storageService.saveUser(user.toJson());
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
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
      _successMessage = '¡Cuenta creada con éxito! Por favor inicia sesión para continuar.';
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

  // Forgot Password (CU23: el canal decide si el codigo llega por correo o SMS)
  Future<bool> forgotPassword(String correo, {String canal = 'email'}) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final request = ForgotPasswordRequest(correo: correo, canal: canal);
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
  Future<bool> resetPassword(String correo, String codigo, String nuevaPassword) async {
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
      _successMessage = 'Contraseña restablecida exitosamente. Por favor inicia sesión.';
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Ocurrió un error inesperado al restablecer la contraseña.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _inactivityService.stop();

    // CU24: se avisa al backend para que incremente `token_version` y caiga la
    // sesion en todos los dispositivos. Es "best effort": si el servidor no
    // responde se limpia igual, porque el usuario debe salir de la app de
    // inmediato y el token caducara por `exp` por su cuenta.
    try {
      final refreshToken = await _pendingLogoutToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _remoteDataSource.logout(refreshToken);
      }
    } catch (_) {
      // Un fallo de red no debe impedir el cierre local.
    }

    await _storageService.clearSession();
    _currentUser = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Inicia el control de inactividad tras un login correcto (CU23).
  void startInactivityControl() => _inactivityService.start();

  /// Reconcilia el reloj de inactividad contra el servidor (CU23).
  Future<void> syncInactivityWithServer() =>
      _inactivityService.syncWithServer();

  /// Renueva la sesion en el servidor desde el aviso de inactividad (CU23).
  Future<void> continueSession() => _inactivityService.continueSession();

  /// Cuenta regresiva del aviso, en segundos. `null` si no hay aviso activo.
  Stream<int> get inactivityWarning => _inactivityService.warningSeconds;

  /// Emite cuando la sesion se cierra por inactividad (CU23).
  Stream<void> get sessionExpired => _inactivityService.expired;

  @override
  void dispose() {
    _inactivityService.dispose();
    super.dispose();
  }
}
