import 'package:flutter/material.dart';
import '../models/loan_model.dart';
import '../services/firestore_service.dart';

class LoanProvider with ChangeNotifier {
  final FirestoreService _firestoreService;

  LoanProvider({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Stream<List<LoanModel>> getUserLoans(String uid) {
    return _firestoreService.getUserLoans(uid);
  }

  Stream<List<LoanModel>> getAllLoans() {
    return _firestoreService.getAllLoans();
  }

  Future<void> reserveBook(LoanModel loan) async {
    await _firestoreService.reserveBook(loan);
  }

  Future<void> activateLoan(String loanId, String bookId) async {
    await _firestoreService.activateLoan(loanId, bookId);
  }

  Future<void> returnBook(String loanId, String bookId) async {
    await _firestoreService.returnBook(loanId, bookId);
  }

  Future<void> renewLoan(String loanId, DateTime newDate) async {
    await _firestoreService.renewLoan(loanId, newDate);
  }
}
