import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_models.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // Login
  Future<TokenResponse> login(LoginRequest request) async {
    final response = await _apiClient.post(
      ApiConfig.loginUrl,
      body: request.toJson(),
      includeAuth: false,
    );
    return TokenResponse.fromJson(response as Map<String, dynamic>);
  }

  // Register
  Future<UserModel> register(RegisterRequest request) async {
    final response = await _apiClient.post(
      ApiConfig.registerUrl,
      body: request.toJson(),
      includeAuth: false,
    );
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  // Get current user profile
  Future<UserModel> getMe() async {
    final response = await _apiClient.get(
      ApiConfig.meUrl,
      includeAuth: true,
    );
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  // Refresh token
  Future<TokenResponse> refreshToken(String refreshToken) async {
    final response = await _apiClient.post(
      ApiConfig.refreshUrl,
      body: {'refresh_token': refreshToken},
      includeAuth: false,
    );
    return TokenResponse.fromJson(response as Map<String, dynamic>);
  }
}
