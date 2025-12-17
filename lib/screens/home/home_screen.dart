import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book_model.dart';
import '../../providers/book_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/custom_network_image.dart';
import '../book/book_detail_screen.dart';
import '../chat/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final bookProvider = Provider.of<BookProvider>(context);
    final isAdmin = userProvider.userModel?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca Guiar')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Pesquisar livros...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<BookModel>>(
              stream: bookProvider.getBooksStream(showInactive: isAdmin),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                final books = snapshot.data ?? [];
                final filteredBooks = books.where((book) {
                  return book.titulo.toLowerCase().contains(_searchQuery) ||
                         book.autor.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredBooks.isEmpty) {
                  return const Center(child: Text('Nenhum livro encontrado.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filteredBooks.length,
                  itemBuilder: (context, index) {
                    final book = filteredBooks[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetailScreen(book: book),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: CustomNetworkImage(
                                imageUrl: book.imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                fallbackIcon: Icons.book,
                                fallbackIconSize: 50,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book.titulo,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(book.autor, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(
                                    book.quantidadeDisponivel > 0 ? 'Disponível' : 'Indisponível',
                                    style: TextStyle(
                                      color: book.quantidadeDisponivel > 0 ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: !isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                final user = userProvider.userModel;
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatId: user.uid,
                        otherUserName: 'Fale Conosco',
                      ),
                    ),
                  );
                }
              },
              label: const Text('Fale Conosco'),
              icon: const Icon(Icons.chat),
              backgroundColor: Colors.green, // Identidade da biblioteca
            )
          : null,
    );
  }
}
