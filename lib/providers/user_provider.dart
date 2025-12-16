import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService authService;
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserProvider({AuthService? authService, FirestoreService? firestoreService, StorageService? storageService})
      : authService = authService ?? AuthService(),
        _firestoreService = firestoreService ?? FirestoreService(),
        _storageService = storageService ?? StorageService() {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        final currentUid = user.uid;
        
        try {
          // Busca dados do Firestore sem travar o listener se falhar
          final userData = await _firestoreService.getUser(currentUid);
          
          // VERIFICAÇÃO DE SEGURANÇA (Race Condition Check)
          // Só atualiza o model se o usuário logado AINDA for o mesmo que pediu os dados
          // Aqui usamos FirebaseAuth.instance.currentUser ou a instância exposta pelo AuthService se acessível.
          // Como AuthService é um wrapper, e provavelmente não expõe o currentUser diretamente como propriedade pública mutável além do stream,
          // o mais seguro é verificar se 'user.uid' ainda bate com o uid do evento, mas o evento 'user' é snapshot.
          // Precisamos saber se o "estado atual do auth" mudou.
          // O ideal é checar FirebaseAuth.instance.currentUser.uid, mas vamos usar o user.uid capturado versus o que o authService reportaria agora.
          // Se o authService expõe currentUser, usamos ele. Se não, usamos FirebaseAuth.instance.
          
          if (FirebaseAuth.instance.currentUser?.uid == currentUid) {
            _userModel = userData;
            notifyListeners();
          }
        } catch (e) {
             print("Erro ao buscar dados do usuário: $e");
        }
      } else {
        _userModel = null;
        notifyListeners();
      }
    });
  }

  String _tratarErroAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'E-mail não encontrado. Verifique se digitou corretamente ou crie uma conta.';
      case 'wrong-password':
        return 'A senha está incorreta. Tente novamente.';
      case 'invalid-email':
        return 'O formato do e-mail digitado é inválido.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado em outra conta.';
      case 'weak-password':
        return 'A senha é muito fraca. Escolha uma senha com pelo menos 6 caracteres.';
      case 'operation-not-allowed':
        return 'O login com e-mail e senha não está habilitado.';
      case 'user-disabled':
        return 'Este usuário foi desativado. Entre em contato com a administração.';
      case 'too-many-requests':
        return 'Muitas tentativas falhas. Aguarde alguns minutos para tentar novamente.';
      case 'network-request-failed':
        return 'Parece que você está sem internet. Verifique sua conexão.';
      default:
        return 'Ocorreu um erro inesperado. Tente novamente mais tarde.';
    }
  }

  Future<void> signIn(String email, String password) async {
    print("--- PROVIDER: Iniciando signIn com $email ---");
    _isLoading = true;
    notifyListeners();
    try {
      print("--- PROVIDER: Chamando Firebase Auth... ---");
      // Importante: capture o resultado para logar
      final result = await authService.signIn(email, password);
      print("--- PROVIDER: Firebase respondeu Sucesso! UID: ${result?.uid} ---"); // Ajuste conforme o retorno do seu authService (User? ou UserCredential)
    } catch (e) {
      print("--- PROVIDER: Erro capturado: $e ---");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método 1: Apenas cria o usuário no Auth (Tela 1)
  Future<void> registerAuthOnly(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Sucesso: O usuário está logado, mas sem dados no Firestore ainda.
    } on FirebaseAuthException catch (e) {
      throw _tratarErroAuth(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método 2: Completa o cadastro no Firestore (Tela 2)
  Future<void> completeRegistration(UserModel user, File? imageFile) async {
    _isLoading = true;
    notifyListeners();

    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) throw Exception('Usuário não autenticado.');

      // 1. Validação de CPF (Query direta para obter dados se existir)
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('cpf', isEqualTo: user.cpf)
          .get();

      if (result.docs.isNotEmpty) {
        // CENÁRIO A: CPF Duplicado
        final doc = result.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final existingEmail = data['email'] ?? 'email desconhecido';
        final maskedEmail = _maskEmail(existingEmail);

        // ROLLBACK Crítico: Apagar o usuário Auth criado no passo 1
        await authUser.delete();

        throw Exception("Este CPF já possui cadastro vinculado ao e-mail: $maskedEmail");
      }

      // CENÁRIO B: Sucesso - Processar imagem e salvar
      String photoUrl = '';
      if (imageFile != null) {
        photoUrl = await _storageService.uploadUserPhoto(imageFile, authUser.uid);
      }

      // Monta o model final
      UserModel newUser = UserModel(
        uid: authUser.uid,
        nome: user.nome,
        email: authUser.email ?? user.email,
        cpf: user.cpf,
        telefone: user.telefone,
        endereco: user.endereco,
        isAdmin: false,
        isHelper: false,
        photoUrl: photoUrl.isNotEmpty ? photoUrl : user.photoUrl,
      );

      // Salva usando o método seguro
      await _firestoreService.saveUser(newUser);

      // Atualiza estado local
      _userModel = newUser;

    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _maskEmail(String email) {
    if (email.length <= 4) return email;
    final parts = email.split('@');
    if (parts.length != 2) return email;
    
    final name = parts[0];
    final domain = parts[1];
    
    final visibleName = name.length > 2 ? name.substring(0, 2) : name;
    return "$visibleName***@$domain";
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await authService.sendPasswordResetEmail(email);
  }

  Future<void> signOut() async {
    await authService.signOut();
    _userModel = null;
    notifyListeners();
  }

  Future<List<UserModel>> getAllUsers() {
    return _firestoreService.getAllUsers();
  }

  Future<void> updateUser(UserModel user) async {
    await _firestoreService.updateUser(user);
    notifyListeners();
  }

  Future<void> updateProfilePhoto(File imageFile) async {
    if (_userModel == null) return;
    
    try {
      // 1. Upload new photo (overwrites existing due to fixed path)
      String photoUrl = await _storageService.uploadUserPhoto(imageFile, _userModel!.uid);
      
      // 2. Update User Model
      UserModel updatedUser = UserModel(
        uid: _userModel!.uid,
        nome: _userModel!.nome,
        email: _userModel!.email,
        cpf: _userModel!.cpf,
        telefone: _userModel!.telefone,
        endereco: _userModel!.endereco,
        isAdmin: _userModel!.isAdmin,
        isHelper: _userModel!.isHelper,
        photoUrl: photoUrl,
      );
      
      // 3. Update Firestore
      await _firestoreService.updateUser(updatedUser);
      
      // 4. Update Local State
      _userModel = updatedUser;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile(UserModel updatedUser, File? imageFile) async {
    _isLoading = true;
    notifyListeners();
    try {
      String photoUrl = updatedUser.photoUrl ?? '';
      
      if (imageFile != null) {
        photoUrl = await _storageService.uploadUserPhoto(imageFile, updatedUser.uid);
      }

      final userToSave = UserModel(
        uid: updatedUser.uid,
        nome: updatedUser.nome,
        email: updatedUser.email,
        cpf: updatedUser.cpf,
        telefone: updatedUser.telefone,
        endereco: updatedUser.endereco,
        isAdmin: updatedUser.isAdmin,
        isHelper: updatedUser.isHelper,
        photoUrl: photoUrl,
      );

      await _firestoreService.updateUser(userToSave);
      _userModel = userToSave;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();
    try {
      await authService.changePassword(currentPassword, newPassword);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método A: Desativar Conta (Soft Delete)
  Future<void> disableAccount(String feedback) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _userModel == null) throw Exception('Usuário não identificado.');

      // 1. Salvar feedback
      await _firestoreService.saveUserFeedback(
        uid: user.uid,
        feedback: feedback,
        type: 'soft_delete',
      );

      // 2. Desativar Soft Delete
      await _firestoreService.softDeleteUser(user.uid, _userModel!.isAdmin);

      // 3. Logout
      await signOut();

    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método B: Excluir Permanentemente (Hard Delete)
  Future<void> deleteAccountPermanently(String feedback, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _userModel == null) throw Exception('Usuário não identificado.');

      // Passo 0: Reautenticação (Segurança)
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Passo 1: Salvar Feedback (Histórico externo)
      await _firestoreService.saveDeletedUserFeedback(
        email: user.email ?? 'no-email',
        uid: user.uid,
        feedback: feedback,
      );

      // Passo 2: Limpar Storage (Foto)
      if (_userModel!.photoUrl != null && _userModel!.photoUrl!.isNotEmpty) {
        await _storageService.deleteUserPhoto(user.uid);
      }

      // Passo 3: Limpar Firestore (Doc do usuário)
      // Nota: As regras de segurança devem permitir delete para o próprio user
      await _firestoreService.deleteUserDoc(user.uid);

      // Passo 4: Limpar Auth
      await user.delete();

      // Limpa estado local
      _userModel = null;

    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Senha incorreta.');
      }
      throw _tratarErroAuth(e);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    _userModel = null;
    notifyListeners();
  }
}
