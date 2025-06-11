import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;
  String? _userEmail;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  bool get isLoading => _isLoading;

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // This will be replaced with Firebase Auth
      await Future.delayed(const Duration(seconds: 1));
      _isAuthenticated = true;
      _userId = "sample_user_id";
      _userEmail = email;
      
    } catch (e) {
      _isAuthenticated = false;
      _userId = null;
      _userEmail = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // This will be replaced with Firebase Auth
      await Future.delayed(const Duration(milliseconds: 500));
      _isAuthenticated = false;
      _userId = null;
      _userEmail = null;
      
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}