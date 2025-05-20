import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/models/user_model.dart';
import 'package:oraculum/services/firebase_service.dart';

class AuthController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Rx<User?> currentUser = Rx<User?>(null);
  Rx<UserModel?> userModel = Rx<UserModel?>(null);
  RxBool isLoading = false.obs;

  bool get isLoggedIn => currentUser.value != null;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _auth.currentUser;
    _auth.authStateChanges().listen((User? user) {
      currentUser.value = user;
      if (user != null) {
        _loadUserData();
      } else {
        userModel.value = null;
      }
      update();
    });
  }

  Future<void> _loadUserData() async {
    if (currentUser.value != null) {
      try {
        isLoading.value = true;
        final docSnapshot = await _firebaseService.getUserData(currentUser.value!.uid);
        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;
          userModel.value = UserModel.fromMap(data, currentUser.value!.uid);
        }
      } catch (e) {
        Get.snackbar('Erro', 'Não foi possível carregar os dados do usuário: $e');
      } finally {
        isLoading.value = false;
        update();
      }
    }
  }

  // Login com email e senha
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      isLoading.value = true;
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _loadUserData();
      Get.offAllNamed(AppRoutes.navigation);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Erro de Login', _handleAuthException(e));
      return null;
    } finally {
      isLoading.value = false;
      update();
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
      isLoading.value = true;
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
          'credits': 0.0,
        });

        await _loadUserData();
        Get.offAllNamed(AppRoutes.navigation);
        return userCredential.user;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Erro no Registro', _handleAuthException(e));
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Recuperação de senha
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      isLoading.value = true;
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar('Sucesso', 'Email de recuperação enviado com sucesso!');
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Erro', _handleAuthException(e));
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao fazer logout: $e');
    }
  }

  // Atualização de perfil
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      isLoading.value = true;
      if (currentUser.value != null) {
        if (displayName != null) {
          await currentUser.value!.updateDisplayName(displayName);
        }
        if (photoURL != null) {
          await currentUser.value!.updatePhotoURL(photoURL);
        }

        // Atualiza dados no Firestore
        Map<String, dynamic> updateData = {};
        if (displayName != null) updateData['name'] = displayName;
        if (photoURL != null) updateData['profileImageUrl'] = photoURL;

        if (updateData.isNotEmpty) {
          await _firebaseService.updateUserData(currentUser.value!.uid, updateData);
        }

        await _loadUserData();
        Get.snackbar('Sucesso', 'Perfil atualizado com sucesso!');
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Erro', _handleAuthException(e));
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Alteração de senha
  Future<void> updatePassword(String newPassword) async {
    try {
      isLoading.value = true;
      if (currentUser.value != null) {
        await currentUser.value!.updatePassword(newPassword);
        Get.snackbar('Sucesso', 'Senha atualizada com sucesso!');
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Erro', _handleAuthException(e));
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Reautenticação (necessária para operações sensíveis)
  Future<void> reauthenticate(String email, String password) async {
    try {
      isLoading.value = true;
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      if (currentUser.value != null) {
        await currentUser.value!.reauthenticateWithCredential(credential);
        Get.snackbar('Sucesso', 'Reautenticação realizada com sucesso!');
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Erro', _handleAuthException(e));
    } finally {
      isLoading.value = false;
      update();
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