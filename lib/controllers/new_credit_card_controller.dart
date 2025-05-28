import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/services/stripe_payment_service.dart';
import 'package:oraculum/models/credit_card_model.dart';

class NewCreditCardController extends GetxController {
  // ===========================================
  // DEPENDÊNCIAS
  // ===========================================
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthController _authController = Get.find<AuthController>();
  late StripePaymentService _stripePaymentService;

  // ===========================================
  // CONTROLADORES DE FORMULÁRIO
  // ===========================================
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardHolderController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController documentController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // ===========================================
  // FORMATADORES DE ENTRADA
  // ===========================================
  final cardNumberFormatter = MaskTextInputFormatter(
    mask: '#### #### #### ####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final expiryDateFormatter = MaskTextInputFormatter(
    mask: '##/##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final cvvFormatter = MaskTextInputFormatter(
    mask: '####',
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

  // ===========================================
  // FOCUS NODES
  // ===========================================
  final FocusNode cardNumberFocus = FocusNode();
  final FocusNode cardHolderFocus = FocusNode();
  final FocusNode expiryDateFocus = FocusNode();
  final FocusNode cvvFocus = FocusNode();
  final FocusNode documentFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();

  // ===========================================
  // VARIÁVEIS REATIVAS
  // ===========================================
  final RxString cardType = 'credit'.obs;
  final RxBool isLoading = false.obs;
  final RxBool showBackView = false.obs;
  final RxString cardBrand = ''.obs;
  final RxList<Map<String, dynamic>> savedCards = <Map<String, dynamic>>[].obs;
  final RxBool isCardValid = false.obs;
  final RxString validationMessage = ''.obs;

  // Chave para o formulário
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();

    _stripePaymentService = Get.find<StripePaymentService>();

    // Adicionar listeners
    _setupListeners();

    // Carregar cartões salvos
    loadSavedCards();
  }

  @override
  void onClose() {
    _removeListeners();
    _disposeControllers();
    _disposeFocusNodes();
    super.onClose();
  }

  // ===========================================
  // CONFIGURAÇÃO DE LISTENERS
  // ===========================================

  void _setupListeners() {
    cvvFocus.addListener(_onCvvFocusChange);
    cardNumberController.addListener(_updateCardBrand);
    cardNumberController.addListener(_validateCardNumber);
    expiryDateController.addListener(_validateExpiryDate);
    cvvController.addListener(_validateCvv);
    cardHolderController.addListener(_validateCardHolder);
  }

  void _removeListeners() {
    cvvFocus.removeListener(_onCvvFocusChange);
    cardNumberController.removeListener(_updateCardBrand);
    cardNumberController.removeListener(_validateCardNumber);
    expiryDateController.removeListener(_validateExpiryDate);
    cvvController.removeListener(_validateCvv);
    cardHolderController.removeListener(_validateCardHolder);
  }

  void _disposeControllers() {
    cardNumberController.dispose();
    cardHolderController.dispose();
    expiryDateController.dispose();
    cvvController.dispose();
    documentController.dispose();
    phoneController.dispose();
  }

  void _disposeFocusNodes() {
    cardNumberFocus.dispose();
    cardHolderFocus.dispose();
    expiryDateFocus.dispose();
    cvvFocus.dispose();
    documentFocus.dispose();
    phoneFocus.dispose();
  }

  // ===========================================
  // MÉTODOS DE VALIDAÇÃO EM TEMPO REAL
  // ===========================================

  void _validateCardNumber() {
    final cardNumber = cardNumberController.text.replaceAll(' ', '');

    if (cardNumber.isEmpty) {
      isCardValid.value = false;
      validationMessage.value = '';
      return;
    }

    if (cardNumber.length < 16) {
      isCardValid.value = false;
      validationMessage.value = 'Número incompleto';
      return;
    }

    if (!validateCardLuhn(cardNumber)) {
      isCardValid.value = false;
      validationMessage.value = 'Número inválido';
      return;
    }

    isCardValid.value = true;
    validationMessage.value = 'Cartão válido';
  }

