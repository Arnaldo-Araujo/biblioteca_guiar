class UserModel {
  final String uid;
  final String nome;
  final String email;
  final String cpf;
  final String telefone;
  final String endereco;
  final bool isAdmin;

  UserModel({
    required this.uid,
    required this.nome,
    required this.email,
    required this.cpf,
    required this.telefone,
    required this.endereco,
    required this.isAdmin,
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
    );
  }
}
