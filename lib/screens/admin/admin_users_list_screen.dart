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
                  trailing: user.isAdmin
                      ? const Chip(label: Text('Admin'), backgroundColor: Colors.redAccent, labelStyle: TextStyle(color: Colors.white))
                      : user.isHelper
                          ? const Chip(label: Text('Helper'), backgroundColor: Colors.orangeAccent)
                          : const Icon(Icons.chevron_right),
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
