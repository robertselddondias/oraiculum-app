import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/services/firebase_service.dart';

class SettingsController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthController _authController = Get.find<AuthController>();

  // Estados observáveis das configurações originais
  RxBool isLoading = false.obs;
  RxBool isDarkMode = false.obs;
  RxBool notificationsEnabled = true.obs;
  RxBool emailNotifications = true.obs;
  RxString selectedLanguage = 'Português'.obs;

  String? get userId => _authController.currentUser.value?.uid;

  @override
  void onInit() {
    super.onInit();
    debugPrint('=== SettingsController.onInit() ===');
    loadSettings();
  }

  /// Carregar configurações do usuário
  Future<void> loadSettings() async {
    if (userId == null) {
      debugPrint('❌ Usuário não logado');
      return;
    }

    try {
      isLoading.value = true;

      debugPrint('Carregando configurações para usuário: $userId');

      // Primeiro garantir que as configurações existem
      await _firebaseService.ensureUserSettingsExist(userId!);

      // Depois carregar as configurações
      final settings = await _firebaseService.getUserSettings(userId!);

      // Atualizar apenas as configurações que existiam originalmente
      isDarkMode.value = settings['isDarkMode'] ?? false;
      notificationsEnabled.value = settings['notificationsEnabled'] ?? true;
      emailNotifications.value = settings['emailNotifications'] ?? true;
      selectedLanguage.value = settings['language'] ?? 'Português';

      // Aplicar o tema carregado
      if (isDarkMode.value) {
        Get.changeThemeMode(ThemeMode.dark);
      } else {
        Get.changeThemeMode(ThemeMode.light);
      }

      debugPrint('✅ Configurações carregadas com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao carregar configurações: $e');
      _showErrorSnackbar('Erro', 'Não foi possível carregar as configurações');

      // Em caso de erro, usar valores padrão
      isDarkMode.value = false;
      notificationsEnabled.value = true;
      emailNotifications.value = true;
      selectedLanguage.value = 'Português';
    } finally {
      isLoading.value = false;
    }
  }

  /// Alterar modo escuro
  Future<void> toggleDarkMode(bool value) async {
    try {
      isDarkMode.value = value;

      // Aplicar tema imediatamente
      Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);

      // Salvar no Firebase
      await _saveSetting('isDarkMode', value);

      debugPrint('✅ Modo escuro alterado para: $value');
    } catch (e) {
      debugPrint('❌ Erro ao alterar modo escuro: $e');
      // Reverter em caso de erro
      isDarkMode.value = !value;
      Get.changeThemeMode(!value ? ThemeMode.dark : ThemeMode.light);
      _showErrorSnackbar('Erro', 'Não foi possível alterar o tema');
    }
  }

  /// Alterar notificações
  Future<void> toggleNotifications(bool value) async {
    try {
      notificationsEnabled.value = value;
      await _saveSetting('notificationsEnabled', value);
      debugPrint('✅ Notificações alteradas para: $value');
    } catch (e) {
      debugPrint('❌ Erro ao alterar notificações: $e');
      // Reverter em caso de erro
      notificationsEnabled.value = !value;
      _showErrorSnackbar('Erro', 'Não foi possível alterar as notificações');
    }
  }

  /// Alterar notificações por email
  Future<void> toggleEmailNotifications(bool value) async {
    try {
      emailNotifications.value = value;
      await _saveSetting('emailNotifications', value);
      debugPrint('✅ Notificações por email alteradas para: $value');
    } catch (e) {
      debugPrint('❌ Erro ao alterar notificações por email: $e');
      // Reverter em caso de erro
      emailNotifications.value = !value;
      _showErrorSnackbar('Erro', 'Não foi possível alterar as notificações por email');
    }
  }

  /// Alterar idioma
  Future<void> changeLanguage(String language) async {
    try {
      selectedLanguage.value = language;
      await _saveSetting('language', language);
      debugPrint('✅ Idioma alterado para: $language');
    } catch (e) {
      debugPrint('❌ Erro ao alterar idioma: $e');
      _showErrorSnackbar('Erro', 'Não foi possível alterar o idioma');
    }
  }

  /// Salvar uma configuração no Firebase
  Future<void> _saveSetting(String key, dynamic value) async {
    if (userId == null) {
      debugPrint('❌ UserId é null, não é possível salvar');
      return;
    }

    try {
      await _firebaseService.updateUserSetting(userId!, key, value);
      debugPrint('✅ Configuração $key salva: $value');
    } catch (e) {
      debugPrint('❌ Erro ao salvar configuração $key: $e');
      // Re-throw o erro para que os métodos acima possam reverter as mudanças
      throw e;
    }
  }

  /// Resetar todas as configurações para padrão
  Future<void> resetToDefaults() async {
    if (userId == null) {
      _showErrorSnackbar('Erro', 'Usuário não está logado');
      return;
    }

    try {
      isLoading.value = true;

      final defaultSettings = {
        'isDarkMode': false,
        'notificationsEnabled': true,
        'emailNotifications': true,
        'language': 'Português',
      };

      await _firebaseService.saveUserSettings(userId!, defaultSettings);

      // Atualizar valores locais
      isDarkMode.value = false;
      notificationsEnabled.value = true;
      emailNotifications.value = true;
      selectedLanguage.value = 'Português';

      // Aplicar tema padrão
      Get.changeThemeMode(ThemeMode.light);

      _showSuccessSnackbar('Sucesso', 'Configurações resetadas para os padrões');
      debugPrint('✅ Configurações resetadas com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao resetar configurações: $e');
      _showErrorSnackbar('Erro', 'Não foi possível resetar as configurações');
    } finally {
      isLoading.value = false;
    }
  }

  /// Forçar recriação das configurações
  Future<void> recreateSettings() async {
    if (userId == null) {
      _showErrorSnackbar('Erro', 'Usuário não está logado');
      return;
    }

    try {
      isLoading.value = true;
      debugPrint('🔄 Recriando configurações do usuário...');

      await _firebaseService.ensureUserSettingsExist(userId!);
      await loadSettings();

      _showSuccessSnackbar('Sucesso', 'Configurações recriadas com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao recriar configurações: $e');
      _showErrorSnackbar('Erro', 'Não foi possível recriar as configurações');
    } finally {
      isLoading.value = false;
    }
  }

  /// Método de conveniência para mostrar snackbar de sucesso
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

  /// Método de conveniência para mostrar snackbar de erro
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
}