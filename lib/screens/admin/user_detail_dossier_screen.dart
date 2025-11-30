import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/loan_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_network_image.dart';

class UserDetailDossierScreen extends StatelessWidget {
  final UserModel user;

  const UserDetailDossierScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Dossiê do Usuário')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Seção 1: Cabeçalho
            Container(
              color: Colors.blue[50],
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CustomNetworkImage(
                    imageUrl: user.photoUrl,
                    width: 100,
                    height: 100,
                    isCircular: true,
                    fallbackIcon: Icons.person,
                    fallbackIconSize: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.nome,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Text(user.email, style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.phone, user.telefone),
                  _buildInfoRow(Icons.badge, 'CPF: ${user.cpf}'),
                  _buildInfoRow(Icons.home, user.endereco),
                ],
              ),
            ),

            // Seção 2 e 3: Estatísticas e Histórico
            StreamBuilder<List<LoanModel>>(
              stream: firestoreService.getLoansByUserId(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  );
                }
                
                final loans = snapshot.data ?? [];
                final activeLoans = loans.where((l) => l.status == 'ativo').length;
                final totalRead = loans.where((l) => l.status == 'devolvido').length;
                final lateLoans = loans.where((l) => l.status == 'ativo' && DateTime.now().isAfter(l.dataPrevistaDevolucao)).length;

                return Column(
                  children: [
                    // Estatísticas
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard('Lidos', totalRead.toString(), Colors.blue),
                          _buildStatCard('Ativos', activeLoans.toString(), Colors.orange),
                          _buildStatCard('Atrasos', lateLoans.toString(), Colors.red),
                        ],
                      ),
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Histórico de Empréstimos',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (loans.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Nenhum histórico encontrado.'),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: loans.length,
                        itemBuilder: (context, index) {
                          final loan = loans[index];
                          return _buildLoanHistoryCard(loan);
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanHistoryCard(LoanModel loan) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.check_circle;

    if (loan.status == 'ativo') {
      if (DateTime.now().isAfter(loan.dataPrevistaDevolucao)) {
        statusColor = Colors.red;
        statusIcon = Icons.warning;
      } else {
        statusColor = Colors.green;
        statusIcon = Icons.book;
      }
    } else if (loan.status == 'reservado') {
      statusColor = Colors.amber;
      statusIcon = Icons.hourglass_empty;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(loan.bookTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'Empréstimo: ${dateFormat.format(loan.dataEmprestimo)}\n'
          'Status: ${loan.status.toUpperCase()}',
        ),
        isThreeLine: true,
      ),
    );
  }
}
