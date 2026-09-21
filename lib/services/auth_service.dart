import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

/// Wraps Firebase Auth + Firestore user profile (which stores role).
/// Exposes the current AppUser (with role) as a ChangeNotifier so the
/// whole app can react to sign-in / sign-out / role changes.
class AuthService extends ChangeNotifier {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _currentUser;
  bool _loading = true;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _loading;
  bool get isSignedIn => _currentUser != null;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(fb.User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _loading = false;
      notifyListeners();
      return;
    }

    // Fetch the user's profile (including role) from Firestore.
    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();

    if (doc.exists) {
      _currentUser = AppUser.fromMap(firebaseUser.uid, doc.data()!);
    } else {
      // Fallback: shouldn't normally happen since register() creates it.
      _currentUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.email ?? '',
        role: UserRole.user,
      );
    }

    _loading = false;
    notifyListeners();
  }

  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      final newUser = AppUser(uid: uid, email: email.trim(), name: name.trim(), role: role);

      await _firestore.collection('users').doc(uid).set(newUser.toMap());

      _currentUser = newUser;
      notifyListeners();
      return null; // null = success
    } on fb.FirebaseAuthException catch (e) {
      return e.message ?? 'Registration failed';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null; // success — _onAuthStateChanged will populate _currentUser
    } on fb.FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}