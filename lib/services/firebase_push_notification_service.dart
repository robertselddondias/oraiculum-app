import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebasePushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidNotificationChannel = AndroidNotificationChannel(
    'high_importance_channel', // ID do canal
    'High Importance Notifications', // Nome do canal
    description: 'Este canal é usado para notificações importantes.',
    importance: Importance.high,
  );

  // Inicializar notificações
  static Future<void> initialize() async {
    // Solicitar permissões no iOS
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configuração inicial para notificações locais
    const androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitializationSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          // Ação ao clicar na notificação
          print('Notificação clicada com payload: ${response.payload}');
        }
      },
    );

    // Configurar o canal no Android
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidNotificationChannel);

    // Listeners para mensagens
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Ação ao abrir o app pela notificação
      print('Notificação aberta: ${message.data}');
    });


  }

  // Exibir notificação local
  static Future<void> _showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final androidDetails = notification?.android;

    if (notification != null && androidDetails != null) {
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'Este canal é usado para notificações importantes.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      await _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );
    }
  }

  // Obter token do dispositivo
  static Future<String?> getDeviceToken() async {
    return await _firebaseMessaging.getToken();
  }
}