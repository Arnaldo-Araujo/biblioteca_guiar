import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.menu_book_rounded, size: 80, color: Colors.blue),
                const SizedBox(height: 20),
                const Text(
                  'Biblioteca Guiar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.isEmpty ? 'Informe o email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                  validator: (value) => value!.isEmpty ? 'Informe a senha' : null,
                ),
                const SizedBox(height: 24),
                if (userProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          await userProvider.signIn(
                            _emailController.text.trim(),
                            _passwordController.text.trim(),
                          );
                          // Navigation is handled by AuthWrapper
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao logar: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('ENTRAR'),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        final emailController = TextEditingController();
                        return AlertDialog(
                          title: const Text('Redefinir Senha'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Informe seu email para receber o link de redefinição.'),
                              const SizedBox(height: 16),
                              TextField(
                                controller: emailController,
                                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('CANCELAR'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final email = emailController.text.trim();
                                if (email.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Informe o email')),
                                  );
                                  return;
                                }
                                Navigator.pop(context); // Close dialog
                                try {
                                  await Provider.of<UserProvider>(context, listen: false).sendPasswordResetEmail(email);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Email de redefinição enviado! Verifique sua caixa de entrada.')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro: $e')),
                                    );
                                  }
                                }
                              },
                              child: const Text('ENVIAR'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('Esqueci minha senha'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text('Quero me cadastrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
