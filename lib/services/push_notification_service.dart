import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/services/firebase_service.dart';

/// Serviço simplificado de Push Notifications para o Oraculum
class PushNotificationService extends GetxService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final FirebaseService _firebaseService = Get.find<FirebaseService>();

  // Observáveis para controle de estado
  final RxBool isInitialized = false.obs;
  final RxBool hasPermission = false.obs;
  final RxString deviceToken = ''.obs;
  final RxInt notificationCount = 0.obs;
  final RxList<Map<String, dynamic>> notificationHistory = <Map<String, dynamic>>[].obs;

  // Canal padrão simplificado
  static const AndroidNotificationChannel _defaultChannel = AndroidNotificationChannel(
    'oraculum_notifications',
    'Notificações do Oraculum',
    description: 'Notificações gerais do aplicativo Oraculum',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  @override
  Future<void> onInit() async {
    super.onInit();
    await initialize();
  }

  /// Inicializa o serviço de push notifications
  Future<void> initialize() async {
    try {
      debugPrint('🔔 Inicializando PushNotificationService...');

      // 1. Configurar notificações locais
      await _setupLocalNotifications();

      // 2. Solicitar permissões
      await _requestPermissions();

      // 3. Obter token do dispositivo
      await _getDeviceToken();

      // 4. Configurar listeners
      _setupMessageListeners();

      isInitialized.value = true;
      debugPrint('✅ PushNotificationService inicializado com sucesso');
      await checkAndUpdateToken();
    } catch (e) {
      debugPrint('❌ Erro ao inicializar PushNotificationService: $e');
      isInitialized.value = false;
    }
  }

  /// Configura as notificações locais
  Future<void> _setupLocalNotifications() async {
    try {
      debugPrint('🔧 Configurando notificações locais...');

      // Configurações Android
      const androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configurações iOS
      const iosInitializationSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );

      await _localNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Criar canal no Android
      if (Platform.isAndroid) {
        final androidPlugin = _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        await androidPlugin?.createNotificationChannel(_defaultChannel);
      }

      debugPrint('✅ Notificações locais configuradas');
    } catch (e) {
      debugPrint('❌ Erro ao configurar notificações locais: $e');
    }
  }

  /// Solicita permissões de notificação
  Future<void> _requestPermissions() async {
    try {
      debugPrint('🔐 Solicitando permissões de notificação...');

      // Permissões Firebase Messaging
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      hasPermission.value = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      debugPrint('📝 Status da permissão: ${settings.authorizationStatus}');

      // Permissões adicionais no Android
      if (Platform.isAndroid) {
        final notificationStatus = await Permission.notification.request();
        debugPrint('📱 Permissão Android: $notificationStatus');
      }

      if (hasPermission.value) {
        debugPrint('✅ Permissões de notificação concedidas');
      } else {
        debugPrint('⚠️ Permissões de notificação negadas');
      }

    } catch (e) {
      debugPrint('❌ Erro ao solicitar permissões: $e');
      hasPermission.value = false;
    }
  }

  /// Obtém o token do dispositivo
  Future<void> _getDeviceToken() async {
    try {
      debugPrint('🎫 Obtendo token do dispositivo...');

      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        deviceToken.value = token;
        debugPrint('✅ Token obtido: ${token.substring(0, 20)}...');

        // Salvar token no Firestore
        await _saveTokenToFirestore(token);
      }

      // Listener para atualizações do token
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        debugPrint('🔄 Token atualizado automaticamente: ${newToken.substring(0, 20)}...');
        deviceToken.value = newToken;

        await _saveTokenToFirestore(newToken);

        try {
          final authController = Get.find<AuthController>();
          await authController.updateUserFcmToken();
        } catch (e) {
          debugPrint('⚠️ AuthController não disponível: $e');
        }
      });

    } catch (e) {
      debugPrint('❌ Erro ao obter token: $e');
    }
  }

  /// Salva o token no Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final userId = _firebaseService.userId;
      if (userId != null) {
        await _firebaseService.updateUserData(userId, {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'lastTokenUpdate': DateTime.now().toIso8601String(),
          'platform': Platform.isIOS ? 'ios' : 'android',
          'appVersion': '1.0.0',
          'tokenSource': 'push_notification_service',
        });

        debugPrint('💾 Token FCM salvo no Firestore via PushNotificationService');
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar token no Firestore: $e');
    }
  }

  /// Configura os listeners de mensagens
  void _setupMessageListeners() {
    debugPrint('👂 Configurando listeners de mensagens...');

    // Mensagens recebidas quando o app está em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 Mensagem recebida em primeiro plano: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Mensagens que abrem o app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📂 App aberto por notificação: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Verificar se o app foi aberto por uma notificação
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🚀 App iniciado por notificação: ${message.messageId}');
        Future.delayed(const Duration(seconds: 2), () {
          _handleNotificationTap(message);
        });
      }
    });

    debugPrint('✅ Listeners configurados');
  }

  /// Processa mensagens recebidas em primeiro plano
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      debugPrint('🔔 Processando mensagem em primeiro plano...');

      // Adicionar ao histórico
      _addToHistory(message);

      // Mostrar notificação local
      await _showLocalNotification(message);

      // Incrementar contador
      notificationCount.value++;

    } catch (e) {
      debugPrint('❌ Erro ao processar mensagem: $e');
    }
  }

  /// Mostra uma notificação local simplificada
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      const androidDetails = AndroidNotificationDetails(
        'oraculum_notifications',
        'Notificações do Oraculum',
        channelDescription: 'Notificações gerais do aplicativo Oraculum',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF6C63FF),
        // Usar apenas BigTextStyleInformation para evitar erros
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotificationsPlugin.show(
        message.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );

      debugPrint('📱 Notificação local exibida');

    } catch (e) {
      debugPrint('❌ Erro ao mostrar notificação local: $e');
    }
  }

  /// Trata o toque na notificação local
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Notificação local tocada: ${response.id}');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _navigateBasedOnData(data);
      } catch (e) {
        debugPrint('❌ Erro ao processar payload: $e');
      }
    }
  }

  /// Trata o toque na notificação do Firebase
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notificação Firebase tocada: ${message.messageId}');
    _navigateBasedOnData(message.data);
  }

  /// Navega baseado nos dados da notificação
  void _navigateBasedOnData(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final targetId = data['target_id'] ?? '';

    switch (type) {
      case 'horoscope':
        Get.toNamed(AppRoutes.horoscope);
        break;
      // case 'appointment':
      //   if (targetId.isNotEmpty) {
      //     Get.toNamed('${AppRoutes.mediumDetail}/$targetId');
      //   } else {
      //     Get.toNamed(AppRoutes.mediums);
      //   }
      //   break;
      case 'tarot':
        Get.toNamed(AppRoutes.tarotReading);
        break;
      case 'promotion':
        Get.toNamed(AppRoutes.paymentMethods);
        break;
      case 'profile':
        Get.toNamed(AppRoutes.profile);
        break;
      default:
        Get.toNamed(AppRoutes.navigation);
        break;
    }
  }

  /// Adiciona a mensagem ao histórico
  void _addToHistory(RemoteMessage message) {
    final historyItem = {
      'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': message.notification?.title ?? 'Notificação',
      'body': message.notification?.body ?? '',
      'data': message.data,
      'timestamp': DateTime.now(),
      'read': false,
    };

    notificationHistory.insert(0, historyItem);

    // Manter apenas as últimas 50 notificações
    if (notificationHistory.length > 50) {
      notificationHistory.removeRange(50, notificationHistory.length);
    }
  }

  /// Envia uma notificação de teste
  Future<void> sendTestNotification({
    required String title,
    required String body,
    String type = 'default',
    Map<String, String>? data,
  }) async {
    try {
      debugPrint('🧪 Enviando notificação de teste...');

      const androidDetails = AndroidNotificationDetails(
        'oraculum_notifications',
        'Notificações do Oraculum',
        channelDescription: 'Notificações gerais do aplicativo Oraculum',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF6C63FF),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: data != null ? jsonEncode(data) : null,
      );

      debugPrint('✅ Notificação de teste enviada');

    } catch (e) {
      debugPrint('❌ Erro ao enviar notificação de teste: $e');
    }
  }

  /// Agenda uma notificação para o futuro (implementação básica)
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String type = 'default',
    Map<String, String>? data,
  }) async {
    try {
      debugPrint('📅 Agendando notificação para: $scheduledTime');

      // Nota: Para agendamento real, seria necessário usar scheduled notifications
      // Por enquanto, apenas registramos a intenção
      debugPrint('✅ Notificação agendada (implementação básica)');

    } catch (e) {
      debugPrint('❌ Erro ao agendar notificação: $e');
    }
  }

  /// Cancela todas as notificações pendentes
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotificationsPlugin.cancelAll();
      debugPrint('🗑️ Todas as notificações canceladas');
    } catch (e) {
      debugPrint('❌ Erro ao cancelar notificações: $e');
    }
  }

  /// Marca uma notificação como lida
  void markAsRead(String notificationId) {
    final index = notificationHistory.indexWhere((item) => item['id'] == notificationId);
    if (index != -1) {
      notificationHistory[index]['read'] = true;
      notificationHistory.refresh();
    }
  }

  /// Marca todas as notificações como lidas
  void markAllAsRead() {
    for (var item in notificationHistory) {
      item['read'] = true;
    }
    notificationHistory.refresh();
    notificationCount.value = 0;
  }

  /// Limpa o histórico de notificações
  void clearHistory() {
    notificationHistory.clear();
    notificationCount.value = 0;
  }

  /// Obtém o número de notificações não lidas
  int get unreadCount {
    return notificationHistory.where((item) => item['read'] == false).length;
  }

  /// Verifica se as notificações estão habilitadas
  Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        return status.isGranted;
      } else {
        final settings = await _firebaseMessaging.getNotificationSettings();
        return settings.authorizationStatus == AuthorizationStatus.authorized;
      }
    } catch (e) {
      debugPrint('❌ Erro ao verificar status das notificações: $e');
      return false;
    }
  }

  /// Abre as configurações de notificação do sistema
  Future<void> openNotificationSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('❌ Erro ao abrir configurações: $e');
    }
  }

  /// Subscreve a um tópico de notificação
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('📮 Inscrito no tópico: $topic');
    } catch (e) {
      debugPrint('❌ Erro ao se inscrever no tópico $topic: $e');
    }
  }

  /// Desinscreve de um tópico de notificação
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('📭 Desinscrito do tópico: $topic');
    } catch (e) {
      debugPrint('❌ Erro ao se desinscrever do tópico $topic: $e');
    }
  }

  /// Gerencia inscrições baseadas no perfil do usuário
  Future<void> manageUserTopicSubscriptions() async {
    try {
      final userId = _firebaseService.userId;
      if (userId == null) return;

      final userDoc = await _firebaseService.getUserData(userId);
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;

      // Inscrever em tópicos básicos
      await subscribeToTopic('all_users');

      // Gerenciar baseado em configurações
      final settings = userData['notificationSettings'] as Map<String, dynamic>? ?? {};

      if (settings['horoscope'] ?? true) {
        await subscribeToTopic('horoscope_daily');
      } else {
        await unsubscribeFromTopic('horoscope_daily');
      }

      if (settings['promotions'] ?? false) {
        await subscribeToTopic('promotions');
      } else {
        await unsubscribeFromTopic('promotions');
      }

      debugPrint('✅ Inscrições de tópicos atualizadas');
    } catch (e) {
      debugPrint('❌ Erro ao gerenciar inscrições: $e');
    }
  }

  /// Retorna estatísticas das notificações
  Map<String, dynamic> getNotificationStats() {
    final total = notificationHistory.length;
    final unread = unreadCount;
    final typeCount = <String, int>{};

    for (var notification in notificationHistory) {
      final type = notification['data']?['type'] ?? 'default';
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }

    return {
      'total': total,
      'unread': unread,
      'read': total - unread,
      'byType': typeCount,
      'hasPermission': hasPermission.value,
      'isInitialized': isInitialized.value,
      'deviceToken': deviceToken.value.isNotEmpty,
    };
  }

  /// Reseta o serviço
  Future<void> reset() async {
    try {
      await cancelAllNotifications();
      clearHistory();

      // Desinscrever de tópicos conhecidos
      final topics = ['all_users', 'horoscope_daily', 'promotions'];
      for (final topic in topics) {
        await unsubscribeFromTopic(topic);
      }

      isInitialized.value = false;
      hasPermission.value = false;
      deviceToken.value = '';
      notificationCount.value = 0;

      debugPrint('🔄 PushNotificationService resetado');
    } catch (e) {
      debugPrint('❌ Erro ao resetar serviço: $e');
    }
  }

  Future<void> forceTokenUpdate() async {
    try {
      debugPrint('🔄 Forçando atualização do FCM Token...');

      // Deletar o token atual
      await _firebaseMessaging.deleteToken();

      // Obter um novo token
      final newToken = await _firebaseMessaging.getToken();

      if (newToken != null) {
        deviceToken.value = newToken;
        debugPrint('✅ Novo token FCM obtido: ${newToken.substring(0, 20)}...');

        // Salvar o novo token
        await _saveTokenToFirestore(newToken);

        // Atualizar também via AuthController se estiver disponível
        try {
          final authController = Get.find<AuthController>();
          await authController.updateUserFcmToken();
        } catch (e) {
          debugPrint('⚠️ AuthController não disponível: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao forçar atualização do token: $e');
    }
  }

  /// Verificar e atualizar token se necessário
  Future<void> checkAndUpdateToken() async {
    try {
      debugPrint('🔍 Verificando necessidade de atualização do token...');

      final userId = _firebaseService.userId;
      if (userId == null) return;

      // Obter token atual
      final currentToken = await _firebaseMessaging.getToken();
      if (currentToken == null) return;

      // Verificar se é diferente do armazenado
      final userDoc = await _firebaseService.getUserData(userId);
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final storedToken = userData['fcmToken'] as String?;

        if (storedToken != currentToken) {
          debugPrint('🔄 Token FCM mudou, atualizando...');
          deviceToken.value = currentToken;
          await _saveTokenToFirestore(currentToken);
        } else {
          debugPrint('✅ Token FCM está atualizado');
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao verificar token: $e');
    }
  }

  @override
  void onClose() {
    debugPrint('🧹 PushNotificationService finalizando...');
    super.onClose();
  }
}