import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book_model.dart';
import '../../models/loan_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/loan_provider.dart';
import '../../widgets/custom_network_image.dart';

class BookDetailScreen extends StatelessWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final loanProvider = Provider.of<LoanProvider>(context);
    final user = userProvider.userModel;

    return Scaffold(
      appBar: AppBar(title: Text(book.titulo)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300,
              width: double.infinity,
              child: CustomNetworkImage(
                imageUrl: book.imageUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                fallbackIcon: Icons.book,
                fallbackIconSize: 100,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.titulo,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'por ${book.autor}',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text('Categoria: ${book.categoria}'),
                  Text('ISBN: ${book.isbn}'),
                  const SizedBox(height: 16),
                  const Text('Sinopse:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(book.sinopse),
                  const SizedBox(height: 16),
                  Text(
                    'Disponíveis: ${book.quantidadeDisponivel}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  
                    if (user != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: book.quantidadeDisponivel > 0
                              ? () async {
                                  try {
                                    // Create Loan
                                    LoanModel loan = LoanModel(
                                      id: '',
                                      userId: user.uid,
                                      bookId: book.id,
                                      bookTitle: book.titulo,
                                      userName: user.nome,
                                      dataEmprestimo: DateTime.now(),
                                      dataPrevistaDevolucao: DateTime.now().add(const Duration(days: 7)),
                                      status: 'ativo',
                                    );

                                    await loanProvider.loanBook(loan);
                                    
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Empréstimo realizado com sucesso!')),
                                      );
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro: $e')),
                                    );
                                  }
                                }
                              : null,
                          child: const Text('SOLICITAR EMPRÉSTIMO'),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    if (user?.isAdmin == true || user?.isHelper == true) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.person_add),
                          label: const Text('EMPRESTAR PARA LEITOR'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          onPressed: book.quantidadeDisponivel > 0
                              ? () async {
                                  // Show user selection dialog
                                  // This requires fetching users. We can use UserProvider.
                                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                                  final users = await userProvider.getAllUsers();
                                  
                                  if (context.mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Selecione o Leitor'),
                                        content: SizedBox(
                                          width: double.maxFinite,
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: users.length,
                                            itemBuilder: (context, index) {
                                              final u = users[index];
                                              return ListTile(
                                                title: Text(u.nome),
                                                subtitle: Text(u.email),
                                                onTap: () async {
                                                  Navigator.pop(context); // Close dialog
                                                  try {
                                                    LoanModel loan = LoanModel(
                                                      id: '',
                                                      userId: u.uid, // Loan for THIS user
                                                      bookId: book.id,
                                                      bookTitle: book.titulo,
                                                      userName: u.nome,
                                                      dataEmprestimo: DateTime.now(),
                                                      dataPrevistaDevolucao: DateTime.now().add(const Duration(days: 7)),
                                                      status: 'ativo',
                                                    );

                                                    await loanProvider.loanBook(loan);
                                                    
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Empréstimo para ${u.nome} realizado!')),
                                                      );
                                                      Navigator.pop(context); // Close screen
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Erro: $e')),
                                                      );
                                                    }
                                                  }
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              : null,
                        ),
                      ),
                    ],
                    
                  if (user?.isAdmin == true) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/edit_book', arguments: book);
                        },
                        child: const Text('EDITAR LIVRO'),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
