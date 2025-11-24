import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Books
  Stream<List<BookModel>> getBooks() {
    return _db.collection('books').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BookModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addBook(BookModel book) async {
    await _db.collection('books').add(book.toMap());
  }

  Future<void> updateBook(BookModel book) async {
    await _db.collection('books').doc(book.id).update(book.toMap());
  }

  // Loans
  Future<void> loanBook(LoanModel loan) async {
    // Transaction to ensure atomic update of book quantity and loan creation
    await _db.runTransaction((transaction) async {
      DocumentReference bookRef = _db.collection('books').doc(loan.bookId);
      DocumentSnapshot bookSnapshot = await transaction.get(bookRef);

      if (!bookSnapshot.exists) {
        throw Exception("Livro não encontrado!");
      }

      int currentQuantity = bookSnapshot.get('quantidadeDisponivel');
      if (currentQuantity <= 0) {
        throw Exception("Livro indisponível!");
      }

      transaction.update(bookRef, {'quantidadeDisponivel': currentQuantity - 1});
      
      DocumentReference loanRef = _db.collection('loans').doc(); // Auto-ID
      transaction.set(loanRef, loan.toMap());
    });
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
