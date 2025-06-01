import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:oraculum/models/horoscope_model.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/services/gemini_service.dart';

class HoroscopeController extends GetxController {
  final GeminiService _geminiService = Get.find<GeminiService>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final PaymentController _paymentController = Get.find<PaymentController>();
  final AuthController _authController = Get.find<AuthController>();

  RxList<Map<String, dynamic>> birthChartHistory = <Map<String, dynamic>>[].obs;
  RxBool isLoadingHistory = false.obs;

  RxBool isLoading = false.obs;
  RxString currentSign = ''.obs;
  Rx<HoroscopeModel?> dailyHoroscope = Rx<HoroscopeModel?>(null);
  RxList<String> zodiacSigns = <String>[
    'Áries', 'Touro', 'Gêmeos', 'Câncer',
    'Leão', 'Virgem', 'Libra', 'Escorpião',
    'Sagitário', 'Capricórnio', 'Aquário', 'Peixes'
  ].obs;

  final dataNascimento = MaskTextInputFormatter(
      mask: '##/##/#####',
      filter: { "#": RegExp(r'[0-9]') },
      type: MaskAutoCompletionType.lazy
  );

  final horaNascimento = MaskTextInputFormatter(
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
      final compatibilityId = '${sign1}_$sign2';
      final reversedId = '${sign2}_$sign1';

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
      const paymentDescription = 'Geração de Mapa Astral';
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

  // Future<Map<String, dynamic>> getBirthChartInterpretation(
  //     String birthDate,
  //     String birthTime,
  //     String birthPlace,
  //     ) async {
  //   try {
  //     isLoading.value = true;
  //
  //     // Processar pagamento primeiro
  //     final paymentResult = await processBirthChartPayment();
  //     if (!paymentResult['success']) {
  //       return {
  //         'success': false,
  //         'message': paymentResult['message']
  //       };
  //     }
  //
  //     // Gerar a interpretação
  //     final chartInterpretation = await _geminiService.getBirthChartInterpretation(
  //       birthDate,
  //       birthTime,
  //       birthPlace,
  //       jsonFormat: true
  //     );
  //
  //     // Salvar a interpretação no histórico do usuário
  //     if (_authController.currentUser.value != null) {
  //       final userId = _authController.currentUser.value!.uid;
  //
  //       await _firebaseService.firestore.collection('birth_charts').add({
  //         'userId': userId,
  //         'birthDate': birthDate,
  //         'birthTime': birthTime,
  //         'birthPlace': birthPlace,
  //         'interpretation': chartInterpretation,
  //         'createdAt': DateTime.now(),
  //         'paymentId': paymentResult['paymentId']
  //       });
  //     }
  //
  //     return {
  //       'success': true,
  //       'interpretation': chartInterpretation
  //     };
  //   } catch (e) {
  //     Get.snackbar('Erro', 'Não foi possível interpretar o mapa astral: $e');
  //     return {
  //       'success': false,
  //       'message': 'Erro ao interpretar o mapa astral: $e'
  //     };
  //   } finally {
  //     isLoading.value = false;
  //     update();
  //   }
  // }

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

  Future<Map<String, dynamic>> getBirthChartInterpretation(
      String birthDate,
      String birthTime,
      String birthPlace,
      String name
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

      // Salvar no histórico do usuário
      if (_authController.currentUser.value != null) {
        final userId = _authController.currentUser.value!.uid;

        final chartId = await _firebaseService.saveBirthChart(
          userId: userId,
          name: name!,
          birthDate: birthDate,
          birthTime: birthTime,
          birthPlace: birthPlace,
          interpretation: chartInterpretation,
          paymentId: paymentResult['paymentId'],
        );

        // Atualizar lista local
        await loadUserBirthCharts();

        debugPrint('✅ Mapa astral salvo com ID: $chartId');
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

  /// Carregar histórico de mapas astrais do usuário
  Future<void> loadUserBirthCharts() async {
    try {
      if (_authController.currentUser.value == null) {
        birthChartHistory.clear();
        return;
      }

      isLoadingHistory.value = true;
      final userId = _authController.currentUser.value!.uid;

      final charts = await _firebaseService.getUserBirthCharts(userId);
      birthChartHistory.value = charts;

      debugPrint('✅ Carregados ${charts.length} mapas astrais');
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível carregar histórico: $e');
      debugPrint('❌ Erro ao carregar histórico: $e');
    } finally {
      isLoadingHistory.value = false;
    }
  }

  /// Obter mapas astrais favoritos
  Future<List<Map<String, dynamic>>> getFavoriteBirthCharts() async {
    try {
      if (_authController.currentUser.value == null) {
        return [];
      }

      final userId = _authController.currentUser.value!.uid;
      return await _firebaseService.getFavoriteBirthCharts(userId);
    } catch (e) {
      debugPrint('❌ Erro ao obter favoritos: $e');
      return [];
    }
  }

  /// Alternar favorito de um mapa astral
  Future<void> toggleBirthChartFavorite(String chartId, bool isFavorite) async {
    try {
      await _firebaseService.toggleBirthChartFavorite(chartId, isFavorite);

      // Atualizar lista local
      final chartIndex = birthChartHistory.indexWhere((chart) => chart['id'] == chartId);
      if (chartIndex != -1) {
        birthChartHistory[chartIndex]['isFavorite'] = isFavorite;
      }

      Get.snackbar(
        'Sucesso',
        isFavorite ? 'Adicionado aos favoritos' : 'Removido dos favoritos',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível atualizar favorito: $e');
    }
  }

  /// Deletar um mapa astral
  Future<void> deleteBirthChart(String chartId) async {
    try {
      await _firebaseService.deleteBirthChart(chartId);

      // Remover da lista local
      birthChartHistory.removeWhere((chart) => chart['id'] == chartId);

      Get.snackbar(
        'Sucesso',
        'Mapa astral removido com sucesso',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível remover o mapa astral: $e');
    }
  }

  /// Buscar mapas astrais
  Future<List<Map<String, dynamic>>> searchBirthCharts(String query) async {
    try {
      if (_authController.currentUser.value == null) {
        return [];
      }

      final userId = _authController.currentUser.value!.uid;
      return await _firebaseService.searchBirthCharts(userId, query);
    } catch (e) {
      debugPrint('❌ Erro na busca: $e');
      return [];
    }
  }

  /// Obter estatísticas dos mapas astrais
  Future<Map<String, dynamic>> getBirthChartStats() async {
    try {
      if (_authController.currentUser.value == null) {
        return {};
      }

      final userId = _authController.currentUser.value!.uid;
      return await _firebaseService.getBirthChartStats(userId);
    } catch (e) {
      debugPrint('❌ Erro ao obter estatísticas: $e');
      return {};
    }
  }

  /// Obter um mapa astral específico
  Future<Map<String, dynamic>?> getBirthChart(String chartId) async {
    try {
      return await _firebaseService.getBirthChart(chartId);
    } catch (e) {
      debugPrint('❌ Erro ao obter mapa astral: $e');
      return null;
    }
  }

  /// Duplicar um mapa astral existente
  Future<String?> duplicateBirthChart(String chartId) async {
    try {
      final originalChart = await getBirthChart(chartId);
      if (originalChart == null) {
        throw Exception('Mapa astral não encontrado');
      }

      if (_authController.currentUser.value == null) {
        throw Exception('Usuário não autenticado');
      }

      final userId = _authController.currentUser.value!.uid;
      final newName = '${originalChart['name']} (Cópia)';

      final newChartId = await _firebaseService.saveBirthChart(
        userId: userId,
        name: newName,
        birthDate: originalChart['birthDate'],
        birthTime: originalChart['birthTime'],
        birthPlace: originalChart['birthPlace'],
        interpretation: originalChart['interpretation'],
        paymentId: 'duplicated_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Atualizar lista local
      await loadUserBirthCharts();

      Get.snackbar(
        'Sucesso',
        'Mapa astral duplicado com sucesso',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return newChartId;
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível duplicar o mapa astral: $e');
      return null;
    }
  }

  /// Exportar mapa astral como texto
  String exportBirthChartAsText(Map<String, dynamic> chart) {
    final buffer = StringBuffer();

    buffer.writeln('🌟 MAPA ASTRAL - ${chart['name']}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    buffer.writeln('📋 INFORMAÇÕES PESSOAIS:');
    buffer.writeln('Nome: ${chart['name']}');
    buffer.writeln('Data de Nascimento: ${chart['birthDate']}');
    buffer.writeln('Horário: ${chart['birthTime']}');
    buffer.writeln('Local: ${chart['birthPlace']}');
    buffer.writeln('Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(chart['createdAt'])}');
    buffer.writeln();

    buffer.writeln('🔮 INTERPRETAÇÃO:');
    buffer.writeln('-' * 30);

    try {
      // Tentar decodificar como JSON estruturado
      final interpretation = json.decode(chart['interpretation']);

      if (interpretation is Map<String, dynamic>) {
        interpretation.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            buffer.writeln();
            buffer.writeln('${value['title'] ?? key.toUpperCase()}:');
            buffer.writeln(value['body'] ?? '');
          }
        });
      } else {
        buffer.writeln(chart['interpretation']);
      }
    } catch (e) {
      // Se não for JSON, usar como texto simples
      buffer.writeln(chart['interpretation']);
    }

    buffer.writeln();
    buffer.writeln('=' * 50);
    buffer.writeln('Gerado pelo app Oraculum');

    return buffer.toString();
  }

  /// Validar dados do mapa astral
  Map<String, String?> validateBirthChartData({
    required String name,
    required String birthDate,
    required String birthTime,
    required String birthPlace,
  }) {
    final errors = <String, String?>{};

    // Validar nome
    if (name.trim().isEmpty) {
      errors['name'] = 'Nome é obrigatório';
    } else if (name.trim().length < 2) {
      errors['name'] = 'Nome deve ter pelo menos 2 caracteres';
    }

    // Validar data de nascimento
    if (birthDate.isEmpty) {
      errors['birthDate'] = 'Data de nascimento é obrigatória';
    } else {
      try {
        final date = DateFormat('dd/MM/yyyy').parse(birthDate);
        final now = DateTime.now();

        if (date.isAfter(now)) {
          errors['birthDate'] = 'Data não pode ser no futuro';
        } else if (date.isBefore(DateTime(1900))) {
          errors['birthDate'] = 'Data deve ser após 1900';
        }
      } catch (e) {
        errors['birthDate'] = 'Formato de data inválido (use dd/MM/yyyy)';
      }
    }

    // Validar horário
    if (birthTime.isEmpty) {
      errors['birthTime'] = 'Horário é obrigatório';
    } else {
      try {
        final timeParts = birthTime.split(':');
        if (timeParts.length != 2) {
          throw FormatException('Formato inválido');
        }

        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        if (hour < 0 || hour > 23) {
          errors['birthTime'] = 'Hora deve estar entre 00 e 23';
        } else if (minute < 0 || minute > 59) {
          errors['birthTime'] = 'Minuto deve estar entre 00 e 59';
        }
      } catch (e) {
        errors['birthTime'] = 'Formato de horário inválido (use HH:mm)';
      }
    }

    // Validar local
    if (birthPlace.trim().isEmpty) {
      errors['birthPlace'] = 'Local de nascimento é obrigatório';
    } else if (birthPlace.trim().length < 2) {
      errors['birthPlace'] = 'Local deve ter pelo menos 2 caracteres';
    }

    return errors;
  }

  /// Formatar data para exibição
  String formatBirthDate(DateTime date) {
    return DateFormat('dd \'de\' MMMM \'de\' yyyy', 'pt_BR').format(date);
  }

  /// Calcular idade
  int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  /// Gerar resumo do mapa astral
  Map<String, dynamic> generateBirthChartSummary(Map<String, dynamic> chart) {
    final birthDate = DateTime.tryParse(chart['birthDate'].replaceAll('/', '-'));

    return {
      'name': chart['name'],
      'age': birthDate != null ? calculateAge(birthDate) : null,
      'zodiacSign': birthDate != null ? _getZodiacSignFromDate(birthDate) : null,
      'birthPlace': chart['birthPlace'],
      'createdAt': chart['createdAt'],
      'isFavorite': chart['isFavorite'],
      'hasInterpretation': chart['interpretation']?.isNotEmpty ?? false,
    };
  }

  /// Determinar signo zodiacal pela data
  String _getZodiacSignFromDate(DateTime birthDate) {
    final day = birthDate.day;
    final month = birthDate.month;

    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'Aquário';
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return 'Peixes';
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'Áries';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'Touro';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return 'Gêmeos';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'Câncer';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Leão';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'Virgem';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'Libra';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 'Escorpião';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return 'Sagitário';

    return 'Capricórnio';
  }

  /// Limpar histórico (apenas dados locais)
  void clearLocalHistory() {
    birthChartHistory.clear();
    Get.snackbar(
      'Sucesso',
      'Histórico local limpo',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  /// Sincronizar dados com servidor
  Future<void> syncBirthChartsWithServer() async {
    try {
      isLoadingHistory.value = true;
      await loadUserBirthCharts();

      Get.snackbar(
        'Sucesso',
        'Dados sincronizados com sucesso',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Erro', 'Falha na sincronização: $e');
    } finally {
      isLoadingHistory.value = false;
    }
  }
}