import 'package:flutter/material.dart';
import '../main.dart'; // Import rootScaffoldMessengerKey

class DeleteAccountDialog extends StatefulWidget {
  final Future<void> Function(String feedback) onDisable;
  final Future<void> Function(String feedback, String password) onDeletePermanently;

  const DeleteAccountDialog({
    super.key,
    required this.onDisable,
    required this.onDeletePermanently,
  });

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _feedbackController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Key for the permanent delete form
  
  bool _showPasswordInput = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // VIEW 2: Confirmação de Exclusão (Senha)
    if (_showPasswordInput) {
      return AlertDialog(
        scrollable: true,
        title: const Text('Confirmar Exclusão', style: TextStyle(color: Colors.red)),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Esta ação é irreversível. Todos os seus dados serão apagados.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Senha Atual',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Digite sua senha para continuar.';
                  }
                  return null;
                },
                onChanged: (val) {
                  // Rebuild to update button state if we were using a listenable, 
                  // but form validation happens on press usually.
                  // For "O botão ... só deve chamar ... se a senha não estiver vazia",
                  // keeping the validator is sufficient combined with form validate().
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => setState(() => _showPasswordInput = false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: _isLoading
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      // 1. Fecha teclado
                      FocusScope.of(context).unfocus();
                      
                      setState(() => _isLoading = true);
                      try {
                        // Importante: Passa o context em variável local ou acessa via closure segura
                        // Mas aqui vamos usar o widget callback.
                        
                        await widget.onDeletePermanently(
                          _feedbackController.text.trim(),
                          _passwordController.text.trim(),
                        );
                        
                        // 4. FECHA O DIALOG (Importante para não travar overlay)
                        if (mounted) Navigator.of(context).pop();

                        // 5. EXIBE A MENSAGEM GLOBAL (Sobrevive ao Logout)
                        // Precisamos importar o main.dart ou definir a key como global acessível.
                        // Como main.dart não é importado aqui, vamos usar ScaffoldMessenger.of(context)
                        // MAS ISSO FALHA se o context for destruído (que é o caso no logout).
                        // O prompt pede para usar rootScaffoldMessengerKey.
                        // Vou importar o main.dart.
                        
                        // Assumindo que a key foi definida em main.dart como global.
                        // Se não puder importar main, o usuário teria que passar a key.
                        // Mas vamos adicionar o import.
                        
                        // Nota: O replace_file_content não adiciona imports no topo se eu não incluir o topo.
                        // Vou confiar que o usuário já tem, ou o compilador vai reclamar e eu corrijo.
                        // Verificando imports: só tem 'package:flutter/material.dart'.
                        // Preciso adicionar o import do main.dart.
                        // Como é replace_content, vou fazer em dois passos ou usar multi_replace se necessário.
                        // Vou fazer um bloco maior que inclua tudo ou pedir para adicionar o import.
                        // Melhor: Vou usar o rootScaffoldMessengerKey do main.dart. 
                        // Vou adicionar o import no topo primeiro em outro passo, 
                        rootScaffoldMessengerKey.currentState?.showSnackBar(
                          const SnackBar(
                            content: Text("Sua conta e todos os seus dados foram excluídos com sucesso."),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 4),
                          ),
                        );
                      } catch (e) {
                         if (mounted) {
                           final msg = e.toString().replaceAll('Exception: ', '');
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                               content: Text('Erro: $msg'),
                               backgroundColor: Colors.red,
                             ),
                           );
                           setState(() => _isLoading = false);
                         }
                      }
                    }
                  },
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('EXCLUIR PERMANENTEMENTE'),
          ),
        ],
      );
    }

    // VIEW 1: Feedback e Opções
    return AlertDialog(
      title: const Text('Deseja sair?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Conte-nos o motivo (obrigatório):'),
            const SizedBox(height: 10),
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ex: Não uso mais o app...',
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            if (!_isLoading) ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (_feedbackController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Por favor, informe o motivo.')),
                    );
                    return;
                  }
                  setState(() => _isLoading = true);
                  try {
                    await widget.onDisable(_feedbackController.text.trim());
                    if (mounted) Navigator.pop(context); // Disable just logs out usually
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro: ${e.toString()}')),
                      );
                      setState(() => _isLoading = false);
                    }
                  }
                },
                child: const Text('APENA DESATIVAR (Reversível)'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                   if (_feedbackController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Por favor, informe o motivo.')),
                    );
                    return;
                  }
                  setState(() => _showPasswordInput = true);
                },
                child: const Text('Excluir Tudo Permanentemente (Perigoso)', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
