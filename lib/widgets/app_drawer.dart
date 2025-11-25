import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
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
            currentAccountPicture: CustomNetworkImage(
              imageUrl: user?.photoUrl,
              width: 72,
              height: 72,
              isCircular: true,
              fallbackIcon: Icons.person,
              fallbackIconSize: 40,
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
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Sair'),
            onTap: () {
              userProvider.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
