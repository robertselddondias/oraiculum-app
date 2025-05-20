import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/services/pagarme_service.dart';

class NewCreditCardController extends GetxController {
  // Serviços injetados
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthController _authController = Get.find<AuthController>();
  final PagarmeService _pagarmeService = Get.find<PagarmeService>();

  // Controladores para os campos do formulário
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardHolderController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController documentController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Formatadores para os campos
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

  // Focus nodes para controlar o foco dos campos
  final FocusNode cardNumberFocus = FocusNode();
  final FocusNode cardHolderFocus = FocusNode();
  final FocusNode expiryDateFocus = FocusNode();
  final FocusNode cvvFocus = FocusNode();
  final FocusNode documentFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();

  // Variáveis reativas
  final RxBool isLoading = false.obs;
  final RxBool showBackView = false.obs;
  final RxString cardBrand = ''.obs;
  final RxList<Map<String, dynamic>> savedCards = <Map<String, dynamic>>[].obs;

  // Chave para o formulário (validação)
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();

    // Adicionar listeners para detectar mudanças
    cvvFocus.addListener(_onCvvFocusChange);
    cardNumberController.addListener(_updateCardBrand);

    // Carregar cartões salvos
    loadSavedCards();
  }

  @override
  void onClose() {
    // Remover listeners
    cvvFocus.removeListener(_onCvvFocusChange);
    cardNumberController.removeListener(_updateCardBrand);

    // Limpar os controladores
    cardNumberController.dispose();
    cardHolderController.dispose();
    expiryDateController.dispose();
    cvvController.dispose();
    documentController.dispose();
    phoneController.dispose();

    // Limpar os focus nodes
    cardNumberFocus.dispose();
    cardHolderFocus.dispose();
    expiryDateFocus.dispose();
    cvvFocus.dispose();
    documentFocus.dispose();
    phoneFocus.dispose();

    super.onClose();
  }

  // Métodos do controlador
  void _onCvvFocusChange() {
    showBackView.value = cvvFocus.hasFocus;
  }

  void flipCard() {
    showBackView.value = !showBackView.value;
  }

  void _updateCardBrand() {
    final cardNumber = cardNumberController.text.replaceAll(' ', '');

    if (cardNumber.isEmpty) {
      cardBrand.value = '';
      return;
    }

    // Detectar bandeira com base nos primeiros dígitos
    if (cardNumber.startsWith('4')) {
      cardBrand.value = 'visa';
    } else if ((cardNumber.startsWith('5') &&
        int.parse(cardNumber.substring(1, 2)) >= 1 &&
        int.parse(cardNumber.substring(1, 2)) <= 5) ||
        (cardNumber.length >= 4 &&
            int.parse(cardNumber.substring(0, 4)) >= 2221 &&
            int.parse(cardNumber.substring(0, 4)) <= 2720)) {
      cardBrand.value = 'mastercard';
    } else if (cardNumber.startsWith('34') || cardNumber.startsWith('37')) {
      cardBrand.value = 'amex';
    } else if (cardNumber.startsWith('6')) {
      cardBrand.value = 'elo';
    } else if (cardNumber.startsWith('606282')) {
      cardBrand.value = 'hipercard';
    } else if (cardNumber.startsWith('301') || cardNumber.startsWith('305') ||
        cardNumber.startsWith('36') || cardNumber.startsWith('38')) {
      cardBrand.value = 'diners';
    } else {
      cardBrand.value = '';
    }
  }

  // Carregar cartões salvos
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
    }
  }

  // Adicionar novo cartão
  Future<bool> addNewCard() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para adicionar um cartão');
        return false;
      }

      isLoading.value = true;
      final userId = _authController.currentUser.value!.uid;

      // Formatar os dados para envio
      final cardNumber = cardNumberController.text.replaceAll(' ', '');
      final cardHolder = cardHolderController.text;
      final expiryParts = expiryDateController.text.split('/');
      final expiryMonth = expiryParts[0];
      final expiryYear = '20${expiryParts[1]}'; // Assumindo formato MM/YY
      final cvv = cvvController.text;
      final document = documentController.text.replaceAll(RegExp(r'[.-]'), '');
      final phone = phoneController.text.replaceAll(RegExp(r'[() -]'), '');

      // Verificar se o cartão é válido usando o algoritmo de Luhn
      if (!validateCardLuhn(cardNumber)) {
        Get.snackbar('Erro', 'Número de cartão inválido');
        return false;
      }

      // Criar objeto para tokenização
      final cardData = {
        "number": cardNumber,
        "holder_name": cardHolder,
        "exp_month": expiryMonth,
        "exp_year": expiryYear,
        "cvv": cvv,
      };

      // Criar cliente na Pagar.me se necessário
      String? customerId = await _getOrCreatePagarMeCustomer(userId, document, phone, cardHolder);

      if (customerId == null) {
        Get.snackbar('Erro', 'Não foi possível processar seu cadastro');
        return false;
      }

      // Criar token do cartão usando PagarmeService
      final cardId = await _pagarmeService.createCard(
          cardNumber: cardNumber,
          cardHolderName: cardHolder,
          cardExpirationDate: '${expiryMonth}/${expiryParts[1]}',
          cardCvv: cvv,
          documentNumber: document,
          customerId: customerId
      );

      if (cardId.isEmpty) {
        Get.snackbar('Erro', 'Não foi possível tokenizar o cartão');
        return false;
      }

      // Salvar informações do cartão no Firestore
      await _firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('saved_cards')
          .add({
        'cardId': cardId,
        'lastFourDigits': cardNumber.substring(cardNumber.length - 4),
        'cardHolder': cardHolder,
        'expiryMonth': expiryMonth,
        'expiryYear': expiryYear,
        'brand': cardBrand.value,
        'customerId': customerId,
        'isDefault': savedCards.isEmpty, // Se for o primeiro cartão, define como padrão
        'createdAt': DateTime.now(),
      });

      // Limpar o formulário
      _clearForm();

      // Recarregar cartões
      await loadSavedCards();

      Get.snackbar('Sucesso', 'Cartão adicionado com sucesso');
      return true;
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível adicionar o cartão: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Obter ou criar cliente na Pagar.me
  Future<String?> _getOrCreatePagarMeCustomer(
      String userId,
      String document,
      String phone,
      String name
      ) async {
    try {
      final userData = await _firebaseService.getUserData(userId);
      if (userData.exists) {
        final userDoc = userData.data() as Map<String, dynamic>;

        // Verificar se já existe um cliente na Pagar.me
        if (userDoc.containsKey('pagarme_customer_id')) {
          return userDoc['pagarme_customer_id'];
        }

        // Obter e-mail do usuário
        final email = _authController.currentUser.value?.email ?? '';

        // Criar cliente na Pagar.me
        final customerData = {
          "name": name,
          "email": email,
          "type": "individual",
          "document": document,
          "phones": {
            "mobile_phone": {
              "country_code": "55",
              "number": phone.substring(2),
              "area_code": phone.substring(0, 2)
            }
          }
        };

        final customerId = await _pagarmeService.createCustomer(customerData);

        if (customerId.isNotEmpty) {
          // Atualizar ID do cliente no Firestore
          await _firebaseService.updateUserData(userId, {
            'pagarme_customer_id': customerId
          });
          return customerId;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao criar/obter cliente na Pagar.me: $e');
      return null;
    }
  }

  // Remover um cartão
  Future<bool> removeCard(String cardId) async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para remover um cartão');
        return false;
      }

      isLoading.value = true;
      final userId = _authController.currentUser.value!.uid;

      // Verificar se o cartão a ser removido é o padrão
      final cardToRemove = savedCards.firstWhereOrNull((card) => card['id'] == cardId);
      final isDefault = cardToRemove != null && cardToRemove['isDefault'] == true;

      // TODO: Implementar a remoção do cartão na Pagar.me
      // Aqui deveríamos chamar a API da Pagar.me para remover o token do cartão
      // await _pagarmeService.deleteCard(cardToRemove['cardId']);

      // Remover o cartão do Firestore
      await _firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('saved_cards')
          .doc(cardId)
          .delete();

      // Se o cartão removido era o padrão e temos outros cartões,
      // define outro como padrão
      if (isDefault && savedCards.length > 1) {
        final newDefaultId = savedCards
            .where((card) => card['id'] != cardId)
            .first['id'];

        await setDefaultCard(newDefaultId);
      }

      // Atualizar lista local
      savedCards.removeWhere((card) => card['id'] == cardId);

      Get.snackbar('Sucesso', 'Cartão removido com sucesso');
      return true;
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível remover o cartão: $e');
      return false;
    } finally {
      isLoading.value = false;
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

      // Usar batch para atualizar todos os cartões de uma vez
      final batch = _firebaseService.firestore.batch();

      final cardsSnapshot = await _firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('saved_cards')
          .get();

      // Remover flag de cartão padrão de todos os cartões
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
    }
  }

  // Limpar formulário
  void _clearForm() {
    cardNumberController.clear();
    cardHolderController.clear();
    expiryDateController.clear();
    cvvController.clear();
    documentController.clear();
    phoneController.clear();
    cardBrand.value = '';
  }

  // Validar cartão de crédito (algoritmo de Luhn)
  bool validateCardLuhn(String cardNumber) {
    // Remover espaços e caracteres não numéricos
    cardNumber = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (cardNumber.isEmpty) {
      return false;
    }

    // Algoritmo de Luhn
    int sum = 0;
    bool alternate = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cardNumber.substring(i, i + 1));

      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }

      sum += n;
      alternate = !alternate;
    }

    return (sum % 10 == 0);
  }

  // Obter o cartão padrão
  Map<String, dynamic>? getDefaultCard() {
    return savedCards.firstWhereOrNull((card) => card['isDefault'] == true);
  }

  // Processar pagamento com cartão
  Future<bool> processPayment({
    required double amount,
    required String description,
    String? cardId
  }) async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para realizar um pagamento');
        return false;
      }

      isLoading.value = true;
      final userId = _authController.currentUser.value!.uid;

      // Se cardId não foi fornecido, usar o cartão padrão
      if (cardId == null) {
        final defaultCard = getDefaultCard();
        if (defaultCard == null) {
          Get.snackbar('Erro', 'Nenhum cartão padrão definido');
          return false;
        }
        cardId = defaultCard['id'];
      }

      // Encontrar o cartão pelo ID
      final card = savedCards.firstWhere(
            (card) => card['id'] == cardId,
        orElse: () => <String, dynamic>{},
      );

      if (card.isEmpty) {
        Get.snackbar('Erro', 'Cartão não encontrado');
        return false;
      }

      // TODO: Implementar o processamento de pagamento
      // Aqui deveria chamar a API da Pagar.me para processar o pagamento

      // Registrar o pagamento no Firestore
      final paymentData = {
        'userId': userId,
        'cardId': cardId,
        'amount': amount,
        'description': description,
        'status': 'approved', // Temporário, deveria vir da resposta da API
        'timestamp': DateTime.now(),
      };

      await _firebaseService.firestore
          .collection('payments')
          .add(paymentData);

      Get.snackbar('Sucesso', 'Pagamento realizado com sucesso');
      return true;
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível realizar o pagamento: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}