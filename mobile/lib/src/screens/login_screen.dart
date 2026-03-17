import 'package:flutter/material.dart';

import '../services/catalog_api_service.dart';
import '../store/session_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      await widget.sessionStore.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'No se pudo iniciar sesión';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/maxpeed.png',
                      height: 92,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.local_offer, size: 72),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Maxpeed',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Usuario'),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Ingresa usuario'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                      ),
                      validator: (value) =>
                          (value ?? '').isEmpty ? 'Ingresa contraseña' : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: Text(
                        _isSubmitting ? 'Iniciando...' : 'Iniciar sesión',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
