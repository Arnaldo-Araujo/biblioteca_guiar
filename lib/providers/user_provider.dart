import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Added
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

/// ==============================================================================
/// CLASSE: UserProvider
/// OBJETIVO: Gerenciar o estado global do Usuário e da Autenticação.
/// LÓGICA PRINCIPAL:
/// - Ouve alterações no estado do FirebaseAuth (Login/Logout).
/// - Busca e mantém o UserModel atualizado em memória.
/// - Fornece métodos para SignIn, SignUp (2 etapas), Update, Disable e Delete.
/// - Implementa regras de negócio como verificação de CPF único.
/// ==============================================================================
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
    // Escuta o stream de alterações de autenticação do Firebase.
    authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        final currentUid = user.uid;
        
        try {
          // 1. Busca dados do usuário no Firestore
          final userData = await _firestoreService.getUser(currentUid);
          
          // 2. VERIFICAÇÃO DE SEGURANÇA (Race Condition Check)
          // Garante que o usuário logado ainda é o mesmo antes de atualizar o estado.
          if (FirebaseAuth.instance.currentUser?.uid == currentUid) {
            _userModel = userData;
            notifyListeners();
          }
        } catch (e) {
             print("Erro ao buscar dados do usuário: $e");
        }
      } else {
        // Usuário deslogado: limpa o model.
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
  Future<void> completeRegistration({
    required UserModel userModel,
    File? imageFile, // <--- Novo Argumento
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) throw Exception('Usuário não autenticado.');

      String currentUid = authUser.uid;
      String? downloadUrl;

      // 1. Upload da Imagem (se houver)
      if (imageFile != null) {
        try {
          // O usuário pediu especificamente este caminho: 'user_photos/{uid}/profile.jpg'
          // E pediu para usar FirebaseStorage.instance.ref()...
          final ref = FirebaseStorage.instance
              .ref()
              .child('user_photos')
              .child(currentUid)
              .child('profile.jpg');
              
          await ref.putFile(imageFile);
          downloadUrl = await ref.getDownloadURL();
        } catch (e) {
          print("Erro no upload da imagem: $e");
          // Não trava o cadastro, mas avisa no log
        }
      }

      // 2. Atualiza o Model com a URL (se houve upload)
      UserModel finalUser = userModel.copyWith(
        uid: currentUid, // Garante o ID correto
        email: authUser.email ?? userModel.email,
        photoUrl: downloadUrl ?? userModel.photoUrl ?? '',
      );

      // 3. Validação de CPF (aquela lógica de rollback que já fizemos)
      final cpfQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('cpf', isEqualTo: finalUser.cpf)
          .get();

      if (cpfQuery.docs.isNotEmpty) {
         // ROLLBACK Crítico: Apagar o usuário Auth criado no passo 1
         await authUser.delete();
         throw Exception('CPF já cadastrado.'); // Usando Exception genérica conforme o bloco original (que lançava String) ou custom se existisse.
         // O user pediu CustomAuthException, mas não tenho a classe neste arquivo. Vou usar Exception com a string.
      }

      // 4. Salvar no Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .set(finalUser.toMap());

      _userModel = finalUser;

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

  Future<List<UserModel>> getHelpers() async {
    try {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('isAdmin', isEqualTo: true) // Simplification: assuming admins are helpers
          // Ideally we would use Filter.or if available or multiple queries, but let's start with this 
          // or check client side if index issues arise. 
          // The prompt says "isAdmin == true (or isHelper == true)".
          // Firestore OR queries (Filter.or) require recent SDKs.
          // Let's grab all users and filter client-side for simplicity and compatibility 
          // unless the user base is huge, which is unlikely for this app.
          // actually, let's try a direct query for isAdmin = true first.
          .get();

      // If we want both, we can't do a simple OR query without composite indexes usually.
      // Let's try fetching byisAdmin first.
      // If the requirement implies separates roles, I'll fetch both or filter.
      // Given the file content shows 'isHelper' in UserModel, I should check it.
      
      final admins = result.docs.map((doc) => UserModel.fromDocument(doc)).toList();
      
      // Let's also fetch isHelper if it's different. 
      // Safe bet: Fetch where isAdmin is true.
      // Then fetch where isHelper is true.
      // Combine and deduplicate.
      
      final QuerySnapshot resultHelpers = await FirebaseFirestore.instance
          .collection('users')
          .where('isHelper', isEqualTo: true)
          .get();
          
      final helpers = resultHelpers.docs.map((doc) => UserModel.fromDocument(doc)).toList();
      
      final all = [...admins, ...helpers];
      // Deduplicate by UID
      final uniqueParams = <String>{};
      final uniqueUsers = all.where((u) => uniqueParams.add(u.uid)).toList();
      
      return uniqueUsers;
    } catch (e) {
      print("Error fetching helpers: $e");
      return [];
    }
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

  /// Método B: Excluir Permanentemente (Hard Delete).
  /// Reautentica o usuário, exclui feedback, foto, doc do Firestore e conta Auth.
  Future<void> deleteAccountPermanently(String feedback, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não identificado.');

      // 1. REAUTENTICAÇÃO (Obrigatório)
      // Confirma identidade para operações sensíveis.
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. SALVAR FEEDBACK (Opcional)
      // Preserva o motivo da saída em uma coleção separada.
      try {
        await _firestoreService.saveDeletedUserFeedback(
          email: user.email ?? 'no-email',
          uid: user.uid,
          feedback: feedback,
        );
      } catch (e) {
        print("Erro ao salvar feedback: $e");
      }

      // 3. DELETAR FOTO DO STORAGE
      // Tenta remover a referência física do arquivo.
      if (_userModel?.photoUrl != null && _userModel!.photoUrl!.isNotEmpty) {
        try {
          if (_userModel!.photoUrl!.contains('firebase') || _userModel!.photoUrl!.contains('storage')) {
             await FirebaseStorage.instance.refFromURL(_userModel!.photoUrl!).delete();
             print("Foto de perfil deletada com sucesso.");
          }
        } catch (e) {
          print("Erro ao deletar foto (ou não existia): $e");
        }
      }

      // 4. DELETAR DOCUMENTO DO FIRESTORE
      print("--- EXCLUINDO DOC ---");
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      // 5. DELETAR AUTENTICAÇÃO
      // Remove o acesso a login.
      await user.delete();

      // Limpa estado local
      _userModel = null;
      notifyListeners();

    } catch (e) {
      print("Erro ao excluir conta: $e");
      rethrow;
    } finally {
      if (_isLoading) {
         _isLoading = false;
         notifyListeners();
      }
    }
  }

  void clearData() {
    _userModel = null;
    notifyListeners();
  }
}
