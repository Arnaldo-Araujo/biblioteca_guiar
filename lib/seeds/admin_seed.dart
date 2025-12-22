import 'package:cloud_firestore/cloud_firestore.dart';

/// Script de Seed para promover um usuário a SUPER_ADMIN.
/// Uso: Chame esta função em algum lugar seguro (ex: um botão secreto ou console de debug)
/// passando o e-mail do seu usuário.
Future<void> seedSuperAdmin(String email) async {
  print("--- SEED: Iniciando promoção de Super Admin para: $email ---");

  try {
    final QuerySnapshot query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      print("--- SEED ERRO: Usuário com e-mail $email não encontrado.");
      return;
    }

    final DocumentSnapshot userDoc = query.docs.first;
    
    await userDoc.reference.update({
      'role': 'SUPER_ADMIN',
      'isAdmin': true, // Mantém compatibilidade
    });

    print("--- SEED SUCESSO: Usuário $email agora é SUPER_ADMIN. ---");
  } catch (e) {
    print("--- SEED ERRO: Falha ao atualizar usuário: $e ---");
  }
}
