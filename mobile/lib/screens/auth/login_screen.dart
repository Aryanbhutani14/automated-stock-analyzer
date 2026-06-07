import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  bool    _loading = false;
  String? _error;

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authStateProvider.notifier).login(_email.text.trim(), _password.text);
    } catch (e) {
      setState(() => _error = e.toString().contains('401') ? 'Invalid email or password' : 'Login failed. Try again.');
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
                Text('Stock Analyzer', textAlign: TextAlign.center,
                     style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Sign in to your account', textAlign: TextAlign.center,
                     style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 36),
                if (_error != null) ...[
                  _ErrorBox(_error!), const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _email, keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password, obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                  onFieldSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Sign In'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text("Don't have an account? Register"),
                ),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox(this.message);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.bearish.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.bearish.withOpacity(0.5)),
    ),
    child: Text(message, style: const TextStyle(color: AppTheme.bearish, fontSize: 13)),
  );
}
