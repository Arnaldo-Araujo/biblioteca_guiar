import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/loan_model.dart';
import '../../providers/loan_provider.dart';

class ManageLoansScreen extends StatelessWidget {
  const ManageLoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loanProvider = Provider.of<LoanProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Empréstimos')),
      body: StreamBuilder<List<LoanModel>>(
        stream: loanProvider.getAllLoans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final loans = snapshot.data ?? [];
          final activeLoans = loans.where((l) => l.status == 'ativo').toList();

          if (activeLoans.isEmpty) {
            return const Center(child: Text('Nenhum empréstimo ativo.'));
          }

          return ListView.builder(
            itemCount: activeLoans.length,
            itemBuilder: (context, index) {
              final loan = activeLoans[index];
              final dateFormat = DateFormat('dd/MM/yyyy');
              return Card(
                child: ListTile(
                  title: Text(loan.bookTitle),
                  subtitle: Text('Usuário: ${loan.userName}\nPrevisto: ${dateFormat.format(loan.dataPrevistaDevolucao)}'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      try {
                        await loanProvider.returnBook(loan.id, loan.bookId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Livro devolvido com sucesso!')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: $e')),
                        );
                      }
                    },
                    child: const Text('Devolver'),
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
