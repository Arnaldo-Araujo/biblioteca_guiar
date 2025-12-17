import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this imports for Timestamp/QuerySnapshot
import 'package:intl/intl.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart'; // Added
import '../../models/user_model.dart'; // Added
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
              final String? assignedToName = data['assignedToName']; // Added

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

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unreadCount > 0 ? Colors.black87 : Colors.grey,
                        fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    assignedToName != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Text(
                              'Responsável: $assignedToName',
                              style: TextStyle(fontSize: 10, color: Colors.blue[800]),
                            ),
                          )
                        : Text(
                            'Não atribuído',
                            style: TextStyle(fontSize: 10, color: Colors.orange[800]),
                          ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.blueGrey),
                      onPressed: () => _showHelpersModal(context, chatId),
                      tooltip: 'Atribuir responsável',
                    ),
                    Column(
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


  void _showHelpersModal(BuildContext context, String chatId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Atribuir Conversa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<UserModel>>(
                  future: Provider.of<UserProvider>(context, listen: false).getHelpers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Erro ao carregar lista.'));
                    }
                    final helpers = snapshot.data ?? [];
                    if (helpers.isEmpty) {
                      return const Center(child: Text('Nenhum atendente encontrado.'));
                    }
                    return ListView.builder(
                      itemCount: helpers.length,
                      itemBuilder: (ctx, i) {
                        final helper = helpers[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: helper.photoUrl != null && helper.photoUrl!.isNotEmpty
                                ? NetworkImage(helper.photoUrl!)
                                : null,
                            child: helper.photoUrl == null || helper.photoUrl!.isEmpty
                                ? Text(helper.nome[0].toUpperCase())
                                : null,
                          ),
                          title: Text(helper.nome),
                          subtitle: Text(helper.isAdmin ? 'Admin' : 'Helper'),
                          onTap: () async {
                            try {
                              await Provider.of<ChatProvider>(context, listen: false)
                                  .assignAttendant(chatId, helper);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Atribuído a ${helper.nome}'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Erro ao atribuir.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
