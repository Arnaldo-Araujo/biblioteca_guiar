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
          final activeAndReservedLoans = loans.where((l) => l.status == 'ativo' || l.status == 'reservado').toList();

          if (activeAndReservedLoans.isEmpty) {
            return const Center(child: Text('Nenhum empréstimo ativo ou reservado.'));
          }

          return ListView.builder(
            itemCount: activeAndReservedLoans.length,
            itemBuilder: (context, index) {
              final loan = activeAndReservedLoans[index];
              final dateFormat = DateFormat('dd/MM/yyyy');
              final isReserved = loan.status == 'reservado';

              return Card(
                color: isReserved ? Colors.amber[50] : null,
                child: ListTile(
                  title: Text(loan.bookTitle),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Usuário: ${loan.userName}'),
                      if (isReserved)
                        const Text('Status: RESERVADO (Aguardando retirada)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber))
                      else
                        Text('Previsto: ${dateFormat.format(loan.dataPrevistaDevolucao)}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isReserved)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () async {
                            try {
                              await loanProvider.activateLoan(loan.id, loan.bookId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Empréstimo efetivado com sucesso!')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro: $e')),
                              );
                            }
                          },
                          child: const Text('EFETIVAR'),
                        )
                      else
                        ElevatedButton(
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
