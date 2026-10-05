import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_service.dart';
import '../domain/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, error }

class AuthController extends ChangeNotifier {
  final AuthService authService;

  AuthStatus _status = AuthStatus.unknown;
  User? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  AuthController({required this.authService});

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> checkSession() async {
    _status = AuthStatus.unknown;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await authService.getStoredToken();
      if (token == null || token.isEmpty) {
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
        notifyListeners();
        return;
      }

      final user = await authService.getCurrentUser();
      _currentUser = user;
      _status = AuthStatus.authenticated;
    } on ApiException catch (e) {
      if (e.type == ApiErrorType.unauthorized ||
          e.type == ApiErrorType.forbidden) {
        await authService.logout();
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
      } else {
        _errorMessage = e.userFriendlyMessage;
        _status = AuthStatus.error;
      }
    } catch (e) {
      _errorMessage = 'Failed to check authentication session.';
      _status = AuthStatus.error;
    }

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.login(email: email, password: password);
      final user = await authService.getCurrentUser();
      _currentUser = user;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _status = AuthStatus.error;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected login error occurred.';
      _status = AuthStatus.error;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerAndLogin({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      return await login(email, password);
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _status = AuthStatus.error;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected registration error occurred.';
      _status = AuthStatus.error;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await authService.logout();
    } catch (_) {}

    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
