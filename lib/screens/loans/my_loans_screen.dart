import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/loan_model.dart';
import '../../providers/loan_provider.dart';
import '../../providers/user_provider.dart';

class MyLoansScreen extends StatelessWidget {
  const MyLoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final loanProvider = Provider.of<LoanProvider>(context);
    final uid = userProvider.userModel?.uid;

    if (uid == null) return const Scaffold(body: Center(child: Text('Erro: Usuário não logado')));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meus Empréstimos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Com você'),
              Tab(text: 'Histórico'),
            ],
          ),
        ),
        body: StreamBuilder<List<LoanModel>>(
          stream: loanProvider.getUserLoans(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            }

            final loans = snapshot.data ?? [];
            final activeAndReservedLoans = loans.where((l) => l.status == 'ativo' || l.status == 'reservado').toList();
            final historyLoans = loans.where((l) => l.status == 'devolvido').toList();

            return TabBarView(
              children: [
                _buildLoanList(activeAndReservedLoans, false),
                _buildLoanList(historyLoans, true),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoanList(List<LoanModel> loans, bool isHistory) {
    if (loans.isEmpty) {
      return const Center(child: Text('Nenhum empréstimo encontrado.'));
    }
    return ListView.builder(
      itemCount: loans.length,
      itemBuilder: (context, index) {
        final loan = loans[index];
        final dateFormat = DateFormat('dd/MM/yyyy');
        final isReserved = loan.status == 'reservado';
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: isReserved 
                ? const Icon(Icons.watch_later, color: Colors.amber, size: 40)
                : (isHistory ? const Icon(Icons.check_circle, color: Colors.green, size: 40) : const Icon(Icons.book, color: Colors.blue, size: 40)),
            title: Text(loan.bookTitle),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isReserved)
                  const Text('Status: AGUARDANDO RETIRADA', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))
                else
                  Text('Empréstimo: ${dateFormat.format(loan.dataEmprestimo)}'),
                
                Text('Devolução Prevista: ${dateFormat.format(loan.dataPrevistaDevolucao)}'),
                
                if (loan.dataDevolucaoReal != null)
                  Text('Devolvido em: ${dateFormat.format(loan.dataDevolucaoReal!)}',
                      style: const TextStyle(color: Colors.green)),
              ],
            ),
            trailing: isReserved
                ? null
                : (isHistory
                    ? null
                    : const Icon(Icons.timer, color: Colors.orange)),
          ),
        );
      },
    );
  }
}
