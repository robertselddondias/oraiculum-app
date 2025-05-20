import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/creditcard_controller.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:oraculum/controllers/medium_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:oraculum/controllers/tarot_controller.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/services/gemini_service.dart';
import 'package:oraculum/services/pagarme_service.dart';
import 'package:oraculum/services/pagarme_wallet_service.dart';
import 'package:oraculum/services/payment_service.dart';

class InitialBinding implements Bindings {
  @override
  void dependencies() {
    // First, initialize all services
    Get.put(FirebaseService());

    final apiKey = 'AIzaSyD2aGQjaAvnlm75UwuEsT6QR0R9jZ1bKW0';
    Get.put(GeminiService(apiKey: apiKey));

    Get.put(PaymentService());
    Get.put(PagarmeWalletService());
    Get.put(PagarmeService());

    // Second, initialize base controllers that others might depend on
    Get.put(AuthController(), permanent: true);
    Get.put(PaymentController());

    // Finally, initialize controllers that depend on others
    Get.put(MediumController());
    Get.put(TarotController());
    Get.put(HoroscopeController());
    Get.put(CreditCardController());
  }
}