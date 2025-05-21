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
import 'package:oraculum/services/efi_payment_service.dart';

class InitialBinding implements Bindings {
  @override
  void dependencies() {
    // First, initialize all services
    Get.put(FirebaseService());

    const apiKey = 'AIzaSyD2aGQjaAvnlm75UwuEsT6QR0R9jZ1bKW0';
    Get.put(GeminiService(apiKey: apiKey));

    Get.put(PaymentService());
    Get.put(PagarmeWalletService());
    Get.put(PagarmeService());

    // EfiPay service initialization with sandbox credentials
    Get.put(EfiPayService(
      clientId: 'Client_Id_f8157c294c8b932edeadc2d141467641bd8f9758',
      clientSecret: 'Client_Secret_da63f0aa39041e6362449a2dfcdde677e0189fbc',
      certificatePath: 'assets/certificates/oraculum_hml.pem', // Path to your certificate file
      accountId: '768102-1', // Your EfiPay account ID
      isSandbox: true,
    ));

    // Second, initialize base controllers that others might depend on
    Get.put(AuthController(), permanent: true);
    Get.put(PaymentController());

    // Finally, initialize controllers that depend on others
    Get.put(MediumController());
    Get.put(TarotController());
    Get.put(HoroscopeController());
    Get.put(CardListController());
    Get.put(NewCreditCardController());
  }
}