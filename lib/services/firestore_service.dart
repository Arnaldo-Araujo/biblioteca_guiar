import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/book_model.dart';
import '../models/loan_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Users
  Future<UserModel?> getUser(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    QuerySnapshot snapshot = await _db.collection('users').get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
  }

  // Books
  Stream<List<BookModel>> getBooks({bool showInactive = false}) {
    return _db.collection('books').snapshots().map((snapshot) {
      final books = snapshot.docs.map((doc) => BookModel.fromMap(doc.data(), doc.id)).toList();
      if (showInactive) {
        return books;
      }
      return books.where((book) => book.isActive).toList();
    });
  }

  Future<void> addBook(BookModel book) async {
    await _db.collection('books').add(book.toMap());
  }

  Future<void> updateBook(BookModel book) async {
    await _db.collection('books').doc(book.id).update(book.toMap());
  }

  Future<bool> checkBookHasLoans(String bookId) async {
    QuerySnapshot snapshot = await _db.collection('loans')
        .where('bookId', isEqualTo: bookId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> softDeleteBook(String bookId) async {
    await _db.collection('books').doc(bookId).update({'isActive': false});
  }

  Future<void> deleteBook(String bookId) async {
    await _db.collection('books').doc(bookId).delete();
  }

  // Loans
  Future<void> loanBook(LoanModel loan) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      WriteBatch batch = _db.batch();

      DocumentReference bookRef = _db.collection('books').doc(loan.bookId);
      DocumentReference loanRef = _db.collection('loans').doc(); // Auto-ID

      // Decrement book quantity atomically
      // CRITICAL: Only update 'quantidadeDisponivel' to comply with security rules
      batch.update(bookRef, {'quantidadeDisponivel': FieldValue.increment(-1)});

      // Create loan
      // Enforce userId and status to match security rules
      final loanData = loan.toMap();
      loanData['userId'] = user.uid; // Must match auth.uid
      loanData['status'] = 'ativo'; // Must be 'ativo'

      batch.set(loanRef, loanData);

      await batch.commit();
    } on FirebaseException catch (e) {
      print('Erro Firebase: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception('Erro de permissão: Verifique se você já tem empréstimos ou contate o suporte.');
      }
      rethrow;
    } catch (e) {
      print('Erro ao realizar empréstimo: $e');
      rethrow;
    }
  }

  Future<void> returnBook(String loanId, String bookId) async {
    await _db.runTransaction((transaction) async {
      DocumentReference bookRef = _db.collection('books').doc(bookId);
      DocumentSnapshot bookSnapshot = await transaction.get(bookRef);
      
      DocumentReference loanRef = _db.collection('loans').doc(loanId);

      if (bookSnapshot.exists) {
        int currentQuantity = bookSnapshot.get('quantidadeDisponivel');
        transaction.update(bookRef, {'quantidadeDisponivel': currentQuantity + 1});
      }

      transaction.update(loanRef, {
        'status': 'devolvido',
        'dataDevolucaoReal': Timestamp.now(),
      });
    });
  }

  Future<void> renewLoan(String loanId, DateTime newDate) async {
    await _db.collection('loans').doc(loanId).update({
      'dataPrevistaDevolucao': Timestamp.fromDate(newDate),
    });
  }

  Stream<List<LoanModel>> getUserLoans(String uid) {
    return _db.collection('loans')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => LoanModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<LoanModel>> getAllLoans() {
    return _db.collection('loans')
        .orderBy('dataEmprestimo', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => LoanModel.fromMap(doc.data(), doc.id)).toList());
  }
}
