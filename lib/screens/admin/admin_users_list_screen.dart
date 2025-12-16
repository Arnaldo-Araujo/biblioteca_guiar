import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_network_image.dart';
import 'user_detail_dossier_screen.dart';

class AdminUsersListScreen extends StatelessWidget {
  const AdminUsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Usuários')),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.getAllUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(child: Text('Nenhum usuário encontrado.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CustomNetworkImage(
                    imageUrl: user.photoUrl,
                    width: 50,
                    height: 50,
                    isCircular: true,
                    fallbackIcon: Icons.person,
                  ),
                  title: Text(user.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user.isAdmin)
                        const Chip(
                            label: Text('Admin', style: TextStyle(fontSize: 10)),
                            backgroundColor: Colors.redAccent,
                            labelStyle: TextStyle(color: Colors.white))
                      else if (user.isHelper)
                        const Chip(
                            label: Text('Helper', style: TextStyle(fontSize: 10)),
                            backgroundColor: Colors.orangeAccent),
                      
                      const SizedBox(width: 8),

                      // Botão de Exclusão Lógica
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: user.isAdmin ? Colors.grey : Colors.red,
                        tooltip: user.isAdmin
                            ? 'Não é possível excluir administradores'
                            : 'Desativar usuário',
                        onPressed: user.isAdmin
                            ? null
                            : () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirmar desativação'),
                                    content: const Text(
                                        'Tem certeza que deseja desativar este usuário? Ele perderá acesso ao sistema.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context); // Fecha Dialog
                                          try {
                                            await firestoreService.softDeleteUser(
                                                user.uid, user.isAdmin);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                    content: Text('Usuário desativado com sucesso.')),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                    content: Text('Erro: $e'),
                                                    backgroundColor: Colors.red),
                                              );
                                            }
                                          }
                                        },
                                        child: const Text('Desativar',
                                            style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDetailDossierScreen(user: user),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
