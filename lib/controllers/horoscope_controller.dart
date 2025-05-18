import 'package:get/get.dart';
import 'package:oraculum/services/gemini_service.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/models/horoscope_model.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'dart:convert';

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
        final horoscopeText = await _generateStructuredHoroscope(sign);

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

  // Gerar horóscopo estruturado em formato JSON
  Future<String> _generateStructuredHoroscope(String sign) async {
    try {
      // Solicitação ao Gemini para retornar um horóscopo estruturado
      final prompt = '''
        Gere um horóscopo para o signo de $sign no formato JSON com os seguintes tópicos:
        
        1. Uma visão geral do dia ("geral")
        2. Perspectivas para amor e relacionamentos ("amor")
        3. Perspectivas para carreira e finanças ("profissional")
        4. Conselhos gerais para o dia ("conselhos")
        5. Seis números da sorte aleatórios entre 1 e 60 ("numeros_sorte")
        
        Para cada um dos tópicos 1-4, inclua um "title" e um "body". 
        Exemplo da estrutura do JSON:
        
        {
          "geral": {
            "title": "Visão Geral", 
            "body": "Texto da previsão geral..."
          },
          "amor": {
            "title": "Amor e Relacionamentos", 
            "body": "Texto sobre amor..."
          },
          "profissional": {
            "title": "Carreira e Finanças", 
            "body": "Texto sobre trabalho..."
          },
          "conselhos": {
            "title": "Conselhos para Hoje", 
            "body": "Texto com conselhos..."
          },
          "numeros_sorte": [7, 13, 25, 36, 42, 58]
        }
        
        A resposta deve ser somente o JSON válido, sem explicações adicionais ou formatação extra.
        Todas as previsões devem ser positivas, motivadoras e inspiradoras.
      ''';

      String response = await _geminiService.generateJsonHoroscope(prompt);

      // Validar se a resposta é um JSON válido
      try {
        // Tentar analisar o JSON
        json.decode(response);
        return response;
      } catch (e) {
        // Se não for um JSON válido, criar uma estrutura básica
        return json.encode({
          "geral": {
            "title": "Visão Geral para $sign",
            "body": response
          },
          "numeros_sorte": _generateRandomNumbers()
        });
      }
    } catch (e) {
      return json.encode({
        "geral": {
          "title": "Visão Geral para $sign",
          "body": "Hoje o universo reserva energias especiais para você. Aproveite as oportunidades que surgirem."
        },
        "numeros_sorte": _generateRandomNumbers()
      });
    }
  }

  // Gerar números aleatórios para números da sorte
  List<int> _generateRandomNumbers() {
    final numbers = <int>[];
    final random = DateTime.now().millisecondsSinceEpoch;

    while (numbers.length < 6) {
      final next = (random % 60) + 1;
      if (!numbers.contains(next)) {
        numbers.add(next);
      }
    }

    return numbers;
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