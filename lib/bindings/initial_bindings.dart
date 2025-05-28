import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/card_list_controller.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:oraculum/controllers/medium_controller.dart';
import 'package:oraculum/controllers/new_credit_card_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:oraculum/controllers/tarot_controller.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/services/gemini_service.dart';
import 'package:oraculum/services/pagarme_service.dart';
import 'package:oraculum/services/pagarme_wallet_service.dart';
import 'package:oraculum/services/payment_service.dart';
import 'package:oraculum/services/stripe_payment_service.dart';

class InitialBinding implements Bindings {
  @override
  void dependencies() {
    // Services
    Get.put(FirebaseService(), permanent: true);
    Get.put(GeminiService(apiKey: 'AIzaSyD2aGQjaAvnlm75UwuEsT6QR0R9jZ1bKW0'), permanent: true);
    Get.put(PaymentService(), permanent: true);
    Get.put(PagarmeWalletService(), permanent: true);
    Get.put(PagarmeService(), permanent: true);
    Get.put(StripePaymentService(), permanent: true);

    // Base controllers
    Get.put(AuthController(), permanent: true);
    Get.put(PaymentController(), permanent: true);

    // Feature controllers
    Get.put(MediumController(), permanent: true);
    Get.put(TarotController(), permanent: true);
    Get.put(HoroscopeController(), permanent: true);
    Get.put(CardListController(), permanent: true);
    Get.put(NewCreditCardController());
  }
}