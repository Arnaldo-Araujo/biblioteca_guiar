import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Send Message
  Future<void> sendMessage({
    required String text,
    required String chatId, // ID of the user (The Chat Room ID)
    required UserModel sender,
  }) async {
    final timestamp = Timestamp.now();

    // 1. Add message to subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': sender.uid,
      'text': text,
      'timestamp': timestamp,
      'isRead': false,
    });

    // 2. Update Chat Metadata (Inbox Item)
    final chatDocRef = _firestore.collection('chats').doc(chatId);
    
    final Map<String, dynamic> updateData = {
      'lastMessage': text,
      'lastMessageTime': timestamp,
      // Ensure user details are always up to date (useful if it's the first message)
      if (!sender.isAdmin) 'userName': sender.nome,
      if (!sender.isAdmin) 'userEmail': sender.email,
    };

    // Logic for unreadCount:
    // If the sender is the USER (not admin), we increment the unread count for the Admin.
    // If the sender is ADMIN, we don't increment (or we could handle logic for User unread, but focused on Admin Inbox).
    if (!sender.isAdmin) {
      updateData['unreadCount'] = FieldValue.increment(1);
    } 
    // If Admin sends, we might want to reset unreadCount? 
    // Usually unreadCount is reset when Admin OPENS the chat, not when they reply.
    // So we leave it as is or handle it in markAsRead.

    await chatDocRef.set(updateData, SetOptions(merge: true));
    notifyListeners();
  }

  // 2. Get Messages Stream
  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 3. Get Admin Inbox Stream
  Stream<QuerySnapshot> getAdminInboxStream() {
    return _firestore
        .collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // 4. Mark messages as read (Optional but good)
  Future<void> markChatAsRead(String chatId) async {
    // Reset unread count in the chat doc
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount': 0,
    });
    
    // Ideally we would also update all messages to isRead=true, 
    // but for simple Inbox count, the doc field is enough.
  }
}
