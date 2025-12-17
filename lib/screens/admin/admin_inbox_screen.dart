import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this imports for Timestamp/QuerySnapshot
import 'package:intl/intl.dart';
import '../../providers/chat_provider.dart';
import '../chat/chat_screen.dart';

class AdminInboxScreen extends StatelessWidget {
  const AdminInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caixa de Entrada'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatProvider.getAdminInboxStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma mensagem recebida.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final String userName = data['userName'] ?? 'Usuário Desconhecido';
              final String lastMsg = data['lastMessage'] ?? '';
              final Timestamp? time = data['lastMessageTime'];
              final int unreadCount = data['unreadCount'] ?? 0;
              final String chatId = doc.id; // The User ID

              String timeStr = '';
              if (time != null) {
                final date = time.toDate();
                if (date.day == DateTime.now().day && 
                    date.month == DateTime.now().month && 
                    date.year == DateTime.now().year) {
                  timeStr = DateFormat('HH:mm').format(date);
                } else {
                  timeStr = DateFormat('dd/MM').format(date);
                }
              }

              return ListTile(
                leading: CircleAvatar(
                  child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?'),
                ),
                title: Text(
                  userName,
                  style: TextStyle(
                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  lastMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unreadCount > 0 ? Colors.black87 : Colors.grey,
                    fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (unreadCount > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatId: chatId,
                        otherUserName: userName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
