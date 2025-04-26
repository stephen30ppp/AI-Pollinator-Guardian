import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/firebase_service.dart';
import '../../../models/user_model.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  UserModel? _user;

  // Getters
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Initialize auth state from Firebase
  Future<void> initializeAuth() async {
    try {
      // Listen to auth state changes
      _firebaseService.authStateChanges.listen((User? firebaseUser) async {
        if (firebaseUser == null) {
          _status = AuthStatus.unauthenticated;
          _user = null;
        } else {
          _status = AuthStatus.authenticated;
          // Fetch user profile from Firestore
          _user = await _firebaseService.getUserProfile(firebaseUser.uid);
        }
        notifyListeners();
      });
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Sign in with email/username and password
  Future<bool> signIn({required String emailOrUsername, required String password}) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      await _firebaseService.signIn(
        emailOrUsername: emailOrUsername, 
        password: password
      );

      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'No account found with this email or username.';
          break;
        case 'wrong-password':
          _errorMessage = 'Incorrect password.';
          break;
        case 'invalid-credential':
          _errorMessage = 'Invalid login credentials.';
          break;
        case 'user-disabled':
          _errorMessage = 'This account has been disabled.';
          break;
        default:
          _errorMessage = 'Failed to sign in: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'An unexpected error occurred: $e';
      notifyListeners();
      return false;
    }
  }

  // Sign up with email, password and username
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      // Create auth user + Firestore profile
      final cred = await _firebaseService.signUp(
        email: email,
        password: password,
        username: username,
      );

      // Read profile with retry so we're sure it's there
      _user = await _firebaseService.getUserProfile(cred!.user!.uid);

      // Flip status exactly once; UI stops spinning
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      switch (e.code) {
        case 'email-already-in-use':
          _errorMessage = 'An account already exists with this email.';
          break;
        case 'username-already-in-use':
          _errorMessage = 'This username is already taken. Please choose another one.';
          break;
        case 'invalid-email':
          _errorMessage = 'Please provide a valid email address.';
          break;
        case 'weak-password':
          _errorMessage = 'Password should be at least 6 characters.';
          break;
        case 'operation-not-allowed':
          _errorMessage = 'Email/password accounts are not enabled.';
          break;
        default:
          _errorMessage = 'Failed to create account: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'An unexpected error occurred: $e';
      notifyListeners();
      return false;
    }
  }

  // Send password reset email
  Future<bool> resetPassword(String emailOrUsername) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      await _firebaseService.sendPasswordReset(emailOrUsername);

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'No account found with this email or username.';
          break;
        case 'invalid-email':
          _errorMessage = 'Please provide a valid email address.';
          break;
        default:
          _errorMessage = 'Failed to send reset email: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'An unexpected error occurred: $e';
      notifyListeners();
      return false;
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      return !(await _firebaseService.isUsernameTaken(username));
    } catch (e) {
      _errorMessage = 'Failed to check username availability: $e';
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
      _status = AuthStatus.unauthenticated;
      _user = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to sign out: $e';
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? username,
    String? photoUrl,
  }) async {
    if (_user == null) return false;

    try {
      final uid = _user!.id;
      final Map<String, dynamic> updates = {};

      if (displayName != null) updates['name'] = displayName;
      if (username != null) updates['username'] = username;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _firebaseService.updateUserProfile(uid, updates);

      // Refresh user data
      _user = await _firebaseService.getUserProfile(uid);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
      return false;
    }
  }

  // Clear any error messages
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}