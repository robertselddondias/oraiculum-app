import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:oraculum/models/tarot_model.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/services/gemini_service.dart';

class TarotController extends GetxController {
  final GeminiService _geminiService = Get.find<GeminiService>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final PaymentController _paymentController = Get.find<PaymentController>();

  RxBool isLoading = false.obs;
  RxList<TarotCard> allCards = <TarotCard>[].obs;
  RxList<TarotCard> selectedCards = <TarotCard>[].obs;
  Rx<TarotCard?> currentCard = Rx<TarotCard?>(null);
  RxString interpretation = ''.obs;

  RxList<Map<String, dynamic>> savedReadings = <Map<String, dynamic>>[].obs;

  // Controle de jogadas diárias
  RxInt dailyReadingsUsed = 0.obs;
  RxBool hasFreeReadingToday = true.obs;
  final double additionalReadingCost = 10.0; // Custo em créditos para leituras extras

  @override
  void onInit() {
    super.onInit();
    loadTarotCards();
    _checkDailyReadingStatus();
  }

  /// Verifica o status das leituras diárias do usuário
  Future<void> _checkDailyReadingStatus() async {
    try {
      final authController = Get.find<AuthController>();
      if (authController.currentUser.value == null) return;

      final userId = authController.currentUser.value!.uid;
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Buscar registro de leituras diárias
      final dailyReadingDoc = await _firebaseService.firestore
          .collection('daily_tarot_readings')
          .doc('$userId-$todayString')
          .get();

      if (dailyReadingDoc.exists) {
        final data = dailyReadingDoc.data() as Map<String, dynamic>;
        dailyReadingsUsed.value = data['count'] ?? 0;
        hasFreeReadingToday.value = dailyReadingsUsed.value == 0;
      } else {
        // Primeiro acesso do dia
        dailyReadingsUsed.value = 0;
        hasFreeReadingToday.value = true;
      }
    } catch (e) {
      debugPrint('Erro ao verificar status de leituras diárias: $e');
    }
  }

  /// Incrementa o contador de leituras diárias
  Future<void> _incrementDailyReadingCount() async {
    try {
      final authController = Get.find<AuthController>();
      if (authController.currentUser.value == null) return;

      final userId = authController.currentUser.value!.uid;
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final docRef = _firebaseService.firestore
          .collection('daily_tarot_readings')
          .doc('$userId-$todayString');

      final currentCount = dailyReadingsUsed.value;

      await docRef.set({
        'userId': userId,
        'date': todayString,
        'count': currentCount + 1,
        'lastReading': DateTime.now(),
      });

      dailyReadingsUsed.value = currentCount + 1;
      hasFreeReadingToday.value = false;
    } catch (e) {
      debugPrint('Erro ao incrementar contador de leituras: $e');
    }
  }

  /// Verifica se o usuário pode fazer uma leitura gratuita
  bool canPerformFreeReading() {
    return hasFreeReadingToday.value;
  }

  /// Verifica se o usuário tem créditos suficientes para leitura paga
  bool canPerformPaidReading() {
    return _paymentController.userCredits.value >= additionalReadingCost;
  }

