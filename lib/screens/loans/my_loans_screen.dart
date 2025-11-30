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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final uid = userProvider.userModel?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Erro: Usuário não identificado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Estante'),
      ),
      body: Consumer<LoanProvider>(
        builder: (context, loanProvider, child) {
          return StreamBuilder<List<LoanModel>>(
            stream: loanProvider.fetchUserLoans(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Erro ao carregar empréstimos: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final loans = snapshot.data ?? [];

              if (loans.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Você ainda não tem empréstimos.',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: loans.length,
                itemBuilder: (context, index) {
                  final loan = loans[index];
                  return _buildLoanCard(loan);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoanCard(LoanModel loan) {
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    Color borderColor;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    // Lógica de Status (Semáforo)
    if (loan.status == 'reservado') {
      // 🟡 AMARELO (Aguardando)
      borderColor = Colors.amber;
      statusColor = Colors.amber[700]!;
      statusText = "Aguardando retirada na biblioteca";
      statusIcon = Icons.hourglass_empty;
    } else if (loan.status == 'devolvido') {
      // ⚫ CINZA (Histórico)
      borderColor = Colors.grey;
      statusColor = Colors.grey[700]!;
      statusText = "Devolvido em ${loan.dataDevolucaoReal != null ? dateFormat.format(loan.dataDevolucaoReal!) : '-'}";
      statusIcon = Icons.check_circle_outline;
    } else if (loan.status == 'ativo') {
      // Verificar atraso
      // Compara apenas as datas, ignorando hora se necessário, ou comparação direta
      if (now.isAfter(loan.dataPrevistaDevolucao)) {
        // 🔴 VERMELHO (ATRASADO)
        borderColor = Colors.red;
        statusColor = Colors.red;
        statusText = "ATRASADO! Devolva imediatamente";
        statusIcon = Icons.warning_amber_rounded;
      } else {
        // 🟢 VERDE (Em dia)
        borderColor = Colors.green;
        statusColor = Colors.green;
        statusText = "Devolver até ${dateFormat.format(loan.dataPrevistaDevolucao)}";
        statusIcon = Icons.event_available;
      }
    } else {
      // Fallback
      borderColor = Colors.grey;
      statusColor = Colors.grey;
      statusText = loan.status;
      statusIcon = Icons.info_outline;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título do Livro
            Text(
              loan.bookTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Status Chip/Row
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Datas Relevantes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Data Empréstimo', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      dateFormat.format(loan.dataEmprestimo),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (loan.status == 'ativo' || loan.status == 'reservado')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Previsão Devolução', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        dateFormat.format(loan.dataPrevistaDevolucao),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
