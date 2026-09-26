import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

/// Wraps Firebase Auth + Firestore user profile (role, phone, etc.).
/// Exposes the current AppUser as a ChangeNotifier.
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

    // Fetch the user's profile from Firestore.
    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();

    if (doc.exists) {
      _currentUser = AppUser.fromMap(firebaseUser.uid, doc.data()!);
    } else {
      // Fallback
      _currentUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? firebaseUser.email ?? '',
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
    String phone = '',
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      final newUser = AppUser(
        uid: uid,
        email: email.trim(),
        name: name.trim(),
        phone: phone.trim(),
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(newUser.toMap());

      _currentUser = newUser;
      notifyListeners();
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return e.message ?? 'Registration failed';
    } catch (e) {
      return 'Registration failed: $e';
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
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    } catch (e) {
      return 'Login failed: $e';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Updates current user's profile details in Firestore.
  Future<String?> updateProfile({required String name, required String phone}) async {
    if (_currentUser == null) return 'No user signed in';
    try {
      final updatedUser = AppUser(
        uid: _currentUser!.uid,
        email: _currentUser!.email,
        name: name.trim(),
        phone: phone.trim(),
        role: _currentUser!.role,
        createdAt: _currentUser!.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'name': name.trim(),
        'phone': phone.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _currentUser = updatedUser;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Failed to update profile: $e';
    }
  }

  /// Updates current user's role (borrower <-> owner) in Firestore.
  Future<String?> updateRole(UserRole newRole) async {
    if (_currentUser == null) return 'No user signed in';
    try {
      final updatedUser = AppUser(
        uid: _currentUser!.uid,
        email: _currentUser!.email,
        name: _currentUser!.name,
        phone: _currentUser!.phone,
        role: newRole,
        createdAt: _currentUser!.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'role': roleToString(newRole),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _currentUser = updatedUser;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Failed to update account role: $e';
    }
  }

  /// Admin method: Fetches all users from Firestore.
  Future<List<AppUser>> getAllUsers() async {
    final snap = await _firestore.collection('users').get();
    return snap.docs.map((doc) => AppUser.fromMap(doc.id, doc.data())).toList();
  }
}