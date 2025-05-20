import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/models/credit_card_model.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/services/pagarme_service.dart';

class CardListController extends GetxController {
  // Serviços injetados
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthController _authController = Get.find<AuthController>();
  final PagarmeService _pagarmeService = Get.find<PagarmeService>();

  // Variáveis observáveis
  final RxList<Map<String, dynamic>> savedCards = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isInitialLoading = true.obs;
  final RxString errorMessage = ''.obs;

  // Controle para confirmar exclusão
  final RxBool showDeleteConfirmation = false.obs;
  final RxString cardToDelete = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadCards();
  }

  @override
  void onReady() {
    super.onReady();
    // Adicional: Se quiser recarregar os cartões sempre que a tela for acessada
    ever(_authController.currentUser, (_) {
      if (_authController.isLoggedIn) {
        loadCards();
      } else {
        savedCards.clear();
      }
    });
  }

  // Carregar os cartões do usuário
  Future<void> loadCards() async {
    if (!_authController.isLoggedIn) {
      isInitialLoading.value = false;
      errorMessage.value = 'Você precisa estar logado para ver seus cartões';
      return;
    }

    try {
      isLoading.value = true;
      isInitialLoading.value = true;
      errorMessage.value = '';

      final userId = _authController.currentUser.value!.uid;

      // Buscar os cartões na coleção 'credit_cards'
      final cardsSnapshot = await _firebaseService.firestore
          .collection('credit_cards')
          .where('userId', isEqualTo: userId)
          .get();

      // Transformar os documentos em uma lista de mapas
      savedCards.value = cardsSnapshot.docs.map((doc) {
        final data = doc.data();

        // Extração de mês e ano da data de expiração
        String expiryMonth = '12';
        String expiryYear = '2030';

        if (data.containsKey('expirationDate') && data['expirationDate'] != null) {
          final parts = (data['expirationDate'] as String).split('/');
          if (parts.length == 2) {
            expiryMonth = parts[0];
            expiryYear = parts[1].length == 2 ? '20${parts[1]}' : parts[1];
          }
        }

        return {
          'id': doc.id,
          'lastFourDigits': data['lastFourDigits'] ?? '****',
          'cardHolder': data['cardHolderName'] ?? 'Titular',
          'brand': data['brandType'] ?? 'unknown',
          'expiryMonth': expiryMonth,
          'expiryYear': expiryYear,
          'isDefault': data['isDefault'] ?? false,
          'cardId': data['cardId'],
          'customerId': data['customerId'],
        };
      }).toList();

      // Ordenar cartões (padrão primeiro, depois por data de criação)
      savedCards.sort((a, b) {
        // Cartão padrão sempre vem primeiro
        if (a['isDefault'] == true && b['isDefault'] != true) return -1;
        if (b['isDefault'] == true && a['isDefault'] != true) return 1;

        // Se nenhum for padrão ou ambos forem, manter ordem
        return 0;
      });

    } catch (e) {
      debugPrint('Erro ao carregar cartões: $e');
      errorMessage.value = 'Não foi possível carregar seus cartões. Tente novamente mais tarde.';
    } finally {
      isLoading.value = false;
      isInitialLoading.value = false;
    }
  }

  // Atualizar cartões (para o Pull-to-Refresh)
  Future<void> refreshCards() async {
    errorMessage.value = '';
    await loadCards();
  }

  // Verificar se um cartão está expirado
  bool isCardExpired(Map<String, dynamic> card) {
    try {
      final expiryMonth = int.parse(card['expiryMonth'] ?? '12');
      final expiryYear = int.parse(card['expiryYear'] ?? '2099');

      final now = DateTime.now();
      final cardDate = DateTime(expiryYear, expiryMonth, 1);

      // O cartão expira no último dia do mês
      final cardExpiryDate = DateTime(expiryYear, expiryMonth + 1, 0);

      return cardExpiryDate.isBefore(now);
    } catch (e) {
      // Em caso de erro no formato da data, considerar não expirado
      return false;
    }
  }

  // Navegar para a tela de adicionar cartão
  void goToAddCard() {
    Get.toNamed(AppRoutes.addCreditCard)?.then((_) => refreshCards());
  }

  // Preparar para excluir cartão (mostrar confirmação)
  void confirmDeleteCard(String cardId) {
    cardToDelete.value = cardId;
    showDeleteConfirmation.value = true;
  }

  // Cancelar exclusão
  void cancelDelete() {
    showDeleteConfirmation.value = false;
    cardToDelete.value = '';
  }

  // Confirmar exclusão do cartão
  Future<void> confirmDelete() async {
    if (cardToDelete.value.isEmpty) return;

    try {
      isLoading.value = true;
      showDeleteConfirmation.value = false;

      // Encontrar o cartão na lista
      final cardIndex = savedCards.indexWhere((card) => card['id'] == cardToDelete.value);
      if (cardIndex < 0) {
        Get.snackbar('Erro', 'Cartão não encontrado');
        return;
      }

      final card = savedCards[cardIndex];
      final cardModel = CreditCardUserModel(
        id: card['id'],
        cardId: card['cardId'],
        customerId: card['customerId'],
      );

      // Excluir da API da Pagar.me
      try {
        await _pagarmeService.deleteCard(cardModel);
      } catch (e) {
        debugPrint('Erro ao remover cartão da Pagar.me: $e');
        // Continue mesmo com erro, para pelo menos remover do Firestore
      }

      // Excluir do Firestore
      await _firebaseService.firestore
          .collection('credit_cards')
          .doc(cardToDelete.value)
          .delete();

      // Verificar se é o cartão padrão
      final isDefault = card['isDefault'] == true;

      // Remover da lista local
      savedCards.removeAt(cardIndex);

      // Se era o padrão e houver outros cartões, definir outro como padrão
      if (isDefault && savedCards.isNotEmpty) {
        await setDefaultCard(savedCards.first['id']);
      }

      Get.snackbar('Sucesso', 'Cartão removido com sucesso');
    } catch (e) {
      debugPrint('Erro ao excluir cartão: $e');
      Get.snackbar('Erro', 'Não foi possível excluir o cartão');
    } finally {
      isLoading.value = false;
      cardToDelete.value = '';
    }
  }

  // Definir um cartão como padrão
  Future<void> setDefaultCard(String cardId) async {
    try {
      isLoading.value = true;

      // Verificar se o cartão existe
      final cardIndex = savedCards.indexWhere((card) => card['id'] == cardId);
      if (cardIndex < 0) {
        Get.snackbar('Erro', 'Cartão não encontrado');
        return;
      }

      // Usar batch para atualizar todos os cartões de uma vez
      final batch = _firebaseService.firestore.batch();
      final userId = _authController.currentUser.value!.uid;

      // Buscar todos os cartões do usuário
      final cardsSnapshot = await _firebaseService.firestore
          .collection('credit_cards')
          .where('userId', isEqualTo: userId)
          .get();

      // Remover flag de padrão de todos os cartões
      for (var doc in cardsSnapshot.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      // Definir o novo cartão padrão
      batch.update(_firebaseService.firestore.collection('credit_cards').doc(cardId),
          {'isDefault': true});

      // Executar todas as operações
      await batch.commit();

      // Atualizar lista local
      for (var i = 0; i < savedCards.length; i++) {
        savedCards[i] = {...savedCards[i], 'isDefault': savedCards[i]['id'] == cardId};
      }

      // Reordenar a lista (cartão padrão primeiro)
      savedCards.sort((a, b) {
        if (a['isDefault'] == true && b['isDefault'] != true) return -1;
        if (b['isDefault'] == true && a['isDefault'] != true) return 1;
        return 0;
      });

      Get.snackbar('Sucesso', 'Cartão definido como padrão');
    } catch (e) {
      debugPrint('Erro ao definir cartão padrão: $e');
      Get.snackbar('Erro', 'Não foi possível definir o cartão como padrão');
    } finally {
      isLoading.value = false;
    }
  }
}