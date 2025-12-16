import 'package:flutter/material.dart';

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
  final _passwordController = TextEditingController(); // Only for permanent delete
  final _formKey = GlobalKey<FormState>();
  
  bool _showPasswordInput = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // If we are showing password input, it means user selected permanent delete
    if (_showPasswordInput) {
      return AlertDialog(
        title: const Text('Confirmar Exclusão Permanente', style: TextStyle(color: Colors.red)),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'ATENÇÃO: Esta ação é IRREVERSÍVEL. Todos os seus dados serão apagados para sempre.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Digite sua senha para confirmar'),
                obscureText: true,
                validator: (v) => v!.isEmpty ? 'Senha obrigatória' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => setState(() => _showPasswordInput = false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _isLoading
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isLoading = true);
                      try {
                        await widget.onDeletePermanently(
                          _feedbackController.text.trim(),
                          _passwordController.text.trim(),
                        );
                        if (mounted) Navigator.pop(context); // Success
                      } catch (e) {
                         if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Erro: ${e.toString().replaceAll('Exception: ', '')}')),
                           );
                         }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    }
                  },
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
              : const Text('EXCLUIR TUDO', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    }

    // Default View
    return AlertDialog(
      title: const Text('Tem certeza que deseja sair?'),
      content: SingleChildScrollView(
         child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Sentiremos sua falta! Conte-nos o motivo da sua saída (obrigatório):'),
            const SizedBox(height: 10),
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ex: Não estou usando o app...',
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
               const Center(child: CircularProgressIndicator())
            else
               Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                   ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.orange,
                       foregroundColor: Colors.white,
                     ),
                     onPressed: () async {
                       if (_feedbackController.text.trim().isEmpty) {
                         ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Por favor, informe o motivo.')));
                         return;
                       }
                       setState(() => _isLoading = true);
                       try {
                         await widget.onDisable(_feedbackController.text.trim());
                         if (mounted) Navigator.pop(context);
                       } catch (e) {
                         if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Erro: ${e.toString()}')),
                           );
                         }
                       } finally {
                         if (mounted) setState(() => _isLoading = false);
                       }
                     },
                     child: const Text('APENAS DESATIVAR (Mantém dados)'),
                   ),
                   const SizedBox(height: 8),
                   TextButton(
                     onPressed: () {
                        if (_feedbackController.text.trim().isEmpty) {
                         ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Por favor, informe o motivo.')));
                         return;
                       }
                       setState(() => _showPasswordInput = true);
                     },
                     child: const Text('Excluir Tudo Permanentemente', style: TextStyle(color: Colors.red)),
                   ),
                 ],
               )
          ],
        ),
      ),
    );
  }
}
