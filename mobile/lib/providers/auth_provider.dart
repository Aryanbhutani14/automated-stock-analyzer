import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';
import '../data/api/api_client.dart';
import '../data/models/user_model.dart';

// ── Current user state ────────────────────────────────────────────────
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.read(apiClientProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final ApiClient _api;
  final _storage = const FlutterSecureStorage();

  AuthNotifier(this._api) : super(const AsyncValue.loading()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final raw = await _storage.read(key: AppConstants.userKey);
      if (raw != null) {
        state = AsyncValue.data(UserModel.fromJson(jsonDecode(raw)));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final json = await _api.login(email, password);
      final user = UserModel.fromJson(json);
      await _storage.write(key: AppConstants.tokenKey, value: user.token);
      await _storage.write(
          key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(
      String username, String email, String password) async {
    await _api.register(username, email, password);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AsyncValue.data(null);
  }
}
