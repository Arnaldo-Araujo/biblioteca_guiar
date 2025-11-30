import 'package:flutter/material.dart';
import '../models/loan_model.dart';
import '../services/firestore_service.dart';

class LoanProvider with ChangeNotifier {
  final FirestoreService _firestoreService;

  LoanProvider({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Stream<List<LoanModel>> fetchUserLoans(String uid) {
    return _firestoreService.getUserLoans();
  }

  Stream<List<LoanModel>> getUserLoans() {
    return _firestoreService.getUserLoans();
  }

  Stream<List<LoanModel>> getAllLoans() {
    return _firestoreService.getAllLoans();
  }

  Future<void> reserveBook(LoanModel loan) async {
    await _firestoreService.reserveBook(loan);
  }

  Future<void> activateLoan(String loanId, String bookId, int days) async {
    await _firestoreService.activateLoan(loanId, bookId, days);
  }

  Future<void> returnBook(String loanId, String bookId) async {
    await _firestoreService.returnBook(loanId, bookId);
  }

  Future<void> renewLoan(String loanId, int days) async {
    await _firestoreService.renewLoan(loanId, days);
  }
  void clearData() {
    // Reset any local state if added in future
    notifyListeners();
  }
}
