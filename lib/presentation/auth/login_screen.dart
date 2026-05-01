// lib/presentation/auth/login_screen.dart
//
// Sign In + Sign Up (tab-based). Admin self-registers with a secret code.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

/// Change this to any secure string for your deployment.
const _adminSecretCode = 'ADMIN2024';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ─────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E), Color(0xFF16213E)],
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
              ),
            ),
          ),
          // ── Decorative circles ──────────────────────
          Positioned(
            top: -80, left: -80,
            child: _DecorCircle(size: 300, color: AppTheme.primary),
          ),
          Positioned(
            bottom: -100, right: -60,
            child: _DecorCircle(size: 260, color: AppTheme.secondary),
          ),
          // ── Main content ────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.secondary],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:       AppTheme.primary.withOpacity(0.4),
                            blurRadius:  24,
                            offset:      const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.storefront, color: Colors.white, size: 38),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SalesLedger',
                      style: TextStyle(
                        fontSize:   28,
                        fontWeight: FontWeight.w800,
                        color:      Colors.white,
                      ),
                    ),
                    const Text(
                      'Building Material Sales & Inventory',
                      style: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 13),
                    ),
                    const SizedBox(height: 40),

                    // ── Card ────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color:        AppTheme.surfaceVar.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(24),
                        border:       Border.all(color: AppTheme.outline),
                        boxShadow: [
                          BoxShadow(
                            color:       Colors.black.withOpacity(0.3),
                            blurRadius:  32,
                            offset:      const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Tabs
                          TabBar(
                            controller:         _tabCtrl,
                            indicatorColor:     AppTheme.primary,
                            labelColor:         AppTheme.primary,
                            unselectedLabelColor: AppTheme.onSurfaceSub,
                            tabs: const [
                              Tab(text: 'Sign In'),
                              Tab(text: 'Sign Up'),
                            ],
                          ),
                          const Divider(height: 1),
                          SizedBox(
                            height: 420,
                            child: TabBarView(
                              controller: _tabCtrl,
                              children: const [
                                _SignInForm(),
                                _SignUpForm(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sign In form ──────────────────────────────────────
class _SignInForm extends ConsumerStatefulWidget {
  const _SignInForm();

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool  _obscure   = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller:  _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration:  const InputDecoration(
                labelText:  'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller:  _passCtrl,
              obscureText: _obscure,
              decoration:  InputDecoration(
                labelText:  'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 28),
            authState.when(
              data:    (_) => _SignInButton(formKey: _formKey, emailCtrl: _emailCtrl, passCtrl: _passCtrl),
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:        AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border:       Border.all(color: AppTheme.error.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _parseError(e.toString()),
                            style: const TextStyle(color: AppTheme.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SignInButton(formKey: _formKey, emailCtrl: _emailCtrl, passCtrl: _passCtrl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInButton extends ConsumerWidget {
  const _SignInButton({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
  });

  final GlobalKey<FormState>     formKey;
  final TextEditingController    emailCtrl, passCtrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          if (formKey.currentState!.validate()) {
            ref.read(authNotifierProvider.notifier).signIn(
                  email:    emailCtrl.text.trim(),
                  password: passCtrl.text,
                );
          }
        },
        child: const Text('Sign In'),
      ),
    );
  }
}

// ── Sign Up form ──────────────────────────────────────
class _SignUpForm extends ConsumerStatefulWidget {
  const _SignUpForm();

  @override
  ConsumerState<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<_SignUpForm> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _secretCtrl  = TextEditingController();
  bool  _obscure     = true;
  bool  _isAdmin     = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller:  _nameCtrl,
              decoration:  const InputDecoration(
                labelText:  'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller:  _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration:  const InputDecoration(
                labelText:  'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller:  _passCtrl,
              obscureText: _obscure,
              decoration:  InputDecoration(
                labelText:  'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 12),

            // Admin toggle
            Row(
              children: [
                Switch(
                  value:       _isAdmin,
                  activeColor: AppTheme.primary,
                  onChanged:   (v) => setState(() => _isAdmin = v),
                ),
                const SizedBox(width: 8),
                const Text('Register as Admin', style: TextStyle(fontSize: 13)),
              ],
            ),
            if (_isAdmin)
              TextFormField(
                controller:  _secretCtrl,
                obscureText: true,
                decoration:  const InputDecoration(
                  labelText:  'Admin Secret Code',
                  prefixIcon: Icon(Icons.key_outlined),
                ),
                validator: (v) {
                  if (_isAdmin && v != _adminSecretCode) return 'Invalid secret code';
                  return null;
                },
              ),
            const SizedBox(height: 20),

            authState.when(
              data: (_) => SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ref.read(authNotifierProvider.notifier).signUp(
                            email:    _emailCtrl.text.trim(),
                            password: _passCtrl.text,
                            fullName: _nameCtrl.text.trim(),
                            role:     _isAdmin ? 'admin' : 'staff',
                          );
                    }
                  },
                  child: const Text('Create Account'),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:        AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border:       Border.all(color: AppTheme.error.withOpacity(0.4)),
                    ),
                    child: Text(
                      _parseError(e.toString()),
                      style: const TextStyle(color: AppTheme.error, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          ref.read(authNotifierProvider.notifier).signUp(
                                email:    _emailCtrl.text.trim(),
                                password: _passCtrl.text,
                                fullName: _nameCtrl.text.trim(),
                                role:     _isAdmin ? 'admin' : 'staff',
                              );
                        }
                      },
                      child: const Text('Create Account'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────
String _parseError(String raw) {
  if (raw.contains('Invalid login credentials')) return 'Invalid email or password.';
  if (raw.contains('Email already registered'))   return 'This email is already registered.';
  if (raw.contains('Password should be'))          return 'Password must be at least 6 characters.';
  return raw.length > 100 ? '${raw.substring(0, 100)}…' : raw;
}

class _DecorCircle extends StatelessWidget {
  const _DecorCircle({required this.size, required this.color});
  final double size;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.08),
      ),
    );
  }
}
