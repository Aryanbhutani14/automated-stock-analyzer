import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final Dio _dio = Dio();
  
  static final String _host = Platform.isAndroid ? '192.168.1.12' : 'localhost';
  final String _baseUrl = 'http://$_host:8080/api/auth';

  Future<String?> login(String usernameOrEmail, String password) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/login',
        data: {
          'usernameOrEmail': usernameOrEmail,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final token = response.data['token'] as String;
        final username = response.data['username'] as String;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('username', username);
        
        return token;
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to login';
      throw Exception(message);
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
    return null;
  }

  Future<bool> register(String username, String email, String password) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );
      return response.statusCode == 201;
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to register';
      throw Exception(message);
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<bool> validateToken(String token) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('username');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }
}
