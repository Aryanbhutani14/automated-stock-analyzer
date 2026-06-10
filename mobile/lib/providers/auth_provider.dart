import 'package:flutter/material.dart';
import '../data/api/auth_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, authenticating }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthStatus _status = AuthStatus.uninitialized;
  String? _token;
  String? _username;
  String? _errorMessage;

  AuthStatus get status => _status;
  String? get token => _token;
  String? get username => _username;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    _token = await _authService.getToken();
    _username = await _authService.getUsername();
    if (_token != null && _username != null) {
      final isValid = await _authService.validateToken(_token!);
      if (isValid) {
        _status = AuthStatus.authenticated;
      } else {
        await _authService.logout();
        _token = null;
        _username = null;
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.login(usernameOrEmail, password);
      if (token != null) {
        _token = token;
        _username = await _authService.getUsername();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return false;
  }

  Future<bool> register(String username, String email, String password) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.register(username, email, password);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    _username = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
