import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';

import 'auth_repository.dart';

/// Static login until the API exists. Accepts only the demo account.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._prefs);

  final SharedPreferences _prefs;

  static const demoUsername = 'demo';
  static const demoPassword = 'demo1234';
  static const _sessionKey = 'auth.session.username';

  @override
  Future<AuthUser?> restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final saved = _prefs.getString(_sessionKey);
    return saved == null ? null : _user(saved);
  }

  @override
  Future<AuthUser> signIn({
    required String username,
    required String password,
    required bool remember,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (username.toLowerCase() != demoUsername || password != demoPassword) {
      throw const AuthException(AuthFailure.invalidCredentials);
    }
    if (remember) {
      await _prefs.setString(_sessionKey, username);
    } else {
      await _prefs.remove(_sessionKey);
    }
    return _user(username);
  }

  AuthUser _user(String username) =>
      AuthUser(username: username, subscriptionUrl: AppConfig.devSubscriptionUrl);

  @override
  Future<void> signOut() async {
    await _prefs.remove(_sessionKey);
  }
}
