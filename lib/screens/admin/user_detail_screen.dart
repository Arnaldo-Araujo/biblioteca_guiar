import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

class UserDetailScreen extends StatelessWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = Provider.of<UserProvider>(context).userModel;

    // Only admins can access this screen
    if (currentUser?.isAdmin != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acesso Negado')),
        body: const Center(child: Text('Apenas administradores podem acessar esta tela.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(user.nome)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Photo
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null || user.photoUrl!.isEmpty
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            // User Info
            _buildInfoCard('Nome', user.nome),
            _buildInfoCard('Email', user.email),
            _buildInfoCard('CPF', user.cpf),
            _buildInfoCard('Telefone', user.telefone),
            _buildInfoCard('Endereço', user.endereco),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Permission Management
            const Text(
              'Gerenciamento de Permissões',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Helper Toggle
            SwitchListTile(
              title: const Text('Bibliotecário Ativo (Helper)'),
              subtitle: const Text('Permite registrar empréstimos para terceiros'),
              value: user.isHelper,
              onChanged: (value) async {
                final updatedUser = UserModel(
                  uid: user.uid,
                  nome: user.nome,
                  email: user.email,
                  cpf: user.cpf,
                  telefone: user.telefone,
                  endereco: user.endereco,
                  isAdmin: user.isAdmin,
                  isHelper: value,
                  photoUrl: user.photoUrl,
                );

                try {
                  await userProvider.updateUser(updatedUser);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Permissão de bibliotecário concedida'
                              : 'Permissão de bibliotecário removida',
                        ),
                      ),
                    );
                    Navigator.pop(context); // Return to refresh list
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao atualizar: $e')),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 8),

            // Admin Toggle
            SwitchListTile(
              title: const Text('Administrador'),
              subtitle: const Text('Concede acesso total ao sistema'),
              value: user.isAdmin,
              onChanged: (value) async {
                // Show confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmar Alteração'),
                    content: Text(
                      value
                          ? 'Tem certeza que deseja promover ${user.nome} a Administrador? Esta ação concede acesso total ao sistema.'
                          : 'Tem certeza que deseja remover privilégios de administrador de ${user.nome}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Confirmar'),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;

                final updatedUser = UserModel(
                  uid: user.uid,
                  nome: user.nome,
                  email: user.email,
                  cpf: user.cpf,
                  telefone: user.telefone,
                  endereco: user.endereco,
                  isAdmin: value,
                  isHelper: user.isHelper,
                  photoUrl: user.photoUrl,
                );

                try {
                  await userProvider.updateUser(updatedUser);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Usuário promovido a Administrador'
                              : 'Privilégios de administrador removidos',
                        ),
                      ),
                    );
                    Navigator.pop(context); // Return to refresh list
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao atualizar: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }
}
