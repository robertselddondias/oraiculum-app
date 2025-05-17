import 'package:oraculum/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthenticationService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login com email e senha
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Registro com email e senha
  Future<User?> registerWithEmailAndPassword(
      String email,
      String password,
      String name,
      DateTime birthDate
      ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Atualizar displayName
        await userCredential.user!.updateDisplayName(name);

        // Salvar dados adicionais no Firestore
        await _firebaseService.createUserData(userCredential.user!.uid, {
          'name': name,
          'email': email,
          'birthDate': birthDate,
          'createdAt': DateTime.now(),
          'profileImageUrl': '',
          'favoriteReadings': [],
          'favoriteReaders': [],
        });

        notifyListeners();
        return userCredential.user;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Recuperação de senha
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  // Atualização de perfil
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      if (currentUser != null) {
        await currentUser!.updateDisplayName(displayName);
        await currentUser!.updatePhotoURL(photoURL);
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Alteração de senha
  Future<void> updatePassword(String newPassword) async {
    try {
      if (currentUser != null) {
        await currentUser!.updatePassword(newPassword);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Reautenticação (necessária para operações sensíveis)
  Future<void> reauthenticate(String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      if (currentUser != null) {
        await currentUser!.reauthenticateWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Tratamento de exceções do Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este email já está em uso.';
      case 'weak-password':
        return 'A senha é muito fraca.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      case 'too-many-requests':
        return 'Muitas tentativas, tente novamente mais tarde.';
      case 'requires-recent-login':
        return 'Esta operação requer autenticação recente. Faça login novamente.';
      default:
        return 'Ocorreu um erro: ${e.message}';
    }
  }
}