  void _validateExpiryDate() {
    final expiry = expiryDateController.text;

    if (expiry.isEmpty) return;

    if (expiry.length == 5) {
      final parts = expiry.split('/');
      if (parts.length == 2) {
        final month = int.tryParse(parts[0]);
        final year = int.tryParse('20${parts[1]}');

        if (month == null || year == null || month < 1 || month > 12) {
          validationMessage.value = 'Data inválida';
          return;
        }

        final now = DateTime.now();
        final cardDate = DateTime(year, month);
        if (cardDate.isBefore(DateTime(now.year, now.month))) {
          validationMessage.value = 'Cartão expirado';
          return;
        }

        validationMessage.value = 'Data válida';
      }
    }
  }

  void _validateCvv() {
    final cvv = cvvController.text;
    if (cvv.length >= 3) {
      validationMessage.value = 'CVV válido';
    }
  }

  void _validateCardHolder() {
    final holder = cardHolderController.text.trim();
    if (holder.length >= 3) {
      validationMessage.value = 'Nome válido';
    }
  }

  // ===========================================
  // MÉTODOS DE INTERFACE
  // ===========================================

  void setCardType(String type) {
    cardType.value = type;
    _updateCvvMask();
    update();
  }

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
    } else if (_isMastercard(cardNumber)) {
      cardBrand.value = 'mastercard';
    } else if (cardNumber.startsWith('34') || cardNumber.startsWith('37')) {
      cardBrand.value = 'amex';
    } else if (cardNumber.startsWith('6')) {
      cardBrand.value = 'elo';
    } else if (cardNumber.startsWith('606282')) {
      cardBrand.value = 'hipercard';
    } else if (_isDiners(cardNumber)) {
      cardBrand.value = 'diners';
    } else {
      cardBrand.value = '';
    }

    _updateCvvMask();
  }

  bool _isMastercard(String cardNumber) {
    if (cardNumber.length < 4) return false;

    final firstDigit = int.tryParse(cardNumber.substring(0, 1)) ?? 0;
    final firstTwoDigits = int.tryParse(cardNumber.substring(0, 2)) ?? 0;
    final firstFourDigits = int.tryParse(cardNumber.substring(0, 4)) ?? 0;

    return (firstDigit == 5 && firstTwoDigits >= 51 && firstTwoDigits <= 55) ||
        (firstFourDigits >= 2221 && firstFourDigits <= 2720);
  }

  bool _isDiners(String cardNumber) {
    return cardNumber.startsWith('301') ||
        cardNumber.startsWith('305') ||
        cardNumber.startsWith('36') ||
        cardNumber.startsWith('38');
  }

  void _updateCvvMask() {
    // American Express tem CVV de 4 dígitos
    if (cardBrand.value == 'amex') {
      cvvFormatter.updateMask(mask: '####');
    } else {
      cvvFormatter.updateMask(mask: '###');
    }
  }

  // ===========================================
  // GESTÃO DE CARTÕES
  // ===========================================

  Future<void> loadSavedCards() async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para acessar seus cartões');
        return;
      }

      isLoading.value = true;
      final userId = _authController.currentUser.value!.uid;

      final cardsSnapshot = await _firebaseService.firestore
          .collection('credit_cards')
          .where('userId', isEqualTo: userId)
          .get();

      savedCards.value = cardsSnapshot.docs.map((doc) {
        final data = doc.data();

        // Extração segura da data de expiração
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
          'cardType': data['transationalType'] ?? 'credit',
        };
      }).toList();

      // Ordenar cartões (padrão primeiro)
      _sortCards();
    } catch (e) {
      debugPrint('Erro ao carregar cartões: $e');
      Get.snackbar('Erro', 'Não foi possível carregar os cartões: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _sortCards() {
    savedCards.sort((a, b) {
      if (a['isDefault'] == true && b['isDefault'] != true) return -1;
      if (b['isDefault'] == true && a['isDefault'] != true) return 1;
      return 0;
    });
  }

  // ===========================================
  // ADICIONAR NOVO CARTÃO
  // ===========================================

  Future<bool> addNewCard() async {
    if (!formKey.currentState!.validate()) {
      Get.snackbar('Formulário Inválido', 'Por favor, corrija os erros no formulário');
      return false;
    }

    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para adicionar um cartão');
        return false;
      }

      isLoading.value = true;
      final userId = _authController.currentUser.value!.uid;

      // Verificar autenticação
      final isAuthenticated = await _authController.ensureAuthenticated();
      if (!isAuthenticated) {
        Get.snackbar('Erro de Autenticação', 'Sua sessão expirou. Faça login novamente.');
        return false;
      }

      // Preparar dados do formulário
      final cardData = _prepareCardData();

      // Validar dados básicos
      if (!_validateCardData(cardData)) {
        return false;
      }

      debugPrint('Criando cartão com dados do formulário...');

      // 1. Obter ou criar customer no Stripe
      final customerId = await _getOrCreateStripeCustomer(userId, cardData);
      if (customerId.isEmpty) {
        Get.snackbar('Erro', 'Não foi possível criar cliente no Stripe');
        return false;
      }

      // 2. Criar PaymentMethod diretamente via API
      final paymentMethodResult = await _createPaymentMethodDirectly(cardData);
      if (!paymentMethodResult['success']) {
        Get.snackbar('Erro', paymentMethodResult['error']);
        return false;
      }

      final paymentMethodId = paymentMethodResult['data']['id'];
      final cardInfo = paymentMethodResult['data']['card'];

      debugPrint('✅ PaymentMethod criado: $paymentMethodId');

      // 3. Anexar método de pagamento ao customer
      final attachResult = await _attachPaymentMethodToCustomer(paymentMethodId, customerId);
      if (!attachResult['success']) {
        Get.snackbar('Erro', 'Falha ao vincular cartão: ${attachResult['error']}');
        return false;
      }

      debugPrint('✅ PaymentMethod anexado ao customer');

      // 4. Salvar no Firestore
      final success = await _saveCardToFirestore(
        userId: userId,
        customerId: customerId,
        paymentMethodId: paymentMethodId,
        cardInfo: cardInfo,
        cardData: cardData,
      );

      if (success) {
        _clearForm();
        await loadSavedCards();

        Get.snackbar(
          'Sucesso',
          'Cartão ${cardType.value == 'credit' ? 'de crédito' : 'de débito'} adicionado com sucesso',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      }

      return false;

    } on StripeException catch (e) {
      debugPrint('❌ Erro do Stripe: ${e.error.localizedMessage}');

      Get.snackbar(
        'Erro no Cartão',
        _getStripeErrorMessage(e.error.code?.toString(), e.error.localizedMessage),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e) {
      debugPrint('❌ Erro geral ao adicionar cartão: $e');
      _handleGeneralError(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Criar PaymentMethod diretamente via API REST com os dados do formulário
  Future<Map<String, dynamic>> _createPaymentMethodDirectly(Map<String, dynamic> cardData) async {
    try {
      debugPrint('Criando PaymentMethod com dados do formulário');
      debugPrint('Número do cartão: ${cardData['cardNumber'].substring(0, 4)}****');
      debugPrint('Titular: ${cardData['cardHolder']}');
      debugPrint('Expiração: ${cardData['expiryMonth']}/${cardData['expiryYear']}');

      final url = 'https://api.stripe.com/v1/payment_methods';
      final headers = {
        'Authorization': 'Bearer sk_test_51RTpqm4TyzboYffkLCT1uIvlITbGX3vgRC6rNnduYStBy2wg99c4DxrraH75S4ATZiPEOdk3KxsYlR8fVQ661CkV00r5Yt8XgO',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      final body = {
        'type': 'card',
        'card[number]': cardData['cardNumber'],
        'card[exp_month]': cardData['expiryMonth'].toString(),
        'card[exp_year]': cardData['expiryYear'].toString(),
        'card[cvc]': cardData['cvv'],
        'billing_details[name]': cardData['cardHolder'],
        'billing_details[phone]': cardData['phone'],
        'billing_details[address][country]': 'BR',
      };

      debugPrint('Enviando requisição para Stripe...');
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      debugPrint('Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ PaymentMethod criado com sucesso: ${data['id']}');

        return {
          'success': true,
          'data': {
            'id': data['id'],
            'card': {
              'last4': data['card']['last4'],
              'brand': data['card']['brand'],
              'exp_month': data['card']['exp_month'],
              'exp_year': data['card']['exp_year'],
            }
          }
        };
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']['message'] ?? 'Erro desconhecido';
        debugPrint('❌ Erro na API: $errorMessage');

        return {
          'success': false,
          'error': errorMessage
        };
      }

    } catch (e) {
      debugPrint('❌ Erro na requisição: $e');
      return {
        'success': false,
        'error': 'Erro ao processar cartão: $e'
      };
    }
  }

  /// Anexar PaymentMethod ao Customer
  Future<Map<String, dynamic>> _attachPaymentMethodToCustomer(String paymentMethodId, String customerId) async {
    try {
      debugPrint('Anexando PaymentMethod $paymentMethodId ao Customer $customerId');

      final url = 'https://api.stripe.com/v1/payment_methods/$paymentMethodId/attach';
      final headers = {
        'Authorization': 'Bearer sk_test_51RTpqm4TyzboYffkLCT1uIvlITbGX3vgRC6rNnduYStBy2wg99c4DxrraH75S4ATZiPEOdk3KxsYlR8fVQ661CkV00r5Yt8XgO',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      final body = {
        'customer': customerId,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ PaymentMethod anexado com sucesso');
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']['message'] ?? 'Erro ao anexar cartão';
        debugPrint('❌ Erro ao anexar: $errorMessage');

        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      debugPrint('❌ Erro na requisição de anexar: $e');
      return {
        'success': false,
        'error': 'Erro na requisição: $e',
      };
    }
  }

  Map<String, dynamic> _prepareCardData() {
    final expiryParts = expiryDateController.text.split('/');
    return {
      'cardNumber': cardNumberController.text.replaceAll(' ', ''),
      'cardHolder': cardHolderController.text.trim(),
      'expiryMonth': int.parse(expiryParts[0]),
      'expiryYear': int.parse('20${expiryParts[1]}'),
      'cvv': cvvController.text,
      'document': documentController.text.replaceAll(RegExp(r'[.-]'), ''),
      'phone': phoneController.text.replaceAll(RegExp(r'[() -]'), ''),
    };
  }

  bool _validateCardData(Map<String, dynamic> cardData) {
    if (!validateCardLuhn(cardData['cardNumber'])) {
      Get.snackbar('Erro', 'Número de cartão inválido');
      return false;
    }

    if (cardData['cardHolder'].length < 3) {
      Get.snackbar('Erro', 'Nome do titular muito curto');
      return false;
    }

    if (cardData['document'].length != 11) {
      Get.snackbar('Erro', 'CPF inválido');
      return false;
    }

    return true;
  }

  Future<String> _getOrCreateStripeCustomer(String userId, Map<String, dynamic> cardData) async {
    try {
      final userData = await _firebaseService.getUserData(userId);
      final userDoc = userData.data() as Map<String, dynamic>?;

      if (userDoc?['stripeCustomerId'] != null) {
        return userDoc!['stripeCustomerId'];
      }

      // Criar novo customer
      final customerResponse = await _stripePaymentService.createCustomer(
        email: userDoc?['email'] ?? _authController.currentUser.value!.email!,
        name: cardData['cardHolder'],
        phone: cardData['phone'],
        metadata: {
          'userId': userId,
          'document': cardData['document'],
        },
      );

      if (!customerResponse['success']) {
        throw Exception('Falha ao criar customer: ${customerResponse['error']}');
      }

      final customerId = customerResponse['data']['id'];

      // Salvar customer ID no perfil do usuário
      await _firebaseService.updateUserData(userId, {
        'stripeCustomerId': customerId,
      });

      return customerId;
    } catch (e) {
      debugPrint('Erro ao obter/criar customer: $e');
      return '';
    }
  }

  /// Obter Customer ID do Stripe do usuário atual
  Future<String> _getStripeCustomerId() async {
    try {
      final userId = _authController.currentUser.value?.uid ?? '';
      if (userId.isEmpty) return '';

      final userData = await _firebaseService.getUserData(userId);
      final userDoc = userData.data() as Map<String, dynamic>?;

      return userDoc?['stripeCustomerId'] ?? '';
    } catch (e) {
      debugPrint('Erro ao obter Customer ID: $e');
      return '';
    }
  }

  Future<bool> _saveCardToFirestore({
    required String userId,
    required String customerId,
    required String paymentMethodId,
    required Map<String, dynamic> cardInfo,
    required Map<String, dynamic> cardData,
  }) async {
    try {
      final docRef = _firebaseService.firestore.collection('credit_cards').doc();

      final creditCardModel = CreditCardUserModel();
      creditCardModel.cardId = paymentMethodId;
      creditCardModel.lastFourDigits = cardInfo['last4'];
      creditCardModel.brandType = cardInfo['brand'];
      creditCardModel.cardHolderName = cardData['cardHolder'];
      creditCardModel.transationalType = cardType.value;
      creditCardModel.expirationDate = '${cardData['expiryMonth'].toString().padLeft(2, '0')}/${cardData['expiryYear'].toString().substring(2)}';
      creditCardModel.userId = userId;
      creditCardModel.id = docRef.id;
      creditCardModel.cpf = cardData['document'];
      creditCardModel.phone = cardData['phone'];
      creditCardModel.createdAt = DateTime.now();
      creditCardModel.isDefault = savedCards.isEmpty; // Primeiro cartão é padrão
      creditCardModel.customerId = customerId;

      // Usar batch para operações atômicas
      final batch = _firebaseService.firestore.batch();

      // Se não é o primeiro cartão, remover flag de padrão dos outros
      if (savedCards.isNotEmpty) {
        final existingCardsSnapshot = await _firebaseService.firestore
            .collection('credit_cards')
            .where('userId', isEqualTo: userId)
            .get();

        for (var doc in existingCardsSnapshot.docs) {
          batch.update(doc.reference, {'isDefault': false});
        }
      }

      // Adicionar novo cartão
      batch.set(docRef, creditCardModel.toJson());
      await batch.commit();

      debugPrint('✅ Cartão salvo no Firestore com sucesso');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao salvar cartão no Firestore: $e');
      Get.snackbar('Erro', 'Não foi possível salvar o cartão: $e');
      return false;
    }
  }

  // ===========================================
  // GERENCIAR CARTÕES EXISTENTES
  // ===========================================

  Future<bool> removeCard(String cardId) async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para remover um cartão');
        return false;
      }

      isLoading.value = true;
      final userId = _authController.currentUser.value!.uid;

      // Encontrar o cartão
      final cardToRemove = savedCards.firstWhereOrNull((card) => card['id'] == cardId);
      if (cardToRemove == null) {
        Get.snackbar('Erro', 'Cartão não encontrado');
        return false;
      }

      final isDefault = cardToRemove['isDefault'] == true;

      // Remover do Firestore
      await _firebaseService.firestore
          .collection('credit_cards')
          .doc(cardId)
          .delete();

      // Se era o padrão e há outros cartões, definir outro como padrão
      if (isDefault && savedCards.length > 1) {
        final newDefaultCard = savedCards.firstWhere((card) => card['id'] != cardId);
        await setDefaultCard(newDefaultCard['id']);
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

  Future<bool> setDefaultCard(String cardId) async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado');
        return false;
      }

      isLoading.value = true;
      final userId = _authController.currentUser.value!.uid;

      // Usar batch para operação atômica
      final batch = _firebaseService.firestore.batch();

      final cardsSnapshot = await _firebaseService.firestore
          .collection('credit_cards')
          .where('userId', isEqualTo: userId)
          .get();

      // Remover flag de padrão de todos os cartões
      for (var doc in cardsSnapshot.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      // Definir o novo cartão padrão
      batch.update(
          _firebaseService.firestore.collection('credit_cards').doc(cardId),
          {'isDefault': true}
      );

      await batch.commit();

      // Atualizar lista local
      for (var card in savedCards) {
        card['isDefault'] = card['id'] == cardId;
      }
      _sortCards();
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

  // ===========================================
  // PROCESSAMENTO DE PAGAMENTOS
  // ===========================================

  Future<bool> processPayment({
    required double amount,
    required String description,
    String? cardId,
  }) async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para realizar um pagamento');
        return false;
      }

      isLoading.value = true;
      final userId = _authController.currentUser.value!.uid;

      // Buscar cartão a ser usado
      Map<String, dynamic>? selectedCard;
      if (cardId != null) {
        selectedCard = savedCards.firstWhereOrNull((card) => card['id'] == cardId);
      } else {
        selectedCard = getDefaultCard();
      }

      if (selectedCard == null) {
        Get.snackbar('Erro', 'Nenhum cartão encontrado');
        return false;
      }

      final customerId = selectedCard['customerId'];
      if (customerId == null || customerId.isEmpty) {
        Get.snackbar('Erro', 'ID do cliente não encontrado');
        return false;
      }

      debugPrint('Processando pagamento de R\$ ${amount.toStringAsFixed(2)}');

      // Processar pagamento com Stripe
      final paymentResponse = await _stripePaymentService.processCardPaymentWithSavedCard(
        amount: amount,
        customerId: customerId,
        description: description,
        serviceId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
        serviceType: 'credit_purchase',
      );

      if (paymentResponse['success'] == true) {
        Get.snackbar(
          'Sucesso',
          'Pagamento realizado com sucesso',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      } else {
        final errorMessage = paymentResponse['error'] as String? ?? 'Erro desconhecido';
        Get.snackbar(
          'Erro no Pagamento',
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      debugPrint('Erro no pagamento: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível processar o pagamento: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================
  // MÉTODOS AUXILIARES
  // ===========================================

  void _clearForm() {
    cardNumberController.clear();
    cardHolderController.clear();
    expiryDateController.clear();
    cvvController.clear();
    documentController.clear();
    phoneController.clear();
    cardBrand.value = '';
    cardType.value = 'credit';
    showBackView.value = false;
    isCardValid.value = false;
    validationMessage.value = '';
  }

  bool validateCardLuhn(String cardNumber) {
    cardNumber = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (cardNumber.isEmpty || cardNumber.length < 13) {
      return false;
    }

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

  Map<String, dynamic>? getDefaultCard() {
    return savedCards.firstWhereOrNull((card) => card['isDefault'] == true);
  }

  bool isCardExpired(Map<String, dynamic> card) {
    try {
      final expiryMonth = int.parse(card['expiryMonth'] ?? '12');
      final expiryYear = int.parse(card['expiryYear'] ?? '2099');

      final now = DateTime.now();
      final cardExpiryDate = DateTime(expiryYear, expiryMonth + 1, 0);

      return cardExpiryDate.isBefore(now);
    } catch (e) {
      return false;
    }
  }

  String getCardBrandName(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return 'Visa';
      case 'mastercard':
        return 'Mastercard';
      case 'amex':
        return 'American Express';
      case 'elo':
        return 'Elo';
      case 'hipercard':
        return 'Hipercard';
      case 'diners':
        return 'Diners Club';
      default:
        return 'Cartão';
    }
  }

  Color getCardBrandColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Colors.blue;
      case 'mastercard':
        return Colors.red;
      case 'amex':
        return Colors.indigo;
      case 'elo':
        return Colors.green;
      case 'hipercard':
        return Colors.orange;
      case 'diners':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  String formatCardNumber(String cardNumber) {
    cardNumber = cardNumber.replaceAll(' ', '');
    if (cardNumber.length <= 4) return cardNumber;

    // Formato padrão: **** **** **** 1234
    if (cardNumber.length >= 16) {
      final lastFour = cardNumber.substring(cardNumber.length - 4);
      return '**** **** **** $lastFour';
    }

    return cardNumber;
  }

  String formatExpiryDate(String month, String year) {
    final formattedMonth = month.padLeft(2, '0');
    final formattedYear = year.length == 2 ? year : year.substring(2);
    return '$formattedMonth/$formattedYear';
  }

  // ===========================================
  // TRATAMENTO DE ERROS
  // ===========================================

  String _getStripeErrorMessage(String? errorCode, String? errorMessage) {
    switch (errorCode?.toLowerCase()) {
      case 'card_declined':
        return 'Cartão recusado. Verifique os dados ou tente outro cartão.';
      case 'expired_card':
        return 'Cartão expirado. Use um cartão válido.';
      case 'incorrect_cvc':
        return 'CVV incorreto. Verifique o código de segurança.';
      case 'processing_error':
        return 'Erro no processamento. Tente novamente.';
      case 'incorrect_number':
        return 'Número do cartão incorreto.';
      case 'invalid_expiry_month':
        return 'Mês de expiração inválido.';
      case 'invalid_expiry_year':
        return 'Ano de expiração inválido.';
      case 'invalid_cvc':
        return 'CVV inválido.';
      case 'card_not_supported':
        return 'Tipo de cartão não suportado.';
      case 'currency_not_supported':
        return 'Moeda não suportada.';
      case 'duplicate_transaction':
        return 'Transação duplicada detectada.';
      case 'fraudulent':
        return 'Transação bloqueada por segurança.';
      case 'generic_decline':
        return 'Cartão recusado pelo banco.';
      case 'insufficient_funds':
        return 'Saldo insuficiente.';
      case 'invalid_account':
        return 'Conta inválida.';
      case 'lost_card':
        return 'Cartão reportado como perdido.';
      case 'merchant_blacklist':
        return 'Transação não permitida.';
      case 'new_account_information_available':
        return 'Informações da conta foram atualizadas. Tente novamente.';
      case 'no_action_taken':
        return 'Nenhuma ação foi tomada pelo banco.';
      case 'not_permitted':
        return 'Transação não permitida.';
      case 'pickup_card':
        return 'Entre em contato com seu banco.';
      case 'pin_try_exceeded':
        return 'Muitas tentativas de PIN. Tente mais tarde.';
      case 'restricted_card':
        return 'Cartão com restrições.';
      case 'revocation_of_all_authorizations':
        return 'Todas as autorizações foram revogadas.';
      case 'revocation_of_authorization':
        return 'Autorização revogada.';
      case 'security_violation':
        return 'Violação de segurança detectada.';
      case 'service_not_allowed':
        return 'Serviço não permitido para este cartão.';
      case 'stolen_card':
        return 'Cartão reportado como roubado.';
      case 'stop_payment_order':
        return 'Ordem de parada de pagamento.';
      case 'testmode_decline':
        return 'Cartão de teste recusado.';
      case 'transaction_not_allowed':
        return 'Transação não permitida.';
      case 'try_again_later':
        return 'Tente novamente mais tarde.';
      case 'withdrawal_count_limit_exceeded':
        return 'Limite de transações excedido.';
      default:
        return errorMessage ?? 'Erro ao processar cartão. Tente novamente.';
    }
  }

  void _handleGeneralError(dynamic error) {
    String errorMessage = 'Não foi possível adicionar o cartão';

    if (error.toString().contains('unauthenticated') ||
        error.toString().contains('permission-denied')) {
      errorMessage = 'Sua sessão expirou. Faça login novamente.';
      Get.snackbar(
        'Erro de Autenticação',
        errorMessage,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else if (error.toString().contains('network')) {
      errorMessage = 'Erro de conexão. Verifique sua internet.';
      Get.snackbar(
        'Erro de Conexão',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Erro',
        '$errorMessage: ${error.toString().split(': ').last}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ===========================================
  // MÉTODOS DE VALIDAÇÃO AVANÇADA
  // ===========================================

  bool isValidCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    if (cpf.length != 11) return false;

    // Verificar se todos os dígitos são iguais
    if (cpf.split('').every((digit) => digit == cpf[0])) return false;

    // Calcular primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int remainder = sum % 11;
    int firstDigit = remainder < 2 ? 0 : 11 - remainder;

    if (int.parse(cpf[9]) != firstDigit) return false;

    // Calcular segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    remainder = sum % 11;
    int secondDigit = remainder < 2 ? 0 : 11 - remainder;

    return int.parse(cpf[10]) == secondDigit;
  }

  bool isValidPhone(String phone) {
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return phone.length >= 10 && phone.length <= 11;
  }

  String? validateCardNumberField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Digite o número do cartão';
    }

    final cardNumber = value.replaceAll(' ', '');
    if (cardNumber.length < 16) {
      return 'Número do cartão incompleto';
    }

    if (!validateCardLuhn(cardNumber)) {
      return 'Número do cartão inválido';
    }

    return null;
  }

  String? validateCardHolderField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Digite o nome do titular';
    }

    if (value.trim().length < 3) {
      return 'Nome muito curto';
    }

    // Verificar se contém pelo menos nome e sobrenome
    if (!value.trim().contains(' ')) {
      return 'Digite nome e sobrenome';
    }

    return null;
  }

  String? validateExpiryDateField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Digite a validade';
    }

    if (value.length < 5) {
      return 'Formato inválido';
    }

    final parts = value.split('/');
    if (parts.length != 2) {
      return 'Formato inválido';
    }

    final month = int.tryParse(parts[0]);
    final year = int.tryParse('20${parts[1]}');

    if (month == null || year == null || month < 1 || month > 12) {
      return 'Data inválida';
    }

    final now = DateTime.now();
    final cardDate = DateTime(year, month);
    if (cardDate.isBefore(DateTime(now.year, now.month))) {
      return 'Cartão expirado';
    }

    return null;
  }

  String? validateCvvField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Digite o CVV';
    }

    final minLength = cardBrand.value == 'amex' ? 4 : 3;
    if (value.length < minLength) {
      return 'CVV inválido';
    }

    return null;
  }

  String? validateDocumentField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Digite o CPF';
    }

    if (!isValidCPF(value)) {
      return 'CPF inválido';
    }

    return null;
  }

  String? validatePhoneField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Digite o celular';
    }

    if (!isValidPhone(value)) {
      return 'Número de celular inválido';
    }

    return null;
  }

  // ===========================================
  // MÉTODOS DE UTILIDADE
  // ===========================================

  void refreshCards() async {
    await loadSavedCards();
  }

  int get cardCount => savedCards.length;

  bool get hasCards => savedCards.isNotEmpty;

  bool get hasDefaultCard => savedCards.any((card) => card['isDefault'] == true);

  List<Map<String, dynamic>> get activeCards =>
      savedCards.where((card) => !isCardExpired(card)).toList();

  List<Map<String, dynamic>> get expiredCards =>
      savedCards.where((card) => isCardExpired(card)).toList();

  List<Map<String, dynamic>> getCardsByBrand(String brand) =>
      savedCards.where((card) => card['brand'] == brand).toList();

  Map<String, int> get cardBrandCounts {
    final counts = <String, int>{};
    for (final card in savedCards) {
      final brand = card['brand'] as String;
      counts[brand] = (counts[brand] ?? 0) + 1;
    }
    return counts;
  }

  // Método para testar conectividade com Stripe
  Future<bool> testStripeConnection() async {
    try {
      // Tentar criar um customer de teste
      final result = await _stripePaymentService.createCustomer(
        email: 'test@test.com',
        name: 'Test User',
        metadata: {'test': 'true'},
      );

      if (result['success']) {
        debugPrint('✅ Conexão com Stripe OK');
        return true;
      } else {
        debugPrint('❌ Falha na conexão com Stripe: ${result['error']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erro ao testar conexão com Stripe: $e');
      return false;
    }
  }

  // Método para debug - mostrar informações do cartão
  void debugCardInfo(String cardId) {
    final card = savedCards.firstWhereOrNull((c) => c['id'] == cardId);
    if (card != null) {
      debugPrint('=== CARD DEBUG INFO ===');
      debugPrint('ID: ${card['id']}');
      debugPrint('Last 4: ${card['lastFourDigits']}');
      debugPrint('Brand: ${card['brand']}');
      debugPrint('Holder: ${card['cardHolder']}');
      debugPrint('Type: ${card['cardType']}');
      debugPrint('Default: ${card['isDefault']}');
      debugPrint('Expired: ${isCardExpired(card)}');
      debugPrint('Customer ID: ${card['customerId']}');
      debugPrint('======================');
    }
  }
}