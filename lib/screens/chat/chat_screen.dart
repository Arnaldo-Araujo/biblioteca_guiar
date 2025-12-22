import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Mark as read when entering (if Admin)
    final user = Provider.of<UserProvider>(context, listen: false).userModel;
    if (user != null && user.isAdmin) {
      Provider.of<ChatProvider>(context, listen: false).markChatAsRead(widget.chatId);
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final user = userProvider.userModel;

    if (user == null) return;

    _messageController.clear();
    
    try {
      await chatProvider.sendMessage(
        text: text,
        chatId: widget.chatId,
        sender: user,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar mensagem: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final currentUser = userProvider.userModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatProvider.getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Sem mensagens ainda. Comece a conversa!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                final messages = docs.map((doc) => MessageModel.fromDocument(doc)).toList();

                return ListView.builder(
                  reverse: true, // Show newest at button
                  itemCount: messages.length,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUser?.uid;

                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    final timeStr = DateFormat('HH:mm').format(msg.timestamp.toDate());

    // Dark Mode Contrast Fixes
    // Sent: Dark Green, Received: Dark Grey (Charcoal)
    final bubbleColor = isMe 
        ? const Color(0xFF1B5E20) // Dark Green (Green 900)
        : const Color(0xFF37474F); // Dark Blue Grey (Blue Grey 800)

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white, // Ensure white text for contrast
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70, // Slightly transparent white for time
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(10),
      // Use surface color or a dark neutral for dark mode
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Digite sua mensagem...',
                hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                // input background
                fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).primaryColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
