// lib/router/app_router.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/shell/platform_shell.dart';
import '../providers/providers.dart';

// ── Auth state notifier (stable, no race on startup) ─
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(SupabaseClient client) {
    // Set initial state synchronously from the current session
    _isLoggedIn = client.auth.currentSession != null;

    // Only notify router on genuine auth state changes
    _sub = client.auth.onAuthStateChange.listen((event) {
      final nowLoggedIn = event.session != null;
      if (nowLoggedIn != _isLoggedIn) {
        _isLoggedIn = nowLoggedIn;
        notifyListeners();
      }
    });
  }

  late final StreamSubscription<AuthState> _sub;
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final client   = ref.watch(supabaseClientProvider);
  final notifier = _AuthNotifier(client);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    refreshListenable:   notifier,
    initialLocation:     '/login',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path:    '/login',
        name:    'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path:    '/home',
        name:    'home',
        builder: (_, __) => const PlatformShell(),
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = notifier.isLoggedIn;
      final isOnLogin  = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn  &&  isOnLogin) return '/home';
      return null;
    },
  );
});
