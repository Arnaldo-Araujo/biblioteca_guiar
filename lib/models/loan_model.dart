import 'package:cloud_firestore/cloud_firestore.dart';

class LoanModel {
  final String id;
  final String userId;
  final String bookId;
  final String bookTitle;
  final String userName;
  final DateTime dataEmprestimo;
  final DateTime dataPrevistaDevolucao;
  final DateTime? dataDevolucaoReal;
  final String status; // 'ativo', 'devolvido'

  LoanModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.bookTitle,
    required this.userName,
    required this.dataEmprestimo,
    required this.dataPrevistaDevolucao,
    this.dataDevolucaoReal,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'userName': userName,
      'dataEmprestimo': Timestamp.fromDate(dataEmprestimo),
      'dataPrevistaDevolucao': Timestamp.fromDate(dataPrevistaDevolucao),
      'dataDevolucaoReal': dataDevolucaoReal != null ? Timestamp.fromDate(dataDevolucaoReal!) : null,
      'status': status,
    };
  }

  factory LoanModel.fromMap(Map<String, dynamic> map, String documentId) {
    return LoanModel(
      id: documentId,
      userId: map['userId'] ?? '',
      bookId: map['bookId'] ?? '',
      bookTitle: map['bookTitle'] ?? '',
      userName: map['userName'] ?? '',
      dataEmprestimo: (map['dataEmprestimo'] as Timestamp).toDate(),
      dataPrevistaDevolucao: (map['dataPrevistaDevolucao'] as Timestamp).toDate(),
      dataDevolucaoReal: map['dataDevolucaoReal'] != null ? (map['dataDevolucaoReal'] as Timestamp).toDate() : null,
      status: map['status'] ?? 'ativo',
    );
  }
}
