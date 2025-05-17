import 'package:oraculum/controllers/auth_controller.dart';
import 'package:get/get.dart';
import 'package:oraculum/services/gemini_service.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/models/tarot_model.dart';
import 'dart:math';

class TarotController extends GetxController {
  final GeminiService _geminiService = Get.find<GeminiService>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();

  RxBool isLoading = false.obs;
  RxList<TarotCard> allCards = <TarotCard>[].obs;
  RxList<TarotCard> selectedCards = <TarotCard>[].obs;
  Rx<TarotCard?> currentCard = Rx<TarotCard?>(null);
  RxString interpretation = ''.obs;

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
      final readingResult = null; //await _geminiService.getTarotInterpretation(cardNames);
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
}