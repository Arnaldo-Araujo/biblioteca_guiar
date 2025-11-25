import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

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

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await authService.signIn(email, password);
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
}
