import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:oraculum/controllers/medium_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:oraculum/controllers/tarot_controller.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/services/gemini_service.dart';
import 'package:oraculum/services/payment_service.dart';

class InitialBinding implements Bindings {
  @override
  void dependencies() {
    // Serviços
    Get.put(FirebaseService());

    // Inicializar GeminiService com a API key do .env
    final apiKey = 'AIzaSyD2aGQjaAvnlm75UwuEsT6QR0R9jZ1bKW0';
    Get.put(GeminiService(apiKey: apiKey));

    Get.put(PaymentService());

    // Controladores
    Get.put(AuthController(), permanent: true);
    Get.lazyPut(() => HoroscopeController());
    Get.lazyPut(() => TarotController());
    Get.lazyPut(() => MediumController());
    Get.lazyPut(() => PaymentController());
  }
}