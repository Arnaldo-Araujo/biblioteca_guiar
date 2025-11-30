import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/firestore_service.dart';
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
        _userModel = await _firestoreService.getUser(user.uid);
      } else {
        _userModel = null;
      }
      notifyListeners();
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
    _isLoading = true;
    notifyListeners();
    try {
      await authService.signIn(email, password);
      // Update FCM Token on Login
      await NotificationService().getToken();
    } on FirebaseAuthException catch (e) {
      throw _tratarErroAuth(e);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, UserModel user, File? imageFile) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Create Auth User & Initial Firestore Doc
      User? authUser = await authService.signUp(email, password, user);
      
      if (authUser != null && imageFile != null) {
        // 2. Upload Photo if selected
        String photoUrl = await _storageService.uploadUserPhoto(imageFile, authUser.uid);
        
        // 3. Update User Model with Photo URL
        UserModel updatedUser = UserModel(
          uid: authUser.uid,
          nome: user.nome,
          email: user.email,
          cpf: user.cpf,
          telefone: user.telefone,
          endereco: user.endereco,
          isAdmin: user.isAdmin,
          isHelper: user.isHelper,
          photoUrl: photoUrl,
        );
        
        // 4. Update Firestore
        await _firestoreService.updateUser(updatedUser);
        
        // 5. Update Local State
        _userModel = updatedUser;
      }
    } on FirebaseAuthException catch (e) {
      throw _tratarErroAuth(e);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  void clearData() {
    _userModel = null;
    notifyListeners();
  }
}
