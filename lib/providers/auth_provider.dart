// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/profile.dart';
import '../data/services/supabase_service.dart';

// ── Supabase client singleton ────────────────────────
final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

// ── Service singleton ────────────────────────────────
final supabaseServiceProvider = Provider<SupabaseService>(
  (ref) => SupabaseService(ref.watch(supabaseClientProvider)),
);

// ── Auth state stream ────────────────────────────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

// ── Current user ─────────────────────────────────────
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser;
});

// ── Current profile (role, name) ─────────────────────
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(supabaseServiceProvider).fetchCurrentProfile();
});

// ── Auth notifier (sign in / sign out actions) ────────
class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(supabaseServiceProvider).signIn(email: email, password: password));
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(supabaseServiceProvider).signUp(
          email:    email,
          password: password,
          fullName: fullName,
          role:     role,
        ));
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(supabaseServiceProvider).signOut());
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
