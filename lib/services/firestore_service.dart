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
      return UserModel.fromDocument(doc);
    }
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    QuerySnapshot snapshot = await _db.collection('users').get();
    return snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
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
  Future<void> reserveBook(LoanModel loan) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      // Create reservation
      // Status 'reservado', NO stock update
      DocumentReference loanRef = _db.collection('loans').doc(); // Auto-ID
      
      final loanData = loan.toMap();
      loanData['userId'] = user.uid; // Must match auth.uid
      loanData['status'] = 'reservado'; // Initial status
      loanData['dataEmprestimo'] = Timestamp.now(); // Reservation date

      await loanRef.set(loanData);
    } on FirebaseException catch (e) {
      print('Erro Firebase: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception('Erro de permissão: Verifique se você já tem reservas ativas.');
      }
      rethrow;
    } catch (e) {
      print('Erro ao realizar reserva: $e');
      rethrow;
    }
  }

  Future<void> activateLoan(String loanId, String bookId, int days) async {
    try {
      WriteBatch batch = _db.batch();

      DocumentReference bookRef = _db.collection('books').doc(bookId);
      DocumentReference loanRef = _db.collection('loans').doc(loanId);

      // Decrement book quantity atomically
      batch.update(bookRef, {'quantidadeDisponivel': FieldValue.increment(-1)});

      // Calculate return date
      final returnDate = DateTime.now().add(Duration(days: days));

      // Update loan status to active
      batch.update(loanRef, {
        'status': 'ativo',
        'dataEmprestimo': Timestamp.now(), // Update to actual loan date
        'dataPrevistaDevolucao': Timestamp.fromDate(returnDate),
      });

      await batch.commit();
    } catch (e) {
      print('Erro ao ativar empréstimo: $e');
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

  Future<void> renewLoan(String loanId, int days) async {
    final newDate = DateTime.now().add(Duration(days: days));
    await _db.collection('loans').doc(loanId).update({
      'dataPrevistaDevolucao': Timestamp.fromDate(newDate),
      'renovationsCount': FieldValue.increment(1),
    });
  }

  Stream<List<LoanModel>> getUserLoans() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    
    return _db.collection('loans')
        .where('userId', isEqualTo: uid)
        .orderBy('dataEmprestimo', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => LoanModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<LoanModel>> getAllLoans() {
    return _db.collection('loans')
        .orderBy('dataEmprestimo', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => LoanModel.fromMap(doc.data(), doc.id)).toList());
  }
  Stream<List<UserModel>> getAllUsersStream() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
    });
  }

  Stream<List<LoanModel>> getLoansByUserId(String uid) {
    return _db.collection('loans')
        .where('userId', isEqualTo: uid)
        .orderBy('dataEmprestimo', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => LoanModel.fromMap(doc.data(), doc.id)).toList());
  }
}
