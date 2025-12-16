import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/user_provider.dart';
import '../providers/loan_provider.dart';
import 'custom_network_image.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.userModel;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.nome ?? 'Usuário'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: Stack(
              children: [
                CustomNetworkImage(
                  imageUrl: user?.photoUrl,
                  width: 72,
                  height: 72,
                  isCircular: true,
                  fallbackIcon: Icons.person,
                  fallbackIconSize: 40,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () => _showImageSourceActionSheet(context, userProvider),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Livros'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Meus Empréstimos'),
            onTap: () {
              // Navigate to loans screen
              Navigator.pushNamed(context, '/my_loans');
            },
          ),
          if (user?.isAdmin == true || user?.isHelper == true) ...[
            const Divider(),
            const ListTile(
              title: Text('ADMINISTRATIVO', style: TextStyle(color: Colors.grey)),
            ),
            if (user?.isAdmin == true)
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                onTap: () {
                  Navigator.pushNamed(context, '/dashboard');
                },
              ),
            if (user?.isAdmin == true)
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Usuários'),
                onTap: () {
                  Navigator.pushNamed(context, '/users');
                },
              ),
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('Gerenciar Empréstimos'),
              onTap: () {
                Navigator.pushNamed(context, '/manage_loans');
              },
            ),
            if (user?.isAdmin == true)
              ListTile(
                leading: const Icon(Icons.add_box),
                title: const Text('Cadastrar Livro'),
                onTap: () {
                  Navigator.pushNamed(context, '/add_book');
                },
              ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Editar Perfil'),
            onTap: () {
              Navigator.pushNamed(context, '/edit_profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Alterar Senha'),
            onTap: () {
              Navigator.pushNamed(context, '/change_password');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Sair'),
            onTap: () async {
              // 1. Clear Data from Providers
              Provider.of<UserProvider>(context, listen: false).clearData();
              Provider.of<LoanProvider>(context, listen: false).clearData();
              
              // 2. Sign Out
              await userProvider.signOut();
              
              // 3. Navigate to Login
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context, UserProvider userProvider) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(context, ImageSource.gallery, userProvider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Câmera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(context, ImageSource.camera, userProvider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source, UserProvider userProvider) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        await userProvider.updateProfilePhoto(imageFile);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto de perfil atualizada com sucesso!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar foto: $e')),
        );
      }
    }
  }
}
