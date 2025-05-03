import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class FirebaseService {
  // ───────────────────────── Singleton ─────────────────────────
  FirebaseService._internal();
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;

  // ───────────────────── Firebase instances ────────────────────
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // region --- AUTH STATE STREAM ---
  /// Expose auth changes to Providers / Riverpod
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Cached UID helper (null when signed-out)
  String? get currentUid => _auth.currentUser?.uid;

  // endregion

  // region --- USERNAME METHODS ---
  /// Check if a username is already taken
  Future<bool> isUsernameTaken(String username) async {
    final snapshot = await _db
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    
    return snapshot.docs.isNotEmpty;
  }

  /// Find a user by username
  Future<UserModel?> getUserByUsername(String username) async {
    final snapshot = await _db
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return UserModel.fromJson({
      ...snapshot.docs.first.data(),
      'id': snapshot.docs.first.id,
    });
  }
  // endregion

  // region --- AUTH METHODS ---
  /// Sign up with email, password and username
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    try {
      // First, check if username is already taken
      final isUsernameExists = await isUsernameTaken(username);
      if (isUsernameExists) {
        throw FirebaseAuthException(
          code: 'username-already-in-use',
          message: 'This username is already taken. Please choose another one.',
        );
      }

      // Create user with email and password
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null) {
        await credential.user?.updateDisplayName(displayName);
      } else {
        await credential.user?.updateDisplayName(username);
      }
      
      await credential.user?.sendEmailVerification();
      
      // Create user profile with username
      await _createUserProfile(
        uid: credential.user!.uid,
        name: displayName ?? username,
        email: email,
        username: username.toLowerCase(), // Store lowercase for case-insensitive lookup
      );
      
      return credential;
    } on FirebaseAuthException catch (e, s) {
      debugPrint('signUp error: $e\n$s');
      rethrow;
    }
  }

  /// Sign in with email or username + password
  Future<UserCredential?> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      // Check if input is an email or username
      final bool isEmail = emailOrUsername.contains('@');
      
      if (isEmail) {
        // Sign in with email and password
        return await _auth.signInWithEmailAndPassword(
          email: emailOrUsername,
          password: password,
        );
      } else {
        // Find user by username first
        final user = await getUserByUsername(emailOrUsername);
        if (user == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No user found with this username.',
          );
        }
        
        // Sign in with the associated email
        return await _auth.signInWithEmailAndPassword(
          email: user.email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e, s) {
      debugPrint('signIn error: $e\n$s');
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String emailOrUsername) async {
    // Handle both email and username for password reset
    String email;
    
    if (emailOrUsername.contains('@')) {
      email = emailOrUsername;
    } else {
      // Find user by username
      final user = await getUserByUsername(emailOrUsername);
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found with this username.',
        );
      }
      email = user.email;
    }
    
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _auth.signOut();

  /// Re-authenticate before sensitive ops (delete, change email, etc.)
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser!;
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(cred);
  }

  Future<void> deleteAccount() async {
    final uid = currentUid;
    await _auth.currentUser?.delete();
    if (uid != null) await deleteUserProfile(uid);
  }
  // endregion

  // region --- FIRESTORE USER PROFILE CRUD ---
  Future<void> _createUserProfile({
    required String uid,
    required String name,
    required String email,
    required String username,
    String? photoUrl,
  }) => _db.collection('users').doc(uid).set({
    'id': uid,
    'name': name,
    'email': email,
    'username': username,
    'photoUrl': photoUrl,
    'createdAt': FieldValue.serverTimestamp(),
    'sightings': [],
    'gardens': [],
  });

  Future<UserModel?> getUserProfile(String uid) => _retryWithBackoff(() async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.exists
        ? UserModel.fromJson({...snap.data()!, 'id': uid})
        : null;
  });

  Future<T> _retryWithBackoff<T>(
    Future<T> Function() action, {
    int maxAttempts = 4,
    Duration baseDelay = const Duration(milliseconds: 300),
  }) async {
    FirebaseException? last;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await action();
      } on FirebaseException catch (e) {
        if (e.code != 'unavailable') rethrow; // permanent
        last = e;
        await Future.delayed(
          baseDelay * (1 << attempt),
        ); // 0.3 s, 0.6 s, 1.2 s…
      }
    }
    throw last!;
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    // If username is being updated, check if it's already taken
    if (data.containsKey('username')) {
      final newUsername = data['username'] as String;
      
      // Get current user data to check if username is actually changing
      final currentUser = await getUserProfile(uid);
      if (currentUser?.username != newUsername) {
        final isUsernameExists = await isUsernameTaken(newUsername);
        if (isUsernameExists) {
          throw FirebaseAuthException(
            code: 'username-already-in-use',
            message: 'This username is already taken. Please choose another one.',
          );
        }
        
        // Store lowercase version for case-insensitive lookup
        data['username'] = newUsername.toLowerCase();
      }
    }
    
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> setUserField(
    String uid, {
    required String field,
    required dynamic value,
  }) => _db.collection('users').doc(uid).update({field: value});

  Future<void> incrementUserCounter(
    String uid, {
    required String field,
    int by = 1,
  }) => _db.collection('users').doc(uid).update({
    field: FieldValue.increment(by),
  });

  Future<void> deleteUserProfile(String uid) =>
      _db.collection('users').doc(uid).delete();
  // endregion

  // region --- GENERIC HELPERS ---
  Future<DocumentReference<Map<String, dynamic>>> createDocument(
    String collection,
    Map<String, dynamic> data,
  ) => _db.collection(collection).add(data);

  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) => _db.collection(collection).doc(docId).update(data);

  Future<void> deleteDocument(String collection, String docId) =>
      _db.collection(collection).doc(docId).delete();

  /// A simple server-timestamp aware transaction wrapper
  Future<T> runTransaction<T>(TransactionHandler<T> handler) =>
      _db.runTransaction(handler);
  // endregion
}