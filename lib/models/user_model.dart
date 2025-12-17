import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nome;
  final String email;
  final String cpf;
  final String telefone;
  final String endereco;
  final bool isAdmin;
  final bool isHelper;
  final bool isActive; // New field
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.nome,
    required this.email,
    required this.cpf,
    required this.telefone,
    required this.endereco,
    required this.isAdmin,
    this.isHelper = false,
    this.isActive = true, // Default to true
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'telefone': telefone,
      'endereco': endereco,
      'isAdmin': isAdmin,
      'isHelper': isHelper,
      'isActive': isActive,
      'photoUrl': photoUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      cpf: map['cpf'] ?? '',
      telefone: map['telefone'] ?? '',
      endereco: map['endereco'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      isHelper: map['isHelper'] ?? false,
      isActive: map['isActive'] ?? true, // Default true for existing docs
      photoUrl: map['photoUrl'],
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      cpf: data['cpf'] ?? '',
      telefone: data['telefone'] ?? '',
      endereco: data['endereco'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      isHelper: data['isHelper'] ?? false,
      isActive: data['isActive'] ?? true, // Default true
      photoUrl: data['photoUrl'],
    );
  }

  UserModel copyWith({
    String? uid,
    String? nome,
    String? email,
    String? cpf,
    String? telefone,
    String? endereco,
    bool? isAdmin,
    bool? isHelper,
    bool? isActive,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      cpf: cpf ?? this.cpf,
      telefone: telefone ?? this.telefone,
      endereco: endereco ?? this.endereco,
      isAdmin: isAdmin ?? this.isAdmin,
      isHelper: isHelper ?? this.isHelper,
      isActive: isActive ?? this.isActive,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
