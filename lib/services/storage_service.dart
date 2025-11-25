import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadBookCover(File file, String fileName) async {
    try {
      Reference ref = _storage.ref().child('book_covers/$fileName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadUserPhoto(File file, String uid) async {
    try {
      Reference ref = _storage.ref().child('user_profiles/$uid');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteUserPhoto(String uid) async {
    try {
      Reference ref = _storage.ref().child('user_profiles/$uid');
      await ref.delete();
    } catch (e) {
      // Ignore if file doesn't exist
    }
  }

  Future<void> deleteBookCover(String fileName) async {
    try {
      Reference ref = _storage.ref().child('book_covers/$fileName');
      await ref.delete();
    } catch (e) {
      // Ignore if file doesn't exist
    }
  }
}
