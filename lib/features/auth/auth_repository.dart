import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/prefs.dart';
import 'mock_auth_repository.dart';

class AuthUser {
  const AuthUser({required this.username, this.subscriptionUrl});

  final String username;

  /// The account's own subscription once the API returns one. Not used yet:
  /// for now servers come from what's added on the Servers screen.
  final String? subscriptionUrl;

  String get initial => username.isEmpty ? '?' : username.substring(0, 1).toUpperCase();
}

enum AuthFailure { invalidCredentials, network }

class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;

  @override
  String toString() => 'AuthException($failure)';
}

/// The only thing the UI knows about authentication.
/// When the real API is ready, add an `ApiAuthRepository` and swap it
/// in [authRepositoryProvider]. Nothing else has to change.
abstract interface class AuthRepository {
  Future<AuthUser?> restoreSession();

  Future<AuthUser> signIn({
    required String username,
    required String password,
    required bool remember,
  });

  Future<void> signOut();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(ref.watch(sharedPreferencesProvider)),
);
