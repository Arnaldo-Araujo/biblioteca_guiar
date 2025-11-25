import 'dart:io';
import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class BookProvider with ChangeNotifier {
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  BookProvider({FirestoreService? firestoreService, StorageService? storageService})
      : _firestoreService = firestoreService ?? FirestoreService(),
        _storageService = storageService ?? StorageService();

  Stream<List<BookModel>> get booksStream => _firestoreService.getBooks();

  Stream<List<BookModel>> getBooksStream({bool showInactive = false}) {
    return _firestoreService.getBooks(showInactive: showInactive);
  }

  Future<void> addBook(BookModel book, File? imageFile) async {
    try {
      String imageUrl = book.imageUrl;
      if (imageFile != null) {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await _storageService.uploadBookCover(imageFile, fileName);
      }

      BookModel newBook = BookModel(
        id: '', // Firestore generates ID
        titulo: book.titulo,
        autor: book.autor,
        isbn: book.isbn,
        categoria: book.categoria,
        sinopse: book.sinopse,
        quantidadeDisponivel: book.quantidadeDisponivel,
        imageUrl: imageUrl,
      );


      await _firestoreService.addBook(newBook);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBook(BookModel book, File? imageFile) async {
    try {
      String imageUrl = book.imageUrl;
      if (imageFile != null) {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await _storageService.uploadBookCover(imageFile, fileName);
      }

      BookModel updatedBook = BookModel(
        id: book.id,
        titulo: book.titulo,
        autor: book.autor,
        isbn: book.isbn,
        categoria: book.categoria,
        sinopse: book.sinopse,
        quantidadeDisponivel: book.quantidadeDisponivel,
        imageUrl: imageUrl,
      );


      await _firestoreService.updateBook(updatedBook);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBook(String bookId) async {
    try {
      // Check if book has any loans (active or historical)
      bool hasLoans = await _firestoreService.checkBookHasLoans(bookId);
      
      if (hasLoans) {
        // Soft delete: book has loan history
        await _firestoreService.softDeleteBook(bookId);
      } else {
        // Hard delete: book never loaned, safe to remove completely
        await _firestoreService.deleteBook(bookId);
      }
    } catch (e) {
      rethrow;
    }
  }
}
