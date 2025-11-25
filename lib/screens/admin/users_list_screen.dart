import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = Provider.of<UserProvider>(context, listen: false).getAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Usuários')),
      body: FutureBuilder<List<UserModel>>(
        future: _usersFuture,
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
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(user.nome.isNotEmpty ? user.nome[0].toUpperCase() : 'U'),
                  ),
                  title: Text(user.nome),
                  subtitle: Text(user.email),
                  trailing: user.isAdmin
                      ? const Chip(label: Text('Admin'), backgroundColor: Colors.redAccent)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Apoio: '),
                            Switch(
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
                                );
                                
                                try {
                                  await userProvider.updateUser(updatedUser);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Permissão de apoio ${value ? "concedida" : "removida"} para ${user.nome}')),
                                    );
                                    _loadUsers(); // Refresh list
                                  }
                                } catch (e) {
                                  if (mounted) {
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
            },
          );
        },
      ),
    );
  }
}