  /// Mostra diálogo de confirmação para leitura paga
  Future<bool> _showPaidReadingConfirmation() async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Leitura Adicional'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Você já usou sua leitura gratuita de hoje.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Custo da leitura adicional: ${additionalReadingCost.toStringAsFixed(0)} créditos',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Obx(() => Text(
              'Seus créditos atuais: ${_paymentController.userCredits.value.toStringAsFixed(0)}',
              style: TextStyle(
                color: _paymentController.userCredits.value >= additionalReadingCost
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            )),
            if (_paymentController.userCredits.value < additionalReadingCost) ...[
              const SizedBox(height: 16),
              const Text(
                'Você não tem créditos suficientes. Adicione mais créditos para continuar.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          if (_paymentController.userCredits.value < additionalReadingCost)
            ElevatedButton(
              onPressed: () {
                Get.back(result: false);
                // Navegar para tela de adicionar créditos
                Get.toNamed('/payment-methods');
              },
              child: const Text('Adicionar Créditos'),
            )
          else
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar Pagamento'),
            ),
        ],
      ),
    ) ?? false;
  }

  /// Processa o pagamento para leitura adicional
  Future<bool> _processPaidReading() async {
    try {
      final authController = Get.find<AuthController>();
      if (authController.currentUser.value == null) return false;

      final userId = authController.currentUser.value!.uid;

      // Verificar créditos novamente
      if (!await _paymentController.checkUserCredits(userId, additionalReadingCost)) {
        Get.snackbar(
          'Erro',
          'Créditos insuficientes para realizar a leitura',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Processar pagamento
      const paymentDescription = 'Leitura de Tarô Adicional';
      final serviceId = 'tarot-reading-${DateTime.now().millisecondsSinceEpoch}';

      final paymentId = await _paymentController.processPaymentWithCredits(
          userId,
          additionalReadingCost,
          paymentDescription,
          serviceId,
          'tarot_reading'
      );

      if (paymentId.isEmpty) {
        Get.snackbar(
          'Erro',
          'Falha ao processar o pagamento. Tente novamente.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      Get.snackbar(
        'Sucesso',
        'Pagamento processado com sucesso! Você pode fazer sua leitura adicional.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      debugPrint('Erro ao processar pagamento para leitura: $e');
      Get.snackbar(
        'Erro',
        'Ocorreu um erro ao processar o pagamento: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Verifica se pode realizar uma leitura (gratuita ou paga)
  Future<bool> canPerformReading() async {
    // Se tem leitura gratuita disponível
    if (canPerformFreeReading()) {
      return true;
    }

    // Se não tem leitura gratuita, verificar se pode pagar
    if (!canPerformPaidReading()) {
      Get.snackbar(
        'Créditos Insuficientes',
        'Você não tem créditos suficientes para uma leitura adicional hoje.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    // Mostrar diálogo de confirmação para leitura paga
    final confirmed = await _showPaidReadingConfirmation();
    if (!confirmed) return false;

    // Processar pagamento
    return await _processPaidReading();
  }

  Future<void> loadTarotCards() async {
    try {
      isLoading.value = true;
      final cardsSnapshot = await _firebaseService.getTarotCards();

      if (cardsSnapshot.docs.isNotEmpty) {
        allCards.value = cardsSnapshot.docs
            .map((doc) => TarotCard.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      }
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível carregar as cartas de tarô: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  void viewCardDetails(String cardId) {
    final card = allCards.firstWhere((card) => card.id == cardId);
    currentCard.value = card;
    update();
  }

  void toggleCardSelection(TarotCard card) {
    if (selectedCards.contains(card)) {
      selectedCards.remove(card);
    } else {
      // Limitar o número de cartas selecionadas
      if (selectedCards.length < 3) {
        selectedCards.add(card);
      } else {
        Get.snackbar('Limite atingido', 'Você pode selecionar no máximo 3 cartas.');
      }
    }
    update();
  }

  Future<void> performReading() async {
    if (selectedCards.isEmpty) {
      Get.snackbar('Erro', 'Selecione pelo menos uma carta para realizar a leitura.');
      return;
    }

    // Verificar se pode realizar a leitura
    final canPerform = await canPerformReading();
    if (!canPerform) return;

    try {
      isLoading.value = true;
      final cardNames = selectedCards.map((card) => card.name).toList();

      // Modificar o prompt para obter JSON estruturado
      final promptForJSON = '''
      Gere uma interpretação de tarô para as seguintes cartas: ${cardNames.join(', ')}.
      
      A resposta deve estar em formato JSON com a seguinte estrutura:
      
      {
        "geral": {
          "title": "Interpretação Geral", 
          "body": "Texto da interpretação geral das cartas..."
        },
        "amor": {
          "title": "Amor e Relacionamentos", 
          "body": "Texto sobre amor com base nas cartas..."
        },
        "trabalho": {
          "title": "Carreira e Finanças", 
          "body": "Texto sobre trabalho e finanças..."
        },
        "saude": {
          "title": "Saúde e Bem-estar", 
          "body": "Texto sobre saúde..."
        },
        "conselho": {
          "title": "Conselho para Este Momento", 
          "body": "Conselhos finais com base na leitura..."
        }
      }
      
      A resposta deve ser somente o JSON válido, sem explicações adicionais ou formatação extra.
      Todas as interpretações devem ser construtivas, motivadoras e trazer orientação.
    ''';

      // Usar o método do serviço Gemini para obter JSON
      final readingResult = await _geminiService.generateJsonInterpretation(promptForJSON);
      interpretation.value = readingResult;

      // Incrementar contador de leituras após sucesso
      await _incrementDailyReadingCount();

    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível realizar a leitura: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> saveReading() async {
    if (selectedCards.isEmpty || interpretation.value.isEmpty) {
      Get.snackbar('Erro', 'Não há leitura para salvar.');
      return;
    }

    try {
      isLoading.value = true;

      final authController = Get.find<AuthController>();
      if (authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para salvar a leitura.');
        return;
      }

      final userId = authController.currentUser.value!.uid;
      final cardIds = selectedCards.map((card) => card.id).toList();

      final readingData = {
        'userId': userId,
        'cardIds': cardIds,
        'interpretation': interpretation.value,
        'createdAt': DateTime.now(),
        'wasPaid': !hasFreeReadingToday.value, // Marca se foi uma leitura paga
        'cost': !hasFreeReadingToday.value ? additionalReadingCost : 0.0,
      };

      await _firebaseService.saveTarotReading(readingData);
      Get.snackbar('Sucesso', 'Leitura salva com sucesso!');
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível salvar a leitura: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  void resetReading() {
    selectedCards.clear();
    interpretation.value = '';
    update();
  }

  List<TarotCard> getRandomCards(int count) {
    final random = Random();
    final shuffledCards = List<TarotCard>.from(allCards);
    shuffledCards.shuffle(random);
    return shuffledCards.take(count).toList();
  }

  // Carregar leituras salvas do usuário
  Future<void> loadSavedReadings() async {
    try {
      isLoading.value = true;

      final authController = Get.find<AuthController>();
      if (authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para ver suas leituras.');
        return;
      }

      final userId = authController.currentUser.value!.uid;
      final readingsSnapshot = await _firebaseService.getUserTarotReadings(userId);

      if (readingsSnapshot.docs.isNotEmpty) {
        savedReadings.value = readingsSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }).toList();
      } else {
        savedReadings.clear();
      }
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível carregar suas leituras salvas: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

// Marcar/desmarcar leitura como favorita
  Future<void> toggleFavoriteReading(String readingId) async {
    try {
      // Encontrar a leitura na lista
      final index = savedReadings.indexWhere((reading) => reading['id'] == readingId);
      if (index == -1) return;

      // Inverter o status de favorito
      final currentStatus = savedReadings[index]['isFavorite'] ?? false;
      final newStatus = !currentStatus;

      // Atualizar no Firestore
      await _firebaseService.toggleFavoriteTarotReading(readingId, newStatus);

      // Atualizar localmente
      savedReadings[index]['isFavorite'] = newStatus;
      savedReadings.refresh();

      Get.snackbar(
        'Sucesso',
        newStatus ? 'Leitura adicionada aos favoritos' : 'Leitura removida dos favoritos',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível atualizar os favoritos: $e');
    }
  }

// Excluir uma leitura salva
  Future<void> deleteReading(String readingId) async {
    try {
      isLoading.value = true;

      // Excluir do Firestore
      await _firebaseService.firestore.collection('tarot_readings').doc(readingId).delete();

      // Remover da lista local
      savedReadings.removeWhere((reading) => reading['id'] == readingId);
      savedReadings.refresh();

      Get.snackbar(
        'Sucesso',
        'Leitura excluída com sucesso',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível excluir a leitura: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

// Obter detalhes de uma leitura específica por ID
  Future<Map<String, dynamic>?> getReadingById(String readingId) async {
    try {
      // Verificar primeiro na lista local
      final localReading = savedReadings.firstWhereOrNull((reading) => reading['id'] == readingId);
      if (localReading != null) return localReading;

      // Se não estiver na lista local, buscar do Firestore
      final docSnapshot = await _firebaseService.firestore
          .collection('tarot_readings')
          .doc(readingId)
          .get();

      if (docSnapshot.exists) {
        return {
          'id': docSnapshot.id,
          ...docSnapshot.data() as Map<String, dynamic>,
        };
      }

      return null;
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível carregar a leitura: $e');
      return null;
    }
  }

// Buscar uma carta específica por ID
  Future<TarotCard?> getCardById(String cardId) async {
    try {
      // Verificar primeiro na lista de cartas carregadas
      final localCard = allCards.firstWhereOrNull((card) => card.id == cardId);
      if (localCard != null) return localCard;

      // Se não estiver na lista local, buscar do Firestore
      final docSnapshot = await _firebaseService.getTarotCard(cardId);

      if (docSnapshot.exists) {
        return TarotCard.fromMap(
          docSnapshot.data() as Map<String, dynamic>,
          docSnapshot.id,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Erro ao buscar carta: $e');
      return null;
    }
  }

  /// Método para resetar o limite diário (para testes ou admin)
  Future<void> resetDailyLimit() async {
    try {
      final authController = Get.find<AuthController>();
      if (authController.currentUser.value == null) return;

      final userId = authController.currentUser.value!.uid;
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _firebaseService.firestore
          .collection('daily_tarot_readings')
          .doc('$userId-$todayString')
          .delete();

      dailyReadingsUsed.value = 0;
      hasFreeReadingToday.value = true;

      Get.snackbar(
        'Sucesso',
        'Limite diário resetado com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Erro ao resetar limite diário: $e');
    }
  }

  /// Obter estatísticas de uso das leituras de tarô
  Future<Map<String, dynamic>> getReadingStats() async {
    try {
      final authController = Get.find<AuthController>();
      if (authController.currentUser.value == null) return {};

      final userId = authController.currentUser.value!.uid;

      // Buscar todas as leituras do usuário
      final readingsSnapshot = await _firebaseService.firestore
          .collection('tarot_readings')
          .where('userId', isEqualTo: userId)
          .get();

      // Buscar registros de leituras diárias
      final dailyReadingsSnapshot = await _firebaseService.firestore
          .collection('daily_tarot_readings')
          .where('userId', isEqualTo: userId)
          .get();

      final totalReadings = readingsSnapshot.docs.length;
      final totalDays = dailyReadingsSnapshot.docs.length;
      final paidReadings = readingsSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['wasPaid'] == true;
      }).length;

      final totalSpentOnReadings = readingsSnapshot.docs.fold<double>(0.0, (sum, doc) {
        final data = doc.data() as Map<String, dynamic>;
        final cost = data['cost'] ?? 0.0;
        return sum + (cost is num ? cost.toDouble() : 0.0);
      });

      return {
        'totalReadings': totalReadings,
        'freeReadings': totalReadings - paidReadings,
        'paidReadings': paidReadings,
        'totalDaysUsed': totalDays,
        'totalSpent': totalSpentOnReadings,
        'todayUsed': dailyReadingsUsed.value,
        'canReadFreeToday': hasFreeReadingToday.value,
      };
    } catch (e) {
      debugPrint('Erro ao obter estatísticas: $e');
      return {};
    }
  }
}