import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/user_provider.dart';
import '../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscured = true;
  bool _isLoading = false;

  String _translateFirebaseError(dynamic error) {
    String message = error.toString();
    if (message.contains('user-not-found')) return 'E-mail não encontrado.';
    if (message.contains('wrong-password')) return 'Senha incorreta.';
    if (message.contains('invalid-credential')) return 'Credenciais inválidas.';
    if (message.contains('invalid-email')) return 'E-mail inválido.';
    if (message.contains('user-disabled')) return 'Usuário desativado.';
    if (message.contains('too-many-requests')) return 'Muitas tentativas. Tente mais tarde.';
    return 'Erro ao entrar: Verifique seus dados.';
  }

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
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _isObscured = !_isObscured;
                        });
                      },
                    ),
                  ),
                  obscureText: _isObscured,
                  validator: (value) => value!.isEmpty ? 'Informe a senha' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          // 1. Validação do Form
                          if (!_formKey.currentState!.validate()) return;

                          // 2. Fecha teclado IMEDIATAMENTE (antes do async)
                          FocusScope.of(context).unfocus();

                          print("--- UI: Botão Clicado ---");

                          // 3. Loading
                          setState(() => _isLoading = true);

                          try {
                            // 4. Chamada Async
                            await Provider.of<UserProvider>(context, listen: false)
                                .signIn(_emailController.text.trim(), _passwordController.text.trim());

                            // 2. LOG DE DEBUG
                            print("--- UI: Login Sucesso! Navegando para Home... ---");

                            // 3. NAVEGAÇÃO SEGURA (Remove tudo e vai para a raiz, forçando reload do AuthWrapper)
                            if (mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                            }
                          } catch (e) {
                            // ERRO:
                            print("--- UI: Erro recebido na tela: $e ---");
                            
                            // NÃO verificamos 'mounted' aqui para o SnackBar, pois a chave é global.
                            // Mas se fôssemos fazer setState para algo local, precisaríamos.
                            // Como vamos usar a chave global, não tem problema se a tela desmontou.

                            String msg = "Erro desconhecido";
                            if (e.toString().contains('user-not-found')) {
                              msg = "Usuário não encontrado.";
                            } else if (e.toString().contains('wrong-password')) {
                              msg = "Senha incorreta.";
                            } else if (e.toString().contains('invalid-credential')) {
                              msg = "Credenciais inválidas.";
                            } else if (e.toString().contains('invalid-email')) {
                              msg = "E-mail inválido.";
                            } else {
                              msg = "Erro: ${e.toString()}";
                            }

                            rootScaffoldMessengerKey.currentState?.showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          } finally {
                            // 5. Parar Loading
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('ENTRAR'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot-password');
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
