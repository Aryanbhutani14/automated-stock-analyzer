import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  bool    _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() { _username.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authStateProvider.notifier)
               .register(_username.text.trim(), _email.text.trim(), _password.text);
      setState(() => _success = 'Account created! Redirecting…');
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) context.go('/login');
    } catch (_) {
      setState(() => _error = 'Registration failed. Email or username may already exist.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('📈', textAlign: TextAlign.center, style: TextStyle(fontSize: 60)),
                const SizedBox(height: 12),
                Text('Create Account', textAlign: TextAlign.center,
                     style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 36),
                if (_error   != null) ...[_MsgBox(_error!,   isError: true),  const SizedBox(height: 16)],
                if (_success != null) ...[_MsgBox(_success!, isError: false), const SizedBox(height: 16)],
                TextFormField(
                  controller: _username,
                  decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => (v == null || v.length < 3) ? 'At least 3 characters' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email, keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password, obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) => (v == null || v.length < 8) ? 'At least 8 characters' : null,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create Account'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Sign in'),
                ),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MsgBox extends StatelessWidget {
  final String message;
  final bool isError;
  const _MsgBox(this.message, {required this.isError});
  @override
  Widget build(BuildContext context) {
    final color = isError ? AppTheme.bearish : AppTheme.bullish;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(message, style: TextStyle(color: color, fontSize: 13)),
    );
  }
}
