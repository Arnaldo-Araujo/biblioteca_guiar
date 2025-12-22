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

  /// Estado (UF) do usuário.
  final String? estado;
  
  /// Cidade/Distrito do usuário.
  final String? cidade;
  
  /// ID da igreja vinculada (pode ser null).
  final String? churchId;

  /// Papel do usuário no sistema (Role).
  /// Valores: 'SUPER_ADMIN', 'ADMIN', 'HELPER', 'USER'
  final String role;

  /// Getters de conveniência para manter compatibilidade e lógica limpa
  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isAdmin => role == 'ADMIN' || role == 'SUPER_ADMIN';
  bool get isHelper => role == 'HELPER';

  /// Construtor principal.
  UserModel({
    required this.uid,
    required this.nome,
    required this.email,
    required this.cpf,
    required this.telefone,
    required this.endereco,
    this.role = 'USER', // Default role
    this.isActive = true, // Default to true
    this.photoUrl,
    this.estado,
    this.cidade,
    this.churchId,
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
      'role': role,
      'isAdmin': isAdmin, // Persist for legacy/safety check if needed usually not needed but good for querying if indexes rely on it
      'isHelper': isHelper, // Persist for legacy
      'isActive': isActive,
      'photoUrl': photoUrl,
      'estado': estado,
      'cidade': cidade,
      'churchId': churchId,
    };
  }

  /// Cria uma instância de UserModel a partir de um Map.
  /// Útil ao ler dados genéricos.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Logic to migrate/infer role from legacy booleans if role doesn't exist
    String inferredRole = map['role'] ?? 'USER';
    
    // If role is undefined/USER but isAdmin is explicitly true (legacy data)
    if (map['role'] == null) {
      if (map['isAdmin'] == true) inferredRole = 'ADMIN';
      else if (map['isHelper'] == true) inferredRole = 'HELPER';
    }

    return UserModel(
      uid: map['uid'] ?? '',
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      cpf: map['cpf'] ?? '',
      telefone: map['telefone'] ?? '',
      endereco: map['endereco'] ?? '',
      role: inferredRole,
      isActive: map['isActive'] ?? true, // Default true for existing docs
      photoUrl: map['photoUrl'],
      estado: map['estado'],
      cidade: map['cidade'],
      churchId: map['churchId'],
    );
  }

  /// Cria uma instância de UserModel a partir de um DocumentSnapshot do Firestore.
  /// Extrai o ID do documento para preencher o campo 'uid'.
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Logic to migrate/infer role
    String inferredRole = data['role'] ?? 'USER';
    if (data['role'] == null) {
      if (data['isAdmin'] == true) inferredRole = 'ADMIN';
      else if (data['isHelper'] == true) inferredRole = 'HELPER';
    }

    return UserModel(
      uid: doc.id, // O ID do doc é o UID do usuário
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      cpf: data['cpf'] ?? '',
      telefone: data['telefone'] ?? '',
      endereco: data['endereco'] ?? '',
      role: inferredRole,
      isActive: data['isActive'] ?? true, // Default true
      photoUrl: data['photoUrl'],
      estado: data['estado'],
      cidade: data['cidade'],
      churchId: data['churchId'],
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
    String? role,
    bool? isActive,
    String? photoUrl,
    String? estado,
    String? cidade,
    String? churchId,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      cpf: cpf ?? this.cpf,
      telefone: telefone ?? this.telefone,
      endereco: endereco ?? this.endereco,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      photoUrl: photoUrl ?? this.photoUrl,
      estado: estado ?? this.estado,
      cidade: cidade ?? this.cidade,
      churchId: churchId ?? this.churchId,
    );
  }
}
