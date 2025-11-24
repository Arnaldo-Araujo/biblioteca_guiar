import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserProvider() {
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

  Future<void> signUp(String email, String password, UserModel user) async {
    _isLoading = true;
    notifyListeners();
    try {
      await authService.signUp(email, password, user);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await authService.signOut();
    _userModel = null;
    notifyListeners();
  }
}
