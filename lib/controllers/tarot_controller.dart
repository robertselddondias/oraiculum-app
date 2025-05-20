import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/models/tarot_model.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/services/gemini_service.dart';

class TarotController extends GetxController {
  final GeminiService _geminiService = Get.find<GeminiService>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();

  RxBool isLoading = false.obs;
  RxList<TarotCard> allCards = <TarotCard>[].obs;
  RxList<TarotCard> selectedCards = <TarotCard>[].obs;
  Rx<TarotCard?> currentCard = Rx<TarotCard?>(null);
  RxString interpretation = ''.obs;

  RxList<Map<String, dynamic>> savedReadings = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadTarotCards();
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
}