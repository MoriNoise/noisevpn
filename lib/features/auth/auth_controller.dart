import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../servers/servers_controller.dart';
import '../vpn/vpn_controller.dart';
import 'auth_repository.dart';

/// null = signed out. Loading only while restoring the saved session at launch.
class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() => ref.read(authRepositoryProvider).restoreSession();

  /// Throws [AuthException]; the login screen shows the message.
  Future<void> signIn({
    required String username,
    required String password,
    required bool remember,
  }) async {
    final user = await ref.read(authRepositoryProvider).signIn(
          username: username,
          password: password,
          remember: remember,
        );
    state = AsyncData(user);
  }

  /// Ends the VPN session before signing out.
  /// When the API arrives, also remove the account's own subscription here
  /// (ServersController.removeSource) so the next account doesn't see it.
  Future<void> signOut() async {
    await ref.read(vpnControllerProvider.notifier).disconnect();
    ref.invalidate(pingControllerProvider);
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);
