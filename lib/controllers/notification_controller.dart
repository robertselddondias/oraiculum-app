import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/services/push_notification_service.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/services/gemini_service.dart';
import 'package:oraculum/utils/zodiac_utils.dart';

class NotificationController extends GetxController {
  final PushNotificationService _notificationService = Get.find<PushNotificationService>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthController _authController = Get.find<AuthController>();
  final GeminiService _geminiService = Get.find<GeminiService>();

  // Observáveis
  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt unreadCount = 0.obs;
  final RxBool hasPermission = false.obs;

  // Configurações de notificação do usuário
  final RxBool generalNotifications = true.obs;
  final RxBool horoscopeNotifications = true.obs;
  final RxBool appointmentNotifications = true.obs;
  final RxBool promotionNotifications = false.obs;
  final RxBool soundEnabled = true.obs;
  final RxBool vibrationEnabled = true.obs;
  final RxString horoscopeTime = '09:00'.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
    _loadUserSettings();
    _setupListeners();
  }

  /// Inicializa o sistema de notificações
  Future<void> _initializeNotifications() async {
    try {
      debugPrint('🔔 Inicializando NotificationController...');

      // Aguardar inicialização do serviço
      await _notificationService.initialize();

      // Atualizar estado baseado no serviço
      hasPermission.value = _notificationService.hasPermission.value;

      // Carregar histórico de notificações
      _loadNotificationHistory();

      debugPrint('✅ NotificationController inicializado');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar NotificationController: $e');
    }
  }

  /// Configura listeners para mudanças
  void _setupListeners() {
    // Listener para mudanças nas notificações do serviço
    ever(_notificationService.notificationHistory, (List<Map<String, dynamic>> history) {
      notifications.value = history;
      _updateUnreadCount();
    });

    // Listener para mudanças na permissão
    ever(_notificationService.hasPermission, (bool permission) {
      hasPermission.value = permission;
    });

    // Listener para mudanças no usuário autenticado
    ever(_authController.userModel, (user) {
      if (user != null) {
        _loadUserSettings();
        _setupUserSpecificNotifications();
      }
    });
  }

  /// Carrega o histórico de notificações
  void _loadNotificationHistory() {
    notifications.value = _notificationService.notificationHistory;
    _updateUnreadCount();
  }

  /// Atualiza o contador de não lidas
  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => n['read'] == false).length;
  }

  /// Carrega as configurações do usuário
  Future<void> _loadUserSettings() async {
    try {
      final userId = _authController.currentUser.value?.uid;
      if (userId == null) return;

      isLoading.value = true;

      final userDoc = await _firebaseService.getUserData(userId);
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final settings = userData['notificationSettings'] as Map<String, dynamic>? ?? {};

        // Atualizar observáveis com as configurações do usuário
        generalNotifications.value = settings['general'] ?? true;
        horoscopeNotifications.value = settings['horoscope'] ?? true;
        appointmentNotifications.value = settings['appointments'] ?? true;
        promotionNotifications.value = settings['promotions'] ?? false;
        soundEnabled.value = settings['sound'] ?? true;
        vibrationEnabled.value = settings['vibration'] ?? true;
        horoscopeTime.value = settings['horoscopeTime'] ?? '09:00';
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar configurações: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Salva as configurações do usuário
  Future<void> saveUserSettings() async {
    try {
      final userId = _authController.currentUser.value?.uid;
      if (userId == null) return;

      final settings = {
        'notificationSettings': {
          'general': generalNotifications.value,
          'horoscope': horoscopeNotifications.value,
          'appointments': appointmentNotifications.value,
          'promotions': promotionNotifications.value,
          'sound': soundEnabled.value,
          'vibration': vibrationEnabled.value,
          'horoscopeTime': horoscopeTime.value,
          'updatedAt': DateTime.now(),
        }
      };

      await _firebaseService.updateUserData(userId, settings);

      // Gerenciar inscrições de tópicos
      await _notificationService.manageUserTopicSubscriptions();

      Get.snackbar(
        'Sucesso',
        'Configurações salvas com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      debugPrint('❌ Erro ao salvar configurações: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível salvar as configurações',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }

  /// Configura notificações específicas do usuário
  Future<void> _setupUserSpecificNotifications() async {
    try {
      final user = _authController.userModel.value;
      if (user == null) return;

      // Inscrever em tópicos baseados no perfil do usuário
      final userSign = ZodiacUtils.getZodiacSignFromDate(user.birthDate!);

      // Inscrições básicas
      await _notificationService.subscribeToTopic('all_users');

      if (horoscopeNotifications.value) {
        await _notificationService.subscribeToTopic('horoscope_daily');
        await _notificationService.subscribeToTopic('horoscope_$userSign');
      }

      if (appointmentNotifications.value) {
        await _notificationService.subscribeToTopic('appointments');
      }

      if (promotionNotifications.value) {
        await _notificationService.subscribeToTopic('promotions');
      }

      debugPrint('✅ Notificações específicas do usuário configuradas');
    } catch (e) {
      debugPrint('❌ Erro ao configurar notificações do usuário: $e');
    }
  }

  /// Envia notificação de horóscopo diário
  Future<void> sendDailyHoroscope() async {
    try {
      final user = _authController.userModel.value;
      if (user == null || !horoscopeNotifications.value) return;

      final userSign = ZodiacUtils.getZodiacSignFromDate(user.birthDate!);

      // Gerar horóscopo usando o Gemini
      final horoscopeText = await _geminiService.getDailyHoroscope(userSign);

      // Extrair primeira linha como título
      final lines = horoscopeText.split('\n');
      final title = lines.isNotEmpty ? '${lines.first.substring(0, 50)}...' : 'Seu Horóscopo de Hoje';
      final body = 'Sua previsão para $userSign está pronta! ✨';

      await _notificationService.sendTestNotification(
        title: title,
        body: body,
        type: 'horoscope',
        data: {
          'type': 'horoscope',
          'sign': userSign,
          'target_id': '',
        },
      );

      debugPrint('📨 Horóscopo diário enviado para $userSign');
    } catch (e) {
      debugPrint('❌ Erro ao enviar horóscopo diário: $e');
    }
  }

  /// Envia notificação de lembrete de consulta
  Future<void> sendAppointmentReminder({
    required String mediumName,
    required DateTime appointmentTime,
    required String appointmentId,
  }) async {
    try {
      if (!appointmentNotifications.value) return;

      const title = 'Consulta Agendada 🔮';
      final body = 'Sua consulta com $mediumName está marcada para hoje às ${appointmentTime.hour}:${appointmentTime.minute.toString().padLeft(2, '0')}';

      await _notificationService.sendTestNotification(
        title: title,
        body: body,
        type: 'appointment',
        data: {
          'type': 'appointment',
          'target_id': appointmentId,
          'medium_name': mediumName,
          'appointment_time': appointmentTime.toIso8601String(),
        },
      );

      debugPrint('📅 Lembrete de consulta enviado');
    } catch (e) {
      debugPrint('❌ Erro ao enviar lembrete de consulta: $e');
    }
  }

  /// Envia notificação de promoção
  Future<void> sendPromotionNotification({
    required String title,
    required String message,
    String? imageUrl,
    Map<String, String>? extraData,
  }) async {
    try {
      if (!promotionNotifications.value) return;

      final data = {
        'type': 'promotion',
        'image_url': imageUrl ?? '',
        ...?extraData,
      };

      await _notificationService.sendTestNotification(
        title: title,
        body: message,
        type: 'promotion',
        data: data,
      );

      debugPrint('🎁 Notificação de promoção enviada');
    } catch (e) {
      debugPrint('❌ Erro ao enviar promoção: $e');
    }
  }

  /// Envia notificação de nova leitura de tarô salva
  Future<void> sendTarotReadingSaved({
    required String readingType,
    required List<String> cards,
  }) async {
    try {
      if (!generalNotifications.value) return;

      const title = 'Leitura Salva ✨';
      final body = 'Sua leitura de $readingType foi salva com sucesso!';

      await _notificationService.sendTestNotification(
        title: title,
        body: body,
        type: 'tarot',
        data: {
          'type': 'tarot',
          'reading_type': readingType,
          'cards': cards.join(','),
        },
      );

      debugPrint('🃏 Notificação de leitura salva enviada');
    } catch (e) {
      debugPrint('❌ Erro ao enviar notificação de leitura: $e');
    }
  }

  /// Envia notificação de créditos baixos
  Future<void> sendLowCreditsNotification({required double currentCredits}) async {
    try {
      if (!generalNotifications.value) return;

      const title = 'Créditos Baixos 💰';
      final body = 'Você tem apenas R\$ ${currentCredits.toStringAsFixed(2)} em créditos. Recarregue agora!';

      await _notificationService.sendTestNotification(
        title: title,
        body: body,
        type: 'promotion',
        data: {
          'type': 'promotion',
          'target_id': 'payment_methods',
          'credits': currentCredits.toString(),
        },
      );

      debugPrint('💸 Notificação de créditos baixos enviada');
    } catch (e) {
      debugPrint('❌ Erro ao enviar notificação de créditos: $e');
    }
  }

  /// Marca uma notificação como lida
  void markAsRead(String notificationId) {
    _notificationService.markAsRead(notificationId);
    _updateUnreadCount();
  }

  /// Marca todas as notificações como lidas
  void markAllAsRead() {
    _notificationService.markAllAsRead();
    unreadCount.value = 0;
  }

  /// Remove uma notificação específica
  void removeNotification(String notificationId) {
    notifications.removeWhere((n) => n['id'] == notificationId);
    _updateUnreadCount();
  }

  /// Limpa todo o histórico
  void clearAllNotifications() {
    _notificationService.clearHistory();
    notifications.clear();
    unreadCount.value = 0;
  }

  /// Solicita permissões de notificação
  Future<void> requestPermissions() async {
    try {
      await _notificationService.initialize();
      hasPermission.value = _notificationService.hasPermission.value;

      if (!hasPermission.value) {
        await _notificationService.openNotificationSettings();
      }
    } catch (e) {
      debugPrint('❌ Erro ao solicitar permissões: $e');
    }
  }

  /// Abre as configurações de notificação do sistema
  Future<void> openSystemSettings() async {
    await _notificationService.openNotificationSettings();
  }

  /// Envia uma notificação de teste
  Future<void> sendTestNotification({
    required String title,
    required String body,
    String type = 'default',
  }) async {
    await _notificationService.sendTestNotification(
      title: title,
      body: body,
      type: type,
    );
  }

  /// Filtra notificações por tipo
  List<Map<String, dynamic>> getNotificationsByType(String type) {
    return notifications.where((n) {
      final notificationType = n['data']?['type'] ?? 'default';
      return notificationType == type;
    }).toList();
  }

  /// Obtém notificações não lidas
  List<Map<String, dynamic>> getUnreadNotifications() {
    return notifications.where((n) => n['read'] == false).toList();
  }

  /// Obtém estatísticas das notificações
  Map<String, dynamic> getNotificationStatistics() {
    final total = notifications.length;
    final unread = unreadCount.value;
    final typeCount = <String, int>{};

    for (var notification in notifications) {
      final type = notification['data']?['type'] ?? 'default';
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }

    return {
      'total': total,
      'unread': unread,
      'read': total - unread,
      'byType': typeCount,
      'hasPermission': hasPermission.value,
      'settings': {
        'general': generalNotifications.value,
        'horoscope': horoscopeNotifications.value,
        'appointments': appointmentNotifications.value,
        'promotions': promotionNotifications.value,
        'sound': soundEnabled.value,
        'vibration': vibrationEnabled.value,
        'horoscopeTime': horoscopeTime.value,
      },
    };
  }

  /// Agenda notificações recorrentes (horóscopo diário)
  Future<void> scheduleDailyHoroscope() async {
    try {
      if (!horoscopeNotifications.value) return;

      final user = _authController.userModel.value;
      if (user == null) return;

      final userSign = ZodiacUtils.getZodiacSignFromDate(user.birthDate!);
      final timeParts = horoscopeTime.value.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Calcular próximo horário de notificação
      final now = DateTime.now();
      var nextNotification = DateTime(now.year, now.month, now.day, hour, minute);

      if (nextNotification.isBefore(now)) {
        nextNotification = nextNotification.add(const Duration(days: 1));
      }

      await _notificationService.scheduleNotification(
        title: 'Seu Horóscopo Diário ✨',
        body: 'Sua previsão para $userSign está pronta!',
        scheduledTime: nextNotification,
        type: 'horoscope',
        data: {
          'type': 'horoscope',
          'sign': userSign,
        },
      );

      debugPrint('📅 Horóscopo diário agendado para ${nextNotification.toString()}');
    } catch (e) {
      debugPrint('❌ Erro ao agendar horóscopo diário: $e');
    }
  }

  /// Cancela todas as notificações agendadas
  Future<void> cancelAllScheduledNotifications() async {
    await _notificationService.cancelAllNotifications();
    debugPrint('🗑️ Todas as notificações agendadas canceladas');
  }

  /// Configura notificações baseadas no perfil do usuário
  Future<void> setupPersonalizedNotifications() async {
    try {
      final user = _authController.userModel.value;
      if (user == null) return;

      // Configurar baseado no signo
      final userSign = ZodiacUtils.getZodiacSignFromDate(user.birthDate!);
      final element = ZodiacUtils.getElement(userSign);

      // Personalizar mensagens baseadas no elemento
      Map<String, String> elementMessages = {
        'Fogo': 'Sua energia ardente está em alta hoje! 🔥',
        'Terra': 'Estabilidade e crescimento marcam seu dia. 🌱',
        'Ar': 'Comunicação e ideias fluem naturalmente. 💨',
        'Água': 'Suas emoções guiam o caminho hoje. 🌊',
      };

      final personalizedMessage = elementMessages[element] ?? 'Um dia especial te aguarda!';

      // Configurar notificações personalizadas
      if (horoscopeNotifications.value) {
        await scheduleDailyHoroscope();
      }

      debugPrint('🎯 Notificações personalizadas configuradas para $userSign ($element)');
    } catch (e) {
      debugPrint('❌ Erro ao configurar notificações personalizadas: $e');
    }
  }

  /// Envia notificação de boas-vindas para novos usuários
  Future<void> sendWelcomeNotification() async {
    try {
      final user = _authController.userModel.value;
      if (user == null) return;

      final firstName = user.name.split(' ').first;
      final userSign = ZodiacUtils.getZodiacSignFromDate(user.birthDate!);

      await _notificationService.sendTestNotification(
        title: 'Bem-vindo(a) ao Oraculum, $firstName! 🌟',
        body: 'Sua jornada espiritual começa agora. Descubra o que o universo tem para você como $userSign!',
        type: 'default',
        data: {
          'type': 'welcome',
          'user_sign': userSign,
          'target_id': 'navigation',
        },
      );

      debugPrint('👋 Notificação de boas-vindas enviada');
    } catch (e) {
      debugPrint('❌ Erro ao enviar notificação de boas-vindas: $e');
    }
  }

  /// Verifica e envia notificações de aniversário
  Future<void> checkBirthdayNotification() async {
    try {
      final user = _authController.userModel.value;
      if (user == null || !generalNotifications.value) return;

      final now = DateTime.now();
      final birthday = user.birthDate;

      // Verificar se é aniversário hoje
      if (now.month == birthday!.month && now.day == birthday.day) {
        final age = now.year - birthday.year;
        final firstName = user.name.split(' ').first;

        await _notificationService.sendTestNotification(
          title: 'Feliz Aniversário, $firstName! 🎉',
          body: 'Completando $age anos hoje! Que este novo ciclo seja repleto de descobertas espirituais e crescimento.',
          type: 'default',
          data: {
            'type': 'birthday',
            'age': age.toString(),
            'target_id': 'horoscope',
          },
        );

        debugPrint('🎂 Notificação de aniversário enviada');
      }
    } catch (e) {
      debugPrint('❌ Erro ao verificar aniversário: $e');
    }
  }

  /// Reseta todas as configurações de notificação
  Future<void> resetNotificationSettings() async {
    try {
      // Resetar para valores padrão
      generalNotifications.value = true;
      horoscopeNotifications.value = true;
      appointmentNotifications.value = true;
      promotionNotifications.value = false;
      soundEnabled.value = true;
      vibrationEnabled.value = true;
      horoscopeTime.value = '09:00';

      // Salvar no Firestore
      await saveUserSettings();

      // Resetar serviço
      await _notificationService.reset();

      // Reinicializar
      await _initializeNotifications();

      Get.snackbar(
        'Sucesso',
        'Configurações de notificação resetadas',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      debugPrint('🔄 Configurações de notificação resetadas');
    } catch (e) {
      debugPrint('❌ Erro ao resetar configurações: $e');
    }
  }

  @override
  void onClose() {
    debugPrint('🧹 NotificationController finalizando...');
    super.onClose();
  }
}