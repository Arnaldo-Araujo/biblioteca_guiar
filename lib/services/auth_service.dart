import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signUp(String email, String password, UserModel userModel) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // Inject UID into model before saving
        UserModel newUser = UserModel(
          uid: user.uid,
          nome: userModel.nome,
          email: userModel.email,
          cpf: userModel.cpf,
          telefone: userModel.telefone,
          endereco: userModel.endereco,
          isAdmin: userModel.isAdmin,
          isHelper: userModel.isHelper,
          photoUrl: userModel.photoUrl,
        );

        // Save extra user data to Firestore
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('A senha atual informada está incorreta.');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
