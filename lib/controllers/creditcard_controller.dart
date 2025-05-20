import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/models/user_model.dart';
import 'package:oraculum/services/pagarme_service.dart';
import 'package:oraculum/services/dtos/card_token_request.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class CreditCardController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthController _authController = Get.find<AuthController>();

  final cardNumberFormatter = MaskTextInputFormatter(
    mask: '#### #### #### ####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final expiryDateFormatter = MaskTextInputFormatter(
    mask: '##/##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final cvvFormatter = MaskTextInputFormatter(
    mask: '###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final documentFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  RxBool isLoading = false.obs;
  RxList<Map<String, dynamic>> savedCards = <Map<String, dynamic>>[].obs;

  // Controllers para os campos do formulário
  final cardNumberController = TextEditingController();
  final documentController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final cardHolderController = TextEditingController();
  final expiryDateController = TextEditingController();
  final cvvController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadSavedCards();
  }

  @override
  void onClose() {
    cardNumberController.dispose();
    cardHolderController.dispose();
    expiryDateController.dispose();
    cvvController.dispose();
    super.onClose();
  }

  // Carregar cartões salvos do usuário atual
  Future<void> loadSavedCards() async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para acessar seus cartões');
        return;
      }

      isLoading.value = true;
      final userId = _authController.currentUser.value!.uid;

      final cardsSnapshot = await _firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('saved_cards')
          .get();

      savedCards.value = cardsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível carregar os cartões: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Remover um cartão salvo
  Future<bool> removeCard(String cardId) async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para remover um cartão');
        return false;
      }

      isLoading.value = true;
      final userId = _authController.currentUser.value!.uid;

      await _firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('saved_cards')
          .doc(cardId)
          .delete();

      // Atualizar lista local
      savedCards.removeWhere((card) => card['id'] == cardId);
      update();

      Get.snackbar('Sucesso', 'Cartão removido com sucesso');
      return true;
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível remover o cartão: $e');
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Definir um cartão como padrão
  Future<bool> setDefaultCard(String cardId) async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para definir um cartão padrão');
        return false;
      }

      isLoading.value = true;
      final userId = _authController.currentUser.value!.uid;

      // Primeiro, remover flag de cartão padrão de todos os cartões
      final batch = _firebaseService.firestore.batch();

      final cardsSnapshot = await _firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('saved_cards')
          .get();

      for (var doc in cardsSnapshot.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      // Definir o cartão selecionado como padrão
      batch.update(
          _firebaseService.firestore
              .collection('users')
              .doc(userId)
              .collection('saved_cards')
              .doc(cardId),
          {'isDefault': true}
      );

      await batch.commit();

      // Atualizar lista local
      for (var card in savedCards) {
        card['isDefault'] = card['id'] == cardId;
      }
      savedCards.refresh();

      Get.snackbar('Sucesso', 'Cartão definido como padrão');
      return true;
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível definir o cartão como padrão: $e');
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Validar dados do cartão
  bool _validateCardData() {
    if (cardNumberController.text.isEmpty ||
        cardNumberController.text.replaceAll(' ', '').length < 16) {
      Get.snackbar('Erro', 'Número de cartão inválido');
      return false;
    }

    if (cardHolderController.text.isEmpty) {
      Get.snackbar('Erro', 'Nome do titular do cartão não pode estar vazio');
      return false;
    }

    final expiryText = expiryDateController.text;
    if (expiryText.isEmpty || expiryText.length < 5) {
      Get.snackbar('Erro', 'Data de validade inválida');
      return false;
    }

    // Verificar se a data não está expirada
    final parts = expiryText.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse('20${parts[1]}');
    final now = DateTime.now();

    if (year < now.year || (year == now.year && month < now.month)) {
      Get.snackbar('Erro', 'Cartão expirado');
      return false;
    }

    if (cvvController.text.isEmpty || cvvController.text.length < 3) {
      Get.snackbar('Erro', 'CVV inválido');
      return false;
    }

    return true;
  }

  // Limpar formulário
  void _clearForm() {
    cardNumberController.clear();
    cardHolderController.clear();
    expiryDateController.clear();
    cvvController.clear();
  }

  // Identificar a bandeira do cartão (simplificado)
  String _identifyCardBrand(String cardNumber) {
    if (cardNumber.startsWith('4')) {
      return 'visa';
    } else if (cardNumber.startsWith('5')) {
      return 'mastercard';
    } else if (cardNumber.startsWith('3')) {
      return 'amex';
    } else if (cardNumber.startsWith('6')) {
      return 'elo';
    } else {
      return 'unknown';
    }
  }

  // Obter o cartão padrão
  Map<String, dynamic>? getDefaultCard() {
    return savedCards.firstWhereOrNull((card) => card['isDefault'] == true);
  }

  // Pagar com um cartão salvo
  Future<bool> payWithSavedCard(String cardId, double amount, String description) async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para fazer um pagamento');
        return false;
      }

      isLoading.value = true;

      // Encontrar o cartão pelo ID
      final card = savedCards.firstWhere(
            (card) => card['id'] == cardId,
        orElse: () => <String, dynamic>{},
      );

      if (card.isEmpty) {
        Get.snackbar('Erro', 'Cartão não encontrado');
        return false;
      }

      // Converter valor para centavos
      final amountInCents = (amount * 100).toInt();

      // Montar objeto de pagamento
      final paymentData = {
        "items": [
          {
            "amount": amountInCents,
            "description": description,
            "quantity": 1
          }
        ],
        "customer_id": _authController.userModel.value!.id,
        "payments": [
          {
            "payment_method": "credit_card",
            "credit_card": {
              "installments": 1,
              "card_token": card['token'],
              "statement_descriptor": "ORACULUM APP"
            }
          }
        ]
      };

      final result = null;//await _pagarmeService.payWithCreditCard(paymentData);

      if (result) {
        Get.snackbar('Sucesso', 'Pagamento realizado com sucesso');
        return true;
      } else {
        Get.snackbar('Erro', 'Falha ao processar o pagamento');
        return false;
      }
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível realizar o pagamento: $e');
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }
}