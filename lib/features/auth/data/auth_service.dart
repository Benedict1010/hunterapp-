import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_token.dart';
import '../domain/user.dart';

class AuthService {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  AuthService({required this.apiClient, required this.tokenStorage});

  Future<User> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await apiClient.post(
      '/auth/register',
      body: {'email': email, 'password': password, 'full_name': fullName},
    );
    return User.fromJson(response as Map<String, dynamic>);
  }

  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    final authToken = AuthToken.fromJson(response as Map<String, dynamic>);
    if (authToken.accessToken.isNotEmpty) {
      await tokenStorage.saveToken(authToken.accessToken);
    }
    return authToken;
  }

  Future<User> getCurrentUser() async {
    final response = await apiClient.get('/users/me');
    return User.fromJson(response as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await tokenStorage.clearToken();
  }

  Future<String?> getStoredToken() async {
    return tokenStorage.getToken();
  }
}
