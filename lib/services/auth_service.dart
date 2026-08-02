import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

abstract interface class AuthGateway {
  Stream<User?> get userChanges;
  User? get currentUser;
  Future<UserCredential> signIn(String email, String password);
  Future<UserCredential> register(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<void> deleteAccount();
}

class AuthService extends ChangeNotifier implements AuthGateway {
  AuthService({required bool enabled, FirebaseAuth? firebaseAuth})
      : _auth = enabled ? (firebaseAuth ?? FirebaseAuth.instance) : null {
    _subscription = _auth?.userChanges().listen((_) => notifyListeners());
  }

  final FirebaseAuth? _auth;
  StreamSubscription<User?>? _subscription;

  bool get isEnabled => _auth != null;

  FirebaseAuth get _requiredAuth {
    final auth = _auth;
    if (auth == null) {
      throw StateError('Cloud authentication is not configured.');
    }
    return auth;
  }

  @override
  Stream<User?> get userChanges =>
      _auth?.userChanges() ?? const Stream<User?>.empty();

  @override
  User? get currentUser => _auth?.currentUser;

  @override
  Future<UserCredential> signIn(String email, String password) =>
      _requiredAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

  @override
  Future<UserCredential> register(String email, String password) =>
      _requiredAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

  @override
  Future<void> signOut() => _requiredAuth.signOut();

  @override
  Future<void> sendPasswordReset(String email) =>
      _requiredAuth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<void> deleteAccount() async {
    final user = _requiredAuth.currentUser;
    if (user == null) throw StateError('No signed-in account.');
    await user.delete();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
