import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which shell tab is showing. Shared so Home can jump to Servers.
class ShellTabController extends Notifier<int> {
  static const home = 0;
  static const servers = 1;
  static const settings = 2;

  @override
  int build() => home;

  void go(int index) => state = index;
}

final shellTabProvider = NotifierProvider<ShellTabController, int>(ShellTabController.new);
