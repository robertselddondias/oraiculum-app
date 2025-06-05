import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/models/user_model.dart';
import 'package:oraculum/services/firebase_service.dart';

class AuthController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Estados observáveis
  Rx<User?> currentUser = Rx<User?>(null);
  Rx<UserModel?> userModel = Rx<UserModel?>(null);
  RxBool isLoading = false.obs;
  RxBool isAuthenticated = false.obs;
  RxString authError = ''.obs;

  // Apple Sign In availability
  RxBool isAppleSignInAvailable = false.obs;

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

    // Verificar disponibilidade do Apple Sign In
    _checkAppleSignInAvailability();

    // Listener para mudanças de estado de autenticação
    _auth.authStateChanges().listen(_handleAuthStateChange);

    // Listener adicional para mudanças no token ID
    _auth.idTokenChanges().listen(_handleTokenChange);

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

  // ========== AUTH STATE MANAGEMENT ==========

  void _handleAuthStateChange(User? user) {
    debugPrint('=== AuthStateChanged ===');
    debugPrint('Usuário: ${user?.email ?? 'null'}');

    currentUser.value = user;
    isAuthenticated.value = user != null;

    if (user != null) {
      debugPrint('Usuário logado - carregando dados...');
      _loadUserData();
      _ensureTokenFreshness();
      _startTokenRefreshTimer();
      _reauthAttempts = 0;
    } else {
      debugPrint('Usuário deslogado - limpando dados...');
      _clearUserData();
    }
    update();
  }

  void _handleTokenChange(User? user) {
    if (user != null) {
      debugPrint('Token ID atualizado para usuário: ${user.email}');
      _refreshAuthToken();
    }
  }

  void _clearUserData() {
    userModel.value = null;
    isAuthenticated.value = false;
    authError.value = '';
    _stopTokenRefreshTimer();
  }

  // ========== TOKEN MANAGEMENT ==========

  void _startTokenRefreshTimer() {
    _stopTokenRefreshTimer();

    debugPrint('Iniciando timer de refresh de token...');
    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      debugPrint('Timer de refresh executado - ${DateTime.now()}');
      _refreshAuthToken();
    });
  }

  void _stopTokenRefreshTimer() {
    if (_tokenRefreshTimer != null) {
      debugPrint('Parando timer de refresh de token...');
      _tokenRefreshTimer?.cancel();
      _tokenRefreshTimer = null;
    }
  }

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

  // ========== APPLE SIGN IN ==========

  Future<void> _checkAppleSignInAvailability() async {
    if (Platform.isIOS) {
      try {
        isAppleSignInAvailable.value = await SignInWithApple.isAvailable();
        debugPrint('Apple Sign In disponível: ${isAppleSignInAvailable.value}');
      } catch (e) {
        debugPrint('Erro ao verificar Apple Sign In: $e');
        isAppleSignInAvailable.value = false;
      }
    } else {
      isAppleSignInAvailable.value = false;
    }
  }

  /// Método público para verificar disponibilidade
  Future<void> checkAppleSignInAvailability() async {
    await _checkAppleSignInAvailability();
  }

  /// Login com Apple
  Future<User?> signInWithApple() async {
    try {
      debugPrint('=== signInWithApple() ===');

      isLoading.value = true;
      authError.value = '';
      _reauthAttempts = 0;

      if (!isAppleSignInAvailable.value) {
        throw Exception('Apple Sign In não está disponível neste dispositivo');
      }

      // Solicitar credenciais do Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.selddon.oraculum',
          redirectUri: Uri.parse('https://oraculum-app.firebaseapp.com/__/auth/handler'),
        ),
      );

      debugPrint('Apple credential obtido: ${appleCredential.userIdentifier}');

      // Criar credencial do Firebase
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Fazer login no Firebase
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      if (userCredential.user != null) {
        await _handleSuccessfulAppleLogin(userCredential, appleCredential);
        return userCredential.user;
      }

      return null;
    } on SignInWithAppleAuthorizationException catch (e) {
      return _handleAppleSignInError(e);
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthError(e, 'Apple');
    } catch (e) {
      return _handleGeneralAppleError(e);
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> _handleSuccessfulAppleLogin(
      UserCredential userCredential,
      AuthorizationCredentialAppleID appleCredential,
      ) async {
    debugPrint('Login com Apple bem-sucedido');

    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

    // Garantir token
    await userCredential.user!.getIdToken(true);
    isAuthenticated.value = true;

    // Extrair nome do usuário
    String displayName = _extractDisplayName(userCredential.user!, appleCredential);

    // Atualizar displayName se necessário
    if (userCredential.user!.displayName != displayName) {
      await userCredential.user!.updateDisplayName(displayName);
    }

    if (isNewUser) {
      await _createAppleUserProfile(userCredential.user!, appleCredential, displayName);
      await _loadUserData();
      await ensureUserSettingsExist();
      Get.offAllNamed(AppRoutes.googleRegisterComplete);
    } else {
      await _handleExistingAppleUser(userCredential.user!, displayName);
    }

    _showSuccessSnackbar('Sucesso', 'Login com Apple realizado com sucesso!');
  }

  String _extractDisplayName(User user, AuthorizationCredentialAppleID appleCredential) {
    String displayName = user.displayName ?? 'Usuário';

    if (appleCredential.givenName != null && appleCredential.familyName != null) {
      displayName = '${appleCredential.givenName} ${appleCredential.familyName}';
    } else if (appleCredential.givenName != null) {
      displayName = appleCredential.givenName!;
    }

    return displayName;
  }

  Future<void> _createAppleUserProfile(
      User user,
      AuthorizationCredentialAppleID appleCredential,
      String displayName,
      ) async {
    debugPrint('Novo usuário Apple - criando perfil básico...');

    await _firebaseService.createUserData(user.uid, {
      'name': displayName,
      'email': user.email ?? appleCredential.email ?? '',
      'createdAt': DateTime.now(),
      'profileImageUrl': user.photoURL ?? '',
      'favoriteReadings': [],
      'favoriteReaders': [],
      'credits': 0.0,
      'loginProvider': 'apple',
      'registrationCompleted': false,
      'appleUserIdentifier': appleCredential.userIdentifier,
    });

    debugPrint('✅ Perfil básico de novo usuário Apple criado');
  }

  Future<void> _handleExistingAppleUser(User user, String displayName) async {
    debugPrint('Usuário Apple existente - verificando registro...');

    final registrationCompleted = await checkRegistrationCompleted(user.uid);

    if (!registrationCompleted) {
      debugPrint('Registro incompleto - redirecionando...');
      await _loadUserData();
      Get.offAllNamed(AppRoutes.googleRegisterComplete);
    } else {
      debugPrint('Registro completo - atualizando informações...');
      await _firebaseService.updateUserData(user.uid, {
        'lastLogin': DateTime.now(),
        'name': displayName,
      });
      await _loadUserData();
      Get.offAllNamed(AppRoutes.navigation);
    }
  }

  User? _handleAppleSignInError(SignInWithAppleAuthorizationException e) {
    debugPrint('❌ Erro de autorização Apple: ${e.code} - ${e.message}');

    String errorMessage = 'Erro no login com Apple';
    switch (e.code) {
      case AuthorizationErrorCode.canceled:
        errorMessage = 'Login cancelado pelo usuário';
        break;
      case AuthorizationErrorCode.failed:
        errorMessage = 'Falha na autenticação com Apple';
        break;
      case AuthorizationErrorCode.invalidResponse:
        errorMessage = 'Resposta inválida do Apple';
        break;
      case AuthorizationErrorCode.notHandled:
        errorMessage = 'Erro não tratado pelo Apple';
        break;
      case AuthorizationErrorCode.unknown:
        errorMessage = 'Erro desconhecido no Apple Sign In';
        break;
      case AuthorizationErrorCode.notInteractive:
        errorMessage = 'Processo não interativo';
        break;
    }

    authError.value = errorMessage;
    isAuthenticated.value = false;

    if (e.code != AuthorizationErrorCode.canceled) {
      _showErrorSnackbar('Erro no Login Apple', errorMessage);
    }
    return null;
  }

  User? _handleGeneralAppleError(dynamic e) {
    debugPrint('❌ Erro geral no login com Apple: $e');
    authError.value = 'Erro no login com Apple';
    isAuthenticated.value = false;

    String errorMessage = 'Erro no login com Apple';

    if (e.toString().contains('not available')) {
      errorMessage = 'Apple Sign In não está disponível neste dispositivo';
    } else if (e.toString().contains('network')) {
      errorMessage = 'Erro de conexão. Verifique sua internet.';
    }

    _showErrorSnackbar('Erro', errorMessage);
    return null;
  }

  // ========== USER DATA MANAGEMENT ==========

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
        await updateUserFcmToken();
      } catch (e) {
        await _handleLoadUserDataError(e);
      } finally {
        isLoading.value = false;
        update();
      }
    }
  }

  Future<void> _handleLoadUserDataError(dynamic e) async {
    debugPrint('❌ Erro ao carregar dados do usuário: $e');
    authError.value = 'Não foi possível carregar os dados do usuário';

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

    _showErrorSnackbar('Erro', 'Não foi possível carregar os dados do usuário');
  }

  /// Método público para carregar dados do usuário
  Future<void> loadUserData() async {
    await _loadUserData();
  }

  // ========== AUTHENTICATION METHODS ==========

  /// Garantir autenticação antes de operações críticas
  Future<bool> ensureAuthenticated() async {
    try {
      debugPrint('=== ensureAuthenticated() ===');

      if (currentUser.value == null) {
        debugPrint('❌ Usuário não está logado');
        authError.value = 'Usuário não está logado';
        return false;
      }

      debugPrint('Verificando validade do usuário...');
      await currentUser.value!.reload();

      debugPrint('Obtendo token fresco...');
      final token = await currentUser.value!.getIdToken(true);

      if (token!.isEmpty) {
        debugPrint('❌ Token vazio');
        authError.value = 'Não foi possível obter token de autenticação';
        return false;
      }

      debugPrint('✅ Autenticação verificada com sucesso');
      authError.value = '';
      isAuthenticated.value = true;
      return true;
    } catch (e) {
      return await _handleAuthenticationError(e);
    }
  }

  Future<bool> _handleAuthenticationError(dynamic e) async {
    debugPrint('❌ Erro ao garantir autenticação: $e');
    authError.value = 'Erro de autenticação. Faça login novamente.';
    isAuthenticated.value = false;

    if ((e.toString().contains('unauthenticated') ||
        e.toString().contains('not authenticated')) &&
        _reauthAttempts < _maxReauthAttempts) {

      debugPrint('Tentando reautenticação automática (tentativa ${_reauthAttempts + 1}/$_maxReauthAttempts)...');
      _reauthAttempts++;

      final refreshed = await _refreshAuthToken();
      if (refreshed) {
        return await ensureAuthenticated();
      } else {
        await signOut();
      }
    }

    return false;
  }

  /// Verificar se pode fazer operações de pagamento
  Future<bool> canPerformPaymentOperations() async {
    try {
      debugPrint('=== canPerformPaymentOperations() ===');

      if (!isLoggedIn) {
        debugPrint('❌ Usuário não está logado');
        authError.value = 'Você precisa estar logado';
        return false;
      }

      final isAuth = await ensureAuthenticated();
      if (!isAuth) {
        debugPrint('❌ Falha na verificação de autenticação');
        return false;
      }

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

  /// Obter token válido para operações críticas
  Future<String?> getValidToken() async {
    try {
      debugPrint('=== getValidToken() ===');

      if (currentUser.value == null) {
        debugPrint('❌ Usuário não está logado');
        authError.value = 'Usuário não está logado';
        return null;
      }

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

  /// Verificar se o usuário completou o registro
  Future<bool> checkRegistrationCompleted(String userId) async {
    try {
      final userDoc = await _firebaseService.getUserData(userId);
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['registrationCompleted'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao verificar registro completo: $e');
      return false;
    }
  }

  // ========== EMAIL/PASSWORD AUTH ==========

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('=== signInWithEmailAndPassword() ===');
      debugPrint('Email: $email');

      isLoading.value = true;
      authError.value = '';
      _reauthAttempts = 0;

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        debugPrint('Login bem-sucedido, obtendo token...');
        await userCredential.user!.getIdToken(true);
        isAuthenticated.value = true;
        debugPrint('✅ Token obtido após login');
      }

      await _loadUserData();
      await ensureUserSettingsExist();

      debugPrint('Redirecionando para navegação...');
      Get.offAllNamed(AppRoutes.navigation);

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthError(e, 'Email/Password');
    } catch (e) {
      return _handleGeneralAuthError(e, 'login');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<User?> registerWithEmailAndPassword(
      String email,
      String password,
      String name,
      DateTime birthDate,
      String gender,
      ) async {
    try {
      debugPrint('=== registerWithEmailAndPassword() ===');
      debugPrint('Email: $email');
      debugPrint('Nome: $name');
      debugPrint('Gênero: $gender');

      isLoading.value = true;
      authError.value = '';
      _reauthAttempts = 0;

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        debugPrint('Registro bem-sucedido, configurando usuário...');

        await userCredential.user!.updateDisplayName(name);
        await userCredential.user!.getIdToken(true);
        isAuthenticated.value = true;

        await _firebaseService.createUserData(userCredential.user!.uid, {
          'name': name,
          'email': email,
          'birthDate': birthDate,
          'gender': gender,
          'createdAt': DateTime.now(),
          'profileImageUrl': '',
          'favoriteReadings': [],
          'favoriteReaders': [],
          'credits': 0.0,
          'registrationCompleted': true,
          'loginProvider': 'email',
        });

        await _loadUserData();
        await ensureUserSettingsExist();

        Get.offAllNamed(AppRoutes.navigation);
        return userCredential.user;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthError(e, 'Registro');
    } catch (e) {
      return _handleGeneralAuthError(e, 'registro');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // ========== GOOGLE AUTH ==========

  Future<User?> signInWithGoogle() async {
    try {
      debugPrint('=== signInWithGoogle() ===');

      isLoading.value = true;
      authError.value = '';
      _reauthAttempts = 0;

      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Login com Google cancelado pelo usuário');
        return null;
      }

      debugPrint('Usuário Google selecionado: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _handleSuccessfulGoogleLogin(userCredential);
        return userCredential.user;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthError(e, 'Google');
    } catch (e) {
      return _handleGeneralGoogleError(e);
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> _handleSuccessfulGoogleLogin(UserCredential userCredential) async {
    debugPrint('Login com Google bem-sucedido');

    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

    await userCredential.user!.getIdToken(true);
    isAuthenticated.value = true;

    if (isNewUser) {
      await _createGoogleUserProfile(userCredential.user!);
      await _loadUserData();
      await ensureUserSettingsExist();
      Get.offAllNamed(AppRoutes.googleRegisterComplete);
    } else {
      await _handleExistingGoogleUser(userCredential.user!);
    }

    _showSuccessSnackbar('Sucesso', 'Login realizado com sucesso!');
  }

  Future<void> _createGoogleUserProfile(User user) async {
    debugPrint('Novo usuário - criando perfil básico...');

    await _firebaseService.createUserData(user.uid, {
      'name': user.displayName ?? 'Usuário',
      'email': user.email ?? '',
      'createdAt': DateTime.now(),
      'profileImageUrl': user.photoURL ?? '',
      'favoriteReadings': [],
      'favoriteReaders': [],
      'credits': 0.0,
      'loginProvider': 'google',
      'registrationCompleted': false,
    });

    debugPrint('✅ Perfil básico de novo usuário criado');
  }

  Future<void> _handleExistingGoogleUser(User user) async {
    debugPrint('Usuário existente - verificando se completou o registro...');

    final registrationCompleted = await checkRegistrationCompleted(user.uid);

    if (!registrationCompleted) {
      debugPrint('Registro incompleto - redirecionando...');
      await _loadUserData();
      Get.offAllNamed(AppRoutes.googleRegisterComplete);
    } else {
      debugPrint('Registro completo - atualizando informações...');
      await _firebaseService.updateUserData(user.uid, {
        'lastLogin': DateTime.now(),
        'profileImageUrl': user.photoURL ?? '',
      });
      await _loadUserData();
      Get.offAllNamed(AppRoutes.navigation);
    }
  }

  User? _handleGeneralGoogleError(dynamic e) {
    debugPrint('❌ Erro geral no login com Google: $e');
    authError.value = 'Erro no login com Google';
    isAuthenticated.value = false;

    String errorMessage = 'Erro no login com Google';

    if (e.toString().contains('network_error')) {
      errorMessage = 'Erro de conexão. Verifique sua internet.';
    } else if (e.toString().contains('sign_in_canceled')) {
      errorMessage = 'Login cancelado pelo usuário';
    } else if (e.toString().contains('sign_in_failed')) {
      errorMessage = 'Falha no login. Tente novamente.';
    }

    _showErrorSnackbar('Erro', errorMessage);
    return null;
  }

  // ========== PASSWORD RESET ==========

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('=== sendPasswordResetEmail() ===');
      debugPrint('Email: $email');

      isLoading.value = true;
      authError.value = '';

      await _auth.sendPasswordResetEmail(email: email);

      _showSuccessSnackbar('Sucesso', 'Email de recuperação enviado com sucesso!');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erro ao enviar email de recuperação: ${e.code} - ${e.message}');
      authError.value = _handleAuthException(e);
      _showErrorSnackbar('Erro', authError.value);
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // ========== PROFILE MANAGEMENT ==========

  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      debugPrint('=== updateUserProfile() ===');
      isLoading.value = true;
      authError.value = '';

      final isAuth = await ensureAuthenticated();
      if (!isAuth) {
        _showErrorSnackbar('Erro', 'Você precisa estar logado para atualizar o perfil');
        return;
      }

      if (currentUser.value != null) {
        if (displayName != null) {
          await currentUser.value!.updateDisplayName(displayName);
        }
        if (photoURL != null) {
          await currentUser.value!.updatePhotoURL(photoURL);
        }

        Map<String, dynamic> updateData = {};
        if (displayName != null) updateData['name'] = displayName;
        if (photoURL != null) updateData['profileImageUrl'] = photoURL;

        if (updateData.isNotEmpty) {
          await _firebaseService.updateUserData(currentUser.value!.uid, updateData);
        }

        await _loadUserData();
        _showSuccessSnackbar('Sucesso', 'Perfil atualizado com sucesso!');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erro ao atualizar perfil: ${e.code} - ${e.message}');
      authError.value = _handleAuthException(e);
      _showErrorSnackbar('Erro', authError.value);
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      debugPrint('=== updatePassword() ===');
      isLoading.value = true;
      authError.value = '';

      final isAuth = await ensureAuthenticated();
      if (!isAuth) {
        _showErrorSnackbar('Erro', 'Você precisa estar logado para alterar a senha');
        return;
      }

      if (currentUser.value != null) {
        await currentUser.value!.updatePassword(newPassword);
        _showSuccessSnackbar('Sucesso', 'Senha atualizada com sucesso!');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erro ao atualizar senha: ${e.code} - ${e.message}');
      authError.value = _handleAuthException(e);
      _showErrorSnackbar('Erro', authError.value);
    } finally {
      isLoading.value = false;
      update();
    }
  }

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
        await currentUser.value!.getIdToken(true);
        isAuthenticated.value = true;
        _reauthAttempts = 0;

        _showSuccessSnackbar('Sucesso', 'Reautenticação realizada com sucesso!');
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erro na reautenticação: ${e.code} - ${e.message}');
      authError.value = _handleAuthException(e);
      isAuthenticated.value = false;
      _showErrorSnackbar('Erro', authError.value);
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // ========== LOGOUT ==========

  Future<void> signOut() async {
    try {
      debugPrint('=== signOut() ===');
      isLoading.value = true;

      _stopTokenRefreshTimer();

      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('Erro ao fazer logout do Google (pode ser normal): $e');
      }

      await _auth.signOut();

      currentUser.value = null;
      userModel.value = null;
      isAuthenticated.value = false;
      authError.value = '';
      _reauthAttempts = 0;

      debugPrint('✅ Logout realizado com sucesso');
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      debugPrint('❌ Erro ao fazer logout: $e');
      _showErrorSnackbar('Erro', 'Erro ao fazer logout: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // ========== ERROR HANDLERS ==========

  User? _handleFirebaseAuthError(FirebaseAuthException e, String operation) {
    debugPrint('❌ Erro de autenticação Firebase no $operation: ${e.code} - ${e.message}');
    authError.value = _handleAuthException(e);
    isAuthenticated.value = false;

    _showErrorSnackbar('Erro no $operation', authError.value);
    return null;
  }

  User? _handleGeneralAuthError(dynamic e, String operation) {
    debugPrint('❌ Erro geral no $operation: $e');
    authError.value = 'Erro inesperado no $operation';
    isAuthenticated.value = false;

    _showErrorSnackbar('Erro', 'Erro inesperado no $operation');
    return null;
  }

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
      case 'session-expired':
        return 'Sessão expirada. Faça login novamente.';
      default:
        debugPrint('Erro não mapeado: ${e.code} - ${e.message}');
        return e.message ?? 'Ocorreu um erro inesperado. Tente novamente.';
    }
  }

  // ========== UTILITY METHODS ==========

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
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

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
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    );
  }

  Future<void> ensureUserSettingsExist() async {
    final userId = currentUser.value?.uid;
    if (userId == null) {
      debugPrint('❌ UserId é null, não é possível criar configurações');
      return;
    }

    try {
      debugPrint('=== ensureUserSettingsExist() ===');
      await _firebaseService.ensureUserSettingsExist(userId);
      debugPrint('✅ Configurações do usuário verificadas/criadas');
    } catch (e) {
      debugPrint('❌ Erro ao garantir configurações do usuário: $e');
    }
  }

  Future<void> updateUserFcmToken() async {
    try {
      debugPrint('=== updateUserFcmToken() ===');

      final user = currentUser.value;
      if (user == null) {
        debugPrint('❌ Usuário não está logado, não é possível atualizar FCM token');
        return;
      }

      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('❌ FCM Token não disponível');
        return;
      }

      debugPrint('✅ FCM Token obtido: ${fcmToken.substring(0, 20)}...');

      final userDoc = await _firebaseService.getUserData(user.uid);
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final storedToken = userData['fcmToken'] as String?;

        if (storedToken == fcmToken) {
          debugPrint('✅ FCM Token já está atualizado');
          return;
        }
      }

      await _firebaseService.updateUserData(user.uid, {
        'fcmToken': fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'lastAppOpen': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : 'android',
        'appVersion': '1.0.0',
        'tokenSource': 'auth_controller',
      });

      debugPrint('✅ FCM Token atualizado no Firestore com sucesso');

    } catch (e) {
      debugPrint('❌ Erro ao atualizar FCM Token: $e');
    }
  }

  // ========== DIAGNOSTIC METHODS ==========

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

    // 3. Teste de disponibilidade do Apple Sign In
    results['appleSignInAvailable'] = isAppleSignInAvailable.value;

    debugPrint('Diagnósticos completos concluídos');
    return results;
  }
}