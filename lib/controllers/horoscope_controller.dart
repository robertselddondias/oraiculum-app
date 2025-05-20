import 'package:get/get.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
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

  final dataNascimento = new MaskTextInputFormatter(
      mask: '##/##/#####',
      filter: { "#": RegExp(r'[0-9]') },
      type: MaskAutoCompletionType.lazy
  );

  final horaNascimento = new MaskTextInputFormatter(
      mask: '##:##',
      filter: { "#": RegExp(r'[0-9]') },
      type: MaskAutoCompletionType.lazy
  );

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

  // Método atualizado para análise de compatibilidade em formato JSON
  Future<String> getCompatibilityAnalysis(String sign1, String sign2) async {
    try {
      isLoading.value = true;

      // Verificar se a análise já existe no Firebase
      final compatibilityId = '${sign1}_${sign2}';
      final reversedId = '${sign2}_${sign1}';

      // Verificar no Firestore se já existe esta análise
      final compatibilityDoc = await _firebaseService.firestore
          .collection('compatibility_analyses')
          .doc(compatibilityId)
          .get();

      // Verificar também a ordem inversa dos signos
      final reversedCompatibilityDoc = await _firebaseService.firestore
          .collection('compatibility_analyses')
          .doc(reversedId)
          .get();

      // Se já existe, retornar o conteúdo salvo
      if (compatibilityDoc.exists) {
        final data = compatibilityDoc.data() as Map<String, dynamic>;
        return data['content'] as String;
      } else if (reversedCompatibilityDoc.exists) {
        final data = reversedCompatibilityDoc.data() as Map<String, dynamic>;
        return data['content'] as String;
      }

      // Se não existe, gerar nova análise com Gemini
      final compatibilityText = await _generateStructuredCompatibility(sign1, sign2);

      // Salvar no Firestore para futuras consultas
      await _firebaseService.firestore.collection('compatibility_analyses').doc(compatibilityId).set({
        'sign1': sign1,
        'sign2': sign2,
        'content': compatibilityText,
        'createdAt': DateTime.now(),
      });

      return compatibilityText;
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível gerar a análise de compatibilidade: $e');
      return json.encode({
        "geral": {
          "title": "Compatibilidade Geral",
          "body": "Não foi possível gerar a análise de compatibilidade no momento. Por favor, tente novamente mais tarde."
        }
      });
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Gerar compatibilidade estruturada em formato JSON
  Future<String> _generateStructuredCompatibility(String sign1, String sign2) async {
    try {
      // Solicitação ao Gemini para retornar uma análise de compatibilidade estruturada
      final prompt = '''
        Gere uma análise de compatibilidade entre $sign1 e $sign2 no formato JSON com os seguintes tópicos:
        
        1. Compatibilidade geral ("geral")
        2. Compatibilidade emocional ("emocional")
        3. Compatibilidade de comunicação ("comunicacao")
        4. Compatibilidade sexual ("sexual")
        5. Pontos fortes da relação ("pontos_fortes")
        6. Desafios potenciais ("desafios")
        7. Conselhos para melhorar a relação ("conselhos")
        
        Para cada um dos tópicos, inclua um "title" e um "body". 
        Exemplo da estrutura do JSON:
        
        {
          "geral": {
            "title": "Compatibilidade Geral", 
            "body": "Texto da análise geral..."
          },
          "emocional": {
            "title": "Conexão Emocional", 
            "body": "Texto sobre a conexão emocional..."
          },
          "comunicacao": {
            "title": "Comunicação", 
            "body": "Texto sobre como se comunicam..."
          },
          "sexual": {
            "title": "Compatibilidade Sexual", 
            "body": "Texto sobre compatibilidade íntima..."
          },
          "pontos_fortes": {
            "title": "Pontos Fortes", 
            "body": "Texto sobre os pontos fortes do relacionamento..."
          },
          "desafios": {
            "title": "Desafios", 
            "body": "Texto sobre os desafios a superar..."
          },
          "conselhos": {
            "title": "Conselhos para o Casal", 
            "body": "Dicas e conselhos para melhorar a relação..."
          }
        }
        
        A resposta deve ser somente o JSON válido, sem explicações adicionais ou formatação extra.
        Mantenha a análise equilibrada, destacando tanto os aspectos positivos quanto os desafios da combinação desses dois signos.
      ''';

      String response = await _geminiService.generateJsonCompatibility(prompt);

      // Validar se a resposta é um JSON válido
      try {
        // Tentar analisar o JSON
        json.decode(response);
        return response;
      } catch (e) {
        // Se não for um JSON válido, criar uma estrutura básica
        return json.encode({
          "geral": {
            "title": "Compatibilidade entre $sign1 e $sign2",
            "body": response
          }
        });
      }
    } catch (e) {
      return json.encode({
        "geral": {
          "title": "Compatibilidade entre $sign1 e $sign2",
          "body": "A combinação desses signos traz elementos interessantes para o relacionamento. Cada um traz suas próprias qualidades e desafios para a relação."
        }
      });
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
      String birthDate,
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
        jsonFormat: true
      );

      // Salvar a interpretação no histórico do usuário
      if (_authController.currentUser.value != null) {
        final userId = _authController.currentUser.value!.uid;

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