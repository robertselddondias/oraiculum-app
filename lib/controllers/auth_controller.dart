import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/models/user_model.dart';
import 'package:oraculum/services/firebase_service.dart';

class AuthController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Estados observáveis
  Rx<User?> currentUser = Rx<User?>(null);
  Rx<UserModel?> userModel = Rx<UserModel?>(null);
  RxBool isLoading = false.obs;
  RxBool isAuthenticated = false.obs;
  RxString authError = ''.obs;

  // Timer para refresh automático do token
  Timer? _tokenRefreshTimer;

  // Controle de tentativas de reautenticação
  int _reauthAttempts = 0;
  static const int _maxReauthAttempts = 3;

  bool get isLoggedIn => currentUser.value != null && isAuthenticated.value;

  @override
  void onInit() {
    super.onInit();
    debugPrint('=== AuthController.onInit() ===');

    // Inicializar com usuário atual (se houver)
    currentUser.value = _auth.currentUser;
    isAuthenticated.value = _auth.currentUser != null;

    // Listener para mudanças de estado de autenticação
    _auth.authStateChanges().listen((User? user) {
      debugPrint('=== AuthStateChanged ===');
      debugPrint('Usuário: ${user?.email ?? 'null'}');

      currentUser.value = user;
      isAuthenticated.value = user != null;

      if (user != null) {
        debugPrint('Usuário logado - carregando dados...');
        _loadUserData();
        _ensureTokenFreshness();
        _startTokenRefreshTimer();
        _reauthAttempts = 0; // Reset contador de tentativas
      } else {
        debugPrint('Usuário deslogado - limpando dados...');
        userModel.value = null;
        isAuthenticated.value = false;
        authError.value = '';
        _stopTokenRefreshTimer();
      }
      update();
    });

    // Listener adicional para mudanças no token ID
    _auth.idTokenChanges().listen((User? user) {
      if (user != null) {
        debugPrint('Token ID atualizado para usuário: ${user.email}');
        _refreshAuthToken();
      }
    });

    // Se já há um usuário logado na inicialização, carregar dados
    if (currentUser.value != null) {
      debugPrint('Usuário já logado na inicialização: ${currentUser.value!.email}');
      _loadUserData();
      _ensureTokenFreshness();
      _startTokenRefreshTimer();
    }
  }

  @override
  void onClose() {
    debugPrint('=== AuthController.onClose() ===');
    _stopTokenRefreshTimer();
    super.onClose();
  }

  /// Iniciar timer para refresh automático do token a cada 30 minutos
  void _startTokenRefreshTimer() {
    _stopTokenRefreshTimer(); // Garantir que não há timer duplicado

    debugPrint('Iniciando timer de refresh de token...');
    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      debugPrint('Timer de refresh executado - ${DateTime.now()}');
      _refreshAuthToken();
    });
  }

  /// Parar timer de refresh do token
  void _stopTokenRefreshTimer() {
    if (_tokenRefreshTimer != null) {
      debugPrint('Parando timer de refresh de token...');
      _tokenRefreshTimer?.cancel();
      _tokenRefreshTimer = null;
    }
  }

  /// Método para garantir que o token de autenticação esteja sempre fresco
  Future<void> _ensureTokenFreshness() async {
    try {
      if (currentUser.value != null) {
        debugPrint('Atualizando token de autenticação...');
        await currentUser.value!.getIdToken(true);
        authError.value = '';
        debugPrint('✅ Token atualizado com sucesso');
      }
    } catch (e) {
      debugPrint('❌ Erro ao atualizar token: $e');
      authError.value = 'Erro de autenticação. Faça login novamente.';
    }
  }

  /// Método para atualizar o token de autenticação
  Future<bool> _refreshAuthToken() async {
    try {
      if (currentUser.value != null) {
        debugPrint('Executando refresh do token...');
        await currentUser.value!.getIdToken(true);
        authError.value = '';
        debugPrint('✅ Token refreshed com sucesso');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erro ao refresh do token: $e');
      authError.value = 'Sessão expirada. Faça login novamente.';
      return false;
    }
  }

  /// Método público para garantir autenticação antes de operações críticas
  Future<bool> ensureAuthenticated() async {
    try {
      debugPrint('=== ensureAuthenticated() ===');

      if (currentUser.value == null) {
        debugPrint('❌ Usuário não está logado');
        authError.value = 'Usuário não está logado';
        return false;
      }

      debugPrint('Verificando validade do usuário...');
      // Verificar se o usuário ainda está válido
      await currentUser.value!.reload();

      // Obter token fresco
      debugPrint('Obtendo token fresco...');
      final token = await currentUser.value!.getIdToken(true);

      if (token!.isEmpty) {
        debugPrint('❌ Token vazio');
        authError.value = 'Não foi possível obter token de autenticação';
        return false;
      }

      debugPrint('✅ Autenticação verificada com sucesso');
      debugPrint('Token length: ${token.length}');
      debugPrint('Token preview: ${token.substring(0, 20)}...');

      authError.value = '';
      isAuthenticated.value = true;
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao garantir autenticação: $e');
      authError.value = 'Erro de autenticação. Faça login novamente.';
      isAuthenticated.value = false;

      // Se o erro for de autenticação e não ultrapassamos o limite de tentativas
      if ((e.toString().contains('unauthenticated') ||
          e.toString().contains('not authenticated')) &&
          _reauthAttempts < _maxReauthAttempts) {

        debugPrint('Tentando reautenticação automática (tentativa ${_reauthAttempts + 1}/$_maxReauthAttempts)...');
        _reauthAttempts++;

        // Tentar refresh do token uma vez
        final refreshed = await _refreshAuthToken();
        if (refreshed) {
          return await ensureAuthenticated(); // Tentar novamente
        } else {
          await signOut(); // Logout se não conseguir reautenticar
        }
      }

      return false;
    }
  }

  /// Método para verificar se o usuário pode fazer operações que requerem pagamento
  Future<bool> canPerformPaymentOperations() async {
    try {
      debugPrint('=== canPerformPaymentOperations() ===');

      if (!isLoggedIn) {
        debugPrint('❌ Usuário não está logado');
        authError.value = 'Você precisa estar logado';
        return false;
      }

      // Verificar se a autenticação está válida
      final isAuth = await ensureAuthenticated();
      if (!isAuth) {
        debugPrint('❌ Falha na verificação de autenticação');
        return false;
      }

      // Verificar se os dados do usuário estão carregados
      if (userModel.value == null) {
        debugPrint('Dados do usuário não carregados, tentando carregar...');
        await _loadUserData();
      }

      final canPerform = userModel.value != null;
      debugPrint('✅ Pode realizar operações de pagamento: $canPerform');
      return canPerform;
    } catch (e) {
      debugPrint('❌ Erro ao verificar permissões de pagamento: $e');
      authError.value = 'Erro ao verificar permissões';
      return false;
    }
  }

  /// Método para recuperar um token válido para operações críticas
  Future<String?> getValidToken() async {
    try {
      debugPrint('=== getValidToken() ===');

      if (currentUser.value == null) {
        debugPrint('❌ Usuário não está logado');
        authError.value = 'Usuário não está logado';
        return null;
      }

      // Sempre obter um token fresco para operações críticas
      debugPrint('Obtendo token válido...');
      final token = await currentUser.value!.getIdToken(true);

      if (token!.isEmpty) {
        debugPrint('❌ Token vazio');
        authError.value = 'Não foi possível obter token de autenticação';
        return null;
      }

      debugPrint('✅ Token válido obtido (${token.length} caracteres)');
      authError.value = '';
      return token;
    } catch (e) {
      debugPrint('❌ Erro ao obter token válido: $e');
      authError.value = 'Erro de autenticação';
      return null;
    }
  }

  /// Método de teste para verificar autenticação
  Future<Map<String, dynamic>> testAuthentication() async {
    try {
      debugPrint('=== testAuthentication() ===');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ Usuário não está logado');
        return {
          'success': false,
          'error': 'Usuário não está logado',
        };
      }

      debugPrint('✅ Usuário logado: ${user.email}');
      debugPrint('✅ UID: ${user.uid}');
      debugPrint('✅ Email verificado: ${user.emailVerified}');
      debugPrint('✅ Provedor: ${user.providerData.map((p) => p.providerId).join(', ')}');

      // Testar se consegue obter token
      final token = await user.getIdToken(true);
      debugPrint('✅ Token obtido: ${token!.substring(0, 20)}... (${token.length} chars)');

      return {
        'success': true,
        'user': {
          'uid': user.uid,
          'email': user.email,
          'emailVerified': user.emailVerified,
          'isAnonymous': user.isAnonymous,
          'providers': user.providerData.map((p) => p.providerId).toList(),
          'tokenLength': token.length,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      debugPrint('❌ Erro de autenticação: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Verificar conectividade com Firebase
  Future<Map<String, dynamic>> testFirebaseConnection() async {
    try {
      debugPrint('=== testFirebaseConnection() ===');

      // Testar Firestore
      await _firebaseService.firestore
          .collection('test')
          .doc('connection')
          .get();
      debugPrint('✅ Firestore conectado');

      return {
        'success': true,
        'firestore': true,
        'timestamp': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      debugPrint('❌ Erro de conexão com Firestore: $e');
      return {
        'success': false,
        'firestore': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Forçar atualização do token
  Future<bool> refreshToken() async {
    try {
      debugPrint('=== refreshToken() ===');

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final token = await user.getIdToken(true);
        authError.value = '';
        debugPrint('✅ Token atualizado manualmente com sucesso');
        return true;
      } else {
        debugPrint('❌ Usuário não logado');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erro ao atualizar token: $e');
      authError.value = 'Erro ao atualizar token';
      return false;
    }
  }

  /// Carregar dados do usuário do Firestore
  Future<void> _loadUserData() async {
    if (currentUser.value != null) {
      try {
        debugPrint('=== _loadUserData() ===');
        isLoading.value = true;
        authError.value = '';

        final docSnapshot = await _firebaseService.getUserData(currentUser.value!.uid);
        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;
          userModel.value = UserModel.fromMap(data, currentUser.value!.uid);
          debugPrint('✅ Dados do usuário carregados: ${userModel.value!.name}');
        } else {
          debugPrint('⚠️ Documento do usuário não existe no Firestore');
        }

        isAuthenticated.value = true;
      } catch (e) {
        debugPrint('❌ Erro ao carregar dados do usuário: $e');
        authError.value = 'Não foi possível carregar os dados do usuário';

        // Se for erro de autenticação, tentar refresh do token
        if (e.toString().contains('unauthenticated') && _reauthAttempts < _maxReauthAttempts) {
          debugPrint('Tentando refresh do token devido a erro de autenticação...');
          _reauthAttempts++;
          final refreshed = await _refreshAuthToken();
          if (refreshed) {
            debugPrint('Token refreshed, tentando carregar dados novamente...');
            await _loadUserData();
            return;
          }
        }

        Get.snackbar(
          'Erro',
          'Não foi possível carregar os dados do usuário',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        isLoading.value = false;
        update();
      }
    }
  }

  // Login com email e senha - VERSÃO MELHORADA
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('=== signInWithEmailAndPassword() ===');
      debugPrint('Email: $email');

      isLoading.value = true;
      authError.value = '';
      _reauthAttempts = 0; // Reset contador

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Garantir que o token seja obtido imediatamente após o login
      if (userCredential.user != null) {
        debugPrint('Login bem-sucedido, obtendo token...');
        await userCredential.user!.getIdToken(true);
        isAuthenticated.value = true;
        debugPrint('✅ Token obtido após login');
      }

      await _loadUserData();

      debugPrint('Redirecionando para navegação...');
      Get.offAllNamed(AppRoutes.navigation);

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erro de autenticação Firebase: ${e.code} - ${e.message}');
      authError.value = _handleAuthException(e);
      isAuthenticated.value = false;

      Get.snackbar(
        'Erro de Login',
        authError.value,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (e) {
      debugPrint('❌ Erro geral no login: $e');
      authError.value = 'Erro inesperado no login';
      isAuthenticated.value = false;

      Get.snackbar(
        'Erro',
        'Erro inesperado no login',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Registro com email e senha - VERSÃO MELHORADA
  Future<User?> registerWithEmailAndPassword(
      String email,
      String password,
      String name,
      DateTime birthDate
      ) async {
    try {
      debugPrint('=== registerWithEmailAndPassword() ===');
      debugPrint('Email: $email');
      debugPrint('Nome: $name');

      isLoading.value = true;
      authError.value = '';
      _reauthAttempts = 0; // Reset contador

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        debugPrint('Registro bem-sucedido, configurando usuário...');

        // Atualizar displayName
        await userCredential.user!.updateDisplayName(name);

        // Garantir que o token seja obtido imediatamente após o registro
        await userCredential.user!.getIdToken(true);
        isAuthenticated.value = true;
        debugPrint('✅ Token obtido após registro');

        // Salvar dados adicionais no Firestore
        debugPrint('Salvando dados do usuário no Firestore...');
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

        debugPrint('Redirecionando para navegação...');
        Get.offAllNamed(AppRoutes.navigation);

        return userCredential.user;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erro de autenticação Firebase no registro: ${e.code} - ${e.message}');
      authError.value = _handleAuthException(e);
      isAuthenticated.value = false;

      Get.snackbar(
        'Erro no Registro',
        authError.value,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (e) {
      debugPrint('❌ Erro geral no registro: $e');
      authError.value = 'Erro inesperado no registro';
      isAuthenticated.value = false;

      Get.snackbar(
        'Erro',
        'Erro inesperado no registro',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Recuperação de senha
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('=== sendPasswordResetEmail() ===');
      debugPrint('Email: $email');

      isLoading.value = true;
      authError.value = '';

      await _auth.sendPasswordResetEmail(email: email);

      Get.snackbar(
        'Sucesso',
        'Email de recuperação enviado com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erro ao enviar email de recuperação: ${e.code} - ${e.message}');
      authError.value = _handleAuthException(e);

      Get.snackbar(
        'Erro',
        authError.value,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Logout - VERSÃO MELHORADA
  Future<void> signOut() async {
    try {
      debugPrint('=== signOut() ===');
      isLoading.value = true;

      // Parar timer de refresh
      _stopTokenRefreshTimer();

      await _auth.signOut();

      // Limpar estado local
      currentUser.value = null;
      userModel.value = null;
      isAuthenticated.value = false;
      authError.value = '';
      _reauthAttempts = 0;

      debugPrint('✅ Logout realizado com sucesso');
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      debugPrint('❌ Erro ao fazer logout: $e');
      Get.snackbar(
        'Erro',
        'Erro ao fazer logout: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Atualização de perfil - VERSÃO MELHORADA
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      debugPrint('=== updateUserProfile() ===');
      isLoading.value = true;
      authError.value = '';

      // Garantir autenticação antes da operação
      final isAuth = await ensureAuthenticated();
      if (!isAuth) {
        Get.snackbar(
          'Erro',
          'Você precisa estar logado para atualizar o perfil',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

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

        Get.snackbar(
          'Sucesso',
          'Perfil atualizado com sucesso!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erro ao atualizar perfil: ${e.code} - ${e.message}');
      authError.value = _handleAuthException(e);

      Get.snackbar(
        'Erro',
        authError.value,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Alteração de senha - VERSÃO MELHORADA
  Future<void> updatePassword(String newPassword) async {
    try {
      debugPrint('=== updatePassword() ===');
      isLoading.value = true;
      authError.value = '';

      // Garantir autenticação antes da operação
      final isAuth = await ensureAuthenticated();
      if (!isAuth) {
        Get.snackbar(
          'Erro',
          'Você precisa estar logado para alterar a senha',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (currentUser.value != null) {
        await currentUser.value!.updatePassword(newPassword);

        Get.snackbar(
          'Sucesso',
          'Senha atualizada com sucesso!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erro ao atualizar senha: ${e.code} - ${e.message}');
      authError.value = _handleAuthException(e);

      Get.snackbar(
        'Erro',
        authError.value,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Reautenticação (necessária para operações sensíveis) - VERSÃO MELHORADA
  Future<bool> reauthenticate(String email, String password) async {
    try {
      debugPrint('=== reauthenticate() ===');
      isLoading.value = true;
      authError.value = '';

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      if (currentUser.value != null) {
        await currentUser.value!.reauthenticateWithCredential(credential);

        // Obter novo token após reautenticação
        await currentUser.value!.getIdToken(true);
        isAuthenticated.value = true;
        _reauthAttempts = 0; // Reset contador

        Get.snackbar(
          'Sucesso',
          'Reautenticação realizada com sucesso!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erro na reautenticação: ${e.code} - ${e.message}');
      authError.value = _handleAuthException(e);
      isAuthenticated.value = false;

      Get.snackbar(
        'Erro',
        authError.value,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  /// Executar diagnóstico completo da autenticação
  Future<Map<String, dynamic>> runCompleteDiagnostics() async {
    debugPrint('=== runCompleteDiagnostics() ===');

    final results = <String, dynamic>{};

    // 1. Estado atual do usuário
    results['currentUserState'] = {
      'isLoggedIn': isLoggedIn,
      'currentUserExists': currentUser.value != null,
      'isAuthenticated': isAuthenticated.value,
      'hasUserModel': userModel.value != null,
      'authError': authError.value,
    };

    // 2. Teste de autenticação
    results['authTest'] = await testAuthentication();

    // 3. Teste de conectividade Firebase
    results['firebaseTest'] = await testFirebaseConnection();

    // 4. Teste de refresh de token
    try {
      final refreshResult = await refreshToken();
      results['tokenRefreshTest'] = {
        'success': refreshResult,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      results['tokenRefreshTest'] = {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    // 5. Verificação de operações de pagamento
    try {
      final canPerform = await canPerformPaymentOperations();
      results['paymentOperationsTest'] = {
        'success': canPerform,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      results['paymentOperationsTest'] = {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    // 6. Informações do timer
    results['timerInfo'] = {
      'timerActive': _tokenRefreshTimer != null,
      'reauthAttempts': _reauthAttempts,
      'maxReauthAttempts': _maxReauthAttempts,
    };

    debugPrint('Diagnósticos completos concluídos');
    return results;
  }

  // Tratamento de exceções do Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    debugPrint('Tratando exceção de autenticação: ${e.code}');

    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este email já está em uso.';
      case 'weak-password':
        return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'invalid-credential':
        return 'Credenciais inválidas. Verifique email e senha.';
      case 'user-disabled':
        return 'Esta conta foi desabilitada.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      case 'too-many-requests':
        return 'Muitas tentativas falharam. Tente novamente mais tarde.';
      case 'requires-recent-login':
        return 'Esta operação requer autenticação recente. Faça login novamente.';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet e tente novamente.';
      case 'internal-error':
        return 'Erro interno do servidor. Tente novamente mais tarde.';
      case 'invalid-api-key':
        return 'Configuração inválida do aplicativo.';
      case 'app-deleted':
        return 'Aplicativo não configurado corretamente.';
      case 'expired-action-code':
        return 'Link expirado. Solicite um novo.';
      case 'invalid-action-code':
        return 'Link inválido ou já utilizado.';
      case 'missing-email':
        return 'Email é obrigatório.';
      case 'missing-password':
        return 'Senha é obrigatória.';
      case 'email-change-needs-verification':
        return 'Mudança de email precisa ser verificada.';
      case 'credential-already-in-use':
        return 'Esta credencial já está sendo usada por outra conta.';
      case 'invalid-verification-code':
        return 'Código de verificação inválido.';
      case 'invalid-verification-id':
        return 'ID de verificação inválido.';
      case 'session-expired':
        return 'Sessão expirada. Faça login novamente.';
      case 'quota-exceeded':
        return 'Cota excedida. Tente novamente mais tarde.';
      default:
        debugPrint('Erro não mapeado: ${e.code} - ${e.message}');
        return e.message ?? 'Ocorreu um erro inesperado. Tente novamente.';
    }
  }

  /// Método de conveniência para mostrar snackbars de erro
  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(
        Icons.error_outline,
        color: Colors.white,
      ),
    );
  }

  /// Método de conveniência para mostrar snackbars de sucesso
  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(
        Icons.check_circle_outline,
        color: Colors.white,
      ),
    );
  }

  /// Método de conveniência para mostrar snackbars de aviso
  void _showWarningSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(
        Icons.warning_outlined,
        color: Colors.white,
      ),
    );
  }

  /// Método para verificar se é necessário reautenticar para operações sensíveis
  Future<bool> checkIfRecentAuthRequired() async {
    try {
      if (currentUser.value == null) return false;

      // Verificar quando foi o último login
      final metadata = currentUser.value!.metadata;
      final lastSignIn = metadata.lastSignInTime;

      if (lastSignIn == null) return true;

      // Se o último login foi há mais de 5 minutos, pode precisar reautenticar
      final now = DateTime.now();
      final timeDifference = now.difference(lastSignIn);

      return timeDifference.inMinutes > 5;
    } catch (e) {
      debugPrint('Erro ao verificar necessidade de reautenticação: $e');
      return true; // Por segurança, assumir que precisa reautenticar
    }
  }

  /// Método para limpar completamente o estado de autenticação
  Future<void> clearAuthState() async {
    debugPrint('=== clearAuthState() ===');

    _stopTokenRefreshTimer();

    currentUser.value = null;
    userModel.value = null;
    isAuthenticated.value = false;
    authError.value = '';
    _reauthAttempts = 0;
    isLoading.value = false;

    debugPrint('✅ Estado de autenticação limpo');
    update();
  }

  /// Método para verificar conectividade de rede
  Future<bool> checkNetworkConnectivity() async {
    try {
      // Tentativa simples de conexão com o Firebase
      await _firebaseService.firestore
          .collection('_test_connectivity')
          .doc('test')
          .get()
          .timeout(const Duration(seconds: 5));

      return true;
    } catch (e) {
      debugPrint('❌ Sem conectividade de rede: $e');
      return false;
    }
  }

  /// Método para mostrar diálogo de erro de rede
  void showNetworkErrorDialog() {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Sem Conexão'),
          ],
        ),
        content: const Text(
          'Verifique sua conexão com a internet e tente novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final hasConnection = await checkNetworkConnectivity();
              if (hasConnection) {
                _showSuccessSnackbar('Conectado', 'Conexão restaurada!');
              } else {
                _showErrorSnackbar('Ainda sem conexão', 'Verifique sua internet');
              }
            },
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Método para mostrar status detalhado da autenticação
  void showAuthStatus() {
    final user = currentUser.value;

    String status = '';
    if (user == null) {
      status = '❌ Usuário não logado';
    } else {
      status = '''
✅ Usuário: ${user.email}
✅ UID: ${user.uid}
✅ Email verificado: ${user.emailVerified ? 'Sim' : 'Não'}
✅ Último login: ${user.metadata.lastSignInTime}
✅ Autenticado: ${isAuthenticated.value ? 'Sim' : 'Não'}
✅ Timer ativo: ${_tokenRefreshTimer != null ? 'Sim' : 'Não'}
✅ Tentativas reauth: $_reauthAttempts/$_maxReauthAttempts
      ''';
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Status da Autenticação'),
        content: SingleChildScrollView(
          child: Text(status),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fechar'),
          ),
          if (user != null)
            ElevatedButton(
              onPressed: () async {
                Get.back();
                final diagnostics = await runCompleteDiagnostics();
                debugPrint('Diagnósticos completos: $diagnostics');
                _showSuccessSnackbar('Diagnósticos', 'Executados com sucesso (veja o console)');
              },
              child: const Text('Executar Diagnósticos'),
            ),
        ],
      ),
    );
  }

  /// Getter para informações básicas do usuário (para debug)
  Map<String, dynamic> get userDebugInfo {
    final user = currentUser.value;
    if (user == null) {
      return {'loggedIn': false};
    }

    return {
      'loggedIn': true,
      'uid': user.uid,
      'email': user.email,
      'emailVerified': user.emailVerified,
      'isAnonymous': user.isAnonymous,
      'isAuthenticated': isAuthenticated.value,
      'hasUserModel': userModel.value != null,
      'timerActive': _tokenRefreshTimer != null,
      'reauthAttempts': _reauthAttempts,
      'authError': authError.value,
      'lastSignIn': user.metadata.lastSignInTime?.toIso8601String(),
      'creationTime': user.metadata.creationTime?.toIso8601String(),
    };
  }
}