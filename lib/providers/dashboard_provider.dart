import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loan_model.dart';
import '../models/book_model.dart';

class DashboardProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Summary Cards
  int totalBooks = 0;
  int totalUsers = 0;
  int totalActiveLoans = 0;

  // Pie Chart Data
  int onTimeLoans = 0;
  int overdueLoans = 0;
  int reservedLoans = 0;

  // Bar Chart Data
  Map<String, int> categoryLoanCounts = {};
  int maxCategoryCount = 0;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Summary Counts
      final booksSnapshot = await _db.collection('books').count().get();
      totalBooks = booksSnapshot.count ?? 0;

      final usersSnapshot = await _db.collection('users').count().get();
      totalUsers = usersSnapshot.count ?? 0;

      // 2. Fetch All Loans for Analysis
      final loansSnapshot = await _db.collection('loans').get();
      final loans = loansSnapshot.docs.map((doc) => LoanModel.fromMap(doc.data(), doc.id)).toList();

      _calculateLoanStats(loans);
      await _calculateCategoryStats(loans);

    } catch (e) {
      print('Erro ao carregar dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateLoanStats(List<LoanModel> loans) {
    onTimeLoans = 0;
    overdueLoans = 0;
    reservedLoans = 0;
    totalActiveLoans = 0;

    final now = DateTime.now();

    for (var loan in loans) {
      if (loan.status == 'reservado') {
        reservedLoans++;
      } else if (loan.status == 'ativo') {
        totalActiveLoans++;
        if (now.isAfter(loan.dataPrevistaDevolucao)) {
          overdueLoans++;
        } else {
          onTimeLoans++;
        }
      }
    }
  }

  Future<void> _calculateCategoryStats(List<LoanModel> loans) async {
    categoryLoanCounts.clear();
    maxCategoryCount = 0;

    // We need book details to get categories. 
    // Optimization: Fetch all books once or fetch individually if list is small.
    // For dashboard, fetching all books is acceptable if dataset isn't huge.
    // Alternatively, we could store category in LoanModel, but that requires schema change.
    // Let's fetch all books for now to map IDs.
    
    final booksSnapshot = await _db.collection('books').get();
    final booksMap = {for (var doc in booksSnapshot.docs) doc.id: BookModel.fromMap(doc.data(), doc.id)};

    for (var loan in loans) {
      final book = booksMap[loan.bookId];
      if (book != null && book.categoria.isNotEmpty) {
        // Normalize category
        final category = book.categoria.trim();
        categoryLoanCounts[category] = (categoryLoanCounts[category] ?? 0) + 1;
      }
    }

    // Sort and keep top 5
    var sortedEntries = categoryLoanCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sortedEntries.length > 5) {
      sortedEntries = sortedEntries.sublist(0, 5);
    }

    categoryLoanCounts = Map.fromEntries(sortedEntries);
    
    if (categoryLoanCounts.isNotEmpty) {
      maxCategoryCount = categoryLoanCounts.values.reduce((a, b) => a > b ? a : b);
    }
  }
}
