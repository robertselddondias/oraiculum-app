import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:oraculum/controllers/medium_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:oraculum/controllers/tarot_controller.dart';
import 'package:oraculum/controllers/notification_controller.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/services/gemini_service.dart';
import 'package:oraculum/services/payment_service.dart';
import 'package:oraculum/services/stripe_payment_service.dart';
import 'package:oraculum/services/push_notification_service.dart';

class InitialBinding implements Bindings {

  @override
  void dependencies() {
    // Services - ordem de inicialização importante
    Get.put(FirebaseService(), permanent: true);
    Get.put(GeminiService(apiKey: 'AIzaSyD2aGQjaAvnlm75UwuEsT6QR0R9jZ1bKW0'), permanent: true);
    Get.put(PaymentService(), permanent: true);

    // Stripe Service - deve ser inicializado após Firebase
    Get.put(StripePaymentService(), permanent: true);

    // IMPORTANTE: Push Notification Service ANTES do AuthController
    Get.put(PushNotificationService(), permanent: true);

    // Base controllers
    Get.put(AuthController(), permanent: true);
    Get.put(PaymentController(), permanent: true);

    // Notification Controller - deve ser inicializado após o serviço de notificações
    Get.put(NotificationController(), permanent: true);

    // Feature controllers
    Get.put(MediumController(), permanent: true);
    Get.put(TarotController(), permanent: true);
    Get.put(HoroscopeController(), permanent: true);
  }
}