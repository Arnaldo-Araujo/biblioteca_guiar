import 'package:cloud_firestore/cloud_firestore.dart';

/// ==============================================================================
/// ARQUIVO: user_model.dart
/// OBJETIVO: Define a estrutura de dados do Usuário no aplicativo.
/// LÓGICA:
/// - Mapeia os documentos da coleção 'users' do Firestore.
/// - Contém métodos de serialização (toMap) e deserialização (fromMap, fromDocument).
/// - Inclui flags de role (isAdmin, isHelper) e status (isActive).
/// ==============================================================================
class UserModel {
  /// Identificador único (UID) vindo do Firebase Auth.
  final String uid;

  /// Nome completo do usuário.
  final String nome;

  /// E-mail de cadastro.
  final String email;

  /// Cadastro de Pessoa Física (Validado externamente).
  final String cpf;

  /// Telefone para contato.
  final String telefone;

  /// Endereço físico do usuário.
  final String endereco;

  /// Flag que indica privilégios de Administrador.
  final bool isAdmin;
  
  /// Flag que indica se o usuário é um "Ajudante" (pode receber chamados).
  final bool isHelper;

  /// Flag para "Soft Delete". Se false, o usuário está "desativado" mas não excluído.
  final bool isActive;

  /// URL da foto de perfil no Firebase Storage (pode ser null).
  final String? photoUrl;

  /// Construtor principal.
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

  /// Converte o objeto para um Map<String, dynamic>.
  /// Útil para salvar/atualizar dados no Firestore.
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

  /// Cria uma instância de UserModel a partir de um Map.
  /// Útil ao ler dados genéricos.
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

  /// Cria uma instância de UserModel a partir de um DocumentSnapshot do Firestore.
  /// Extrai o ID do documento para preencher o campo 'uid'.
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id, // O ID do doc é o UID do usuário
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

  /// Cria uma cópia da instância atual com alguns campos atualizados.
  /// Essencial para padrões de imutabilidade.
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
