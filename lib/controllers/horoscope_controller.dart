import 'package:get/get.dart';
import 'package:oraculum/services/gemini_service.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/models/horoscope_model.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:oraculum/controllers/auth_controller.dart';

class HoroscopeController extends GetxController {
  final GeminiService _geminiService = Get.find<GeminiService>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final PaymentController _paymentController = Get.find<PaymentController>();
  final AuthController _authController = Get.find<AuthController>();

  RxBool isLoading = false.obs;
  RxString currentSign = ''.obs;
  Rx<HoroscopeModel?> dailyHoroscope = Rx<HoroscopeModel?>(null);
  RxList<String> zodiacSigns = <String>[
    'Áries', 'Touro', 'Gêmeos', 'Câncer',
    'Leão', 'Virgem', 'Libra', 'Escorpião',
    'Sagitário', 'Capricórnio', 'Aquário', 'Peixes'
  ].obs;

  // Custo para gerar um mapa astral (em R$)
  final double birthChartCost = 20.0;

  Future<void> getDailyHoroscope(String sign) async {
    try {
      isLoading.value = true;
      currentSign.value = sign;

      // Formatar data atual
      final today = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(today);

      // Verificar se já existe no Firestore
      final horoscopeDoc = await _firebaseService.getDailyHoroscope(sign, formattedDate);

      if (horoscopeDoc.exists) {
        // Usar horóscopo existente
        final data = horoscopeDoc.data() as Map<String, dynamic>;
        dailyHoroscope.value = HoroscopeModel.fromMap(data, horoscopeDoc.id);
      } else {
        // Gerar novo horóscopo com Gemini
        final horoscopeText = await _geminiService.getDailyHoroscope(sign);

        // Salvar no Firestore
        final horoscopeData = {
          'sign': sign,
          'date': today,
          'content': horoscopeText,
          'createdAt': today,
        };

        await _firebaseService.saveHoroscope('$sign-$formattedDate', horoscopeData);

        // Atualizar o estado
        dailyHoroscope.value = HoroscopeModel(
          id: '$sign-$formattedDate',
          sign: sign,
          date: today,
          content: horoscopeText,
          createdAt: today,
        );
      }
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível carregar o horóscopo: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<String> getCompatibilityAnalysis(String sign1, String sign2) async {
    try {
      isLoading.value = true;
      final compatibilityText = await _geminiService.getCompatibilityAnalysis(sign1, sign2);
      return compatibilityText;
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível gerar a análise de compatibilidade: $e');
      return 'Erro ao gerar análise de compatibilidade.';
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<Map<String, dynamic>> processBirthChartPayment() async {
    try {
      if (_authController.currentUser.value == null) {
        return {
          'success': false,
          'message': 'Você precisa estar logado para gerar um mapa astral'
        };
      }

      final userId = _authController.currentUser.value!.uid;

      // Verificar se o usuário tem créditos suficientes
      final hasCredits = await _paymentController.checkUserCredits(userId, birthChartCost);
      if (!hasCredits) {
        return {
          'success': false,
          'message': 'Créditos insuficientes. Você precisa de R\$ $birthChartCost para gerar um mapa astral.'
        };
      }

      // Processar o pagamento
      final paymentDescription = 'Geração de Mapa Astral';
      final serviceId = 'birthchart-${DateTime.now().millisecondsSinceEpoch}';
      final paymentId = await _paymentController.processPaymentWithCredits(
          userId,
          birthChartCost,
          paymentDescription,
          serviceId,
          'birthchart'
      );

      if (paymentId.isEmpty) {
        return {
          'success': false,
          'message': 'Falha ao processar o pagamento. Tente novamente.'
        };
      }

      return {
        'success': true,
        'message': 'Pagamento processado com sucesso!',
        'paymentId': paymentId
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ocorreu um erro: $e'
      };
    }
  }

  Future<Map<String, dynamic>> getBirthChartInterpretation(
      DateTime birthDate,
      String birthTime,
      String birthPlace,
      ) async {
    try {
      isLoading.value = true;

      // Processar pagamento primeiro
      final paymentResult = await processBirthChartPayment();
      if (!paymentResult['success']) {
        return {
          'success': false,
          'message': paymentResult['message']
        };
      }

      // Gerar a interpretação
      final chartInterpretation = await _geminiService.getBirthChartInterpretation(
        birthDate,
        birthTime,
        birthPlace,
      );

      // Salvar a interpretação no histórico do usuário
      if (_authController.currentUser.value != null) {
        final userId = _authController.currentUser.value!.uid;
        final birthdateFormatted = DateFormat('dd/MM/yyyy').format(birthDate);

        await _firebaseService.firestore.collection('birth_charts').add({
          'userId': userId,
          'birthDate': birthDate,
          'birthTime': birthTime,
          'birthPlace': birthPlace,
          'interpretation': chartInterpretation,
          'createdAt': DateTime.now(),
          'paymentId': paymentResult['paymentId']
        });
      }

      return {
        'success': true,
        'interpretation': chartInterpretation
      };
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível interpretar o mapa astral: $e');
      return {
        'success': false,
        'message': 'Erro ao interpretar o mapa astral: $e'
      };
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Função para obter o histórico de mapas astrais do usuário
  Future<List<Map<String, dynamic>>> getUserBirthCharts() async {
    try {
      if (_authController.currentUser.value == null) {
        return [];
      }

      final userId = _authController.currentUser.value!.uid;
      final snapshot = await _firebaseService.firestore
          .collection('birth_charts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível carregar seu histórico de mapas astrais: $e');
      return [];
    }
  }
}