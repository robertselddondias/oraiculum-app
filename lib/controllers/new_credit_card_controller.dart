import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/services/stripe_payment_service.dart';
import 'package:oraculum/models/credit_card_model.dart';

class NewCreditCardController extends GetxController {
  // Serviços injetados
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthController _authController = Get.find<AuthController>();

  // Novo serviço Stripe
  late StripePaymentService _stripePaymentService;

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

    _stripePaymentService = Get.find<StripePaymentService>();

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
          .collection('credit_cards')
          .where('userId', isEqualTo: userId)
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

  // Adicionar novo cartão - VERSÃO CORRIGIDA COM STRIPE
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

      debugPrint('Iniciando processo de criação de cliente e método de pagamento...');

      // Verificar se o usuário já tem um customer no Stripe
      final userData = await _firebaseService.getUserData(userId);
      final userDoc = userData.data() as Map<String, dynamic>?;

      String customerId = '';

      if (userDoc?['stripeCustomerId'] != null) {
        customerId = userDoc!['stripeCustomerId'];
        debugPrint('Customer Stripe existente: $customerId');
      } else {
        // Criar cliente no Stripe
        final customerResponse = await _stripePaymentService.createCustomer(
          email: userDoc?['email'] ?? _authController.currentUser.value!.email!,
          name: cardHolder,
          phone: phone,
          metadata: {
            'userId': userId,
            'document': document,
          },
        );

        if (!customerResponse['success']) {
          Get.snackbar('Erro', 'Não foi possível criar cliente: ${customerResponse['error']}');
          return false;
        }

        customerId = customerResponse['data']['id'];

        // Salvar customer ID no perfil do usuário
        await _firebaseService.updateUserData(userId, {
          'stripeCustomerId': customerId,
        });

        debugPrint('Novo customer Stripe criado: $customerId');
      }

      // Obter os detalhes do cartão
      final lastFourDigits = cardNumber.substring(cardNumber.length - 4);

      debugPrint('Salvando cartão no Firestore...');

      // Salvar informações do cartão no Firestore
      final docRef = _firebaseService.firestore.collection('credit_cards').doc();

      CreditCardUserModel creditCardModel = CreditCardUserModel();
      creditCardModel.cardId = 'stripe_${docRef.id}'; // Para Stripe, usamos um ID local
      creditCardModel.lastFourDigits = lastFourDigits;
      creditCardModel.brandType = cardBrand.value;
      creditCardModel.cardHolderName = cardHolder;
      creditCardModel.transationalType = 'credit';
      creditCardModel.expirationDate = '$expiryMonth/${expiryParts[1]}';
      creditCardModel.userId = userId;
      creditCardModel.id = docRef.id;
      creditCardModel.cpf = document;
      creditCardModel.phone = phone;
      creditCardModel.cvv = cvv; // Em produção, não armazenar CVV
      creditCardModel.createdAt = DateTime.now();
      creditCardModel.isDefault = true;
      creditCardModel.customerId = customerId;

      // Verificar cartões existentes para atualizar o padrão
      final existingCards = await _firebaseService.firestore
          .collection('credit_cards')
          .where('userId', isEqualTo: userId)
          .get();

      // Usar batch para atualizar múltiplos documentos em uma operação
      final batch = _firebaseService.firestore.batch();

      // Se existirem outros cartões, remover a flag de padrão
      for (var doc in existingCards.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      // Adicionar o novo cartão como padrão
      batch.set(docRef, creditCardModel.toJson());

      // Executar o batch
      await batch.commit();

      debugPrint('Cartão salvo no Firestore com sucesso');

      // Limpar o formulário
      _clearForm();

      // Recarregar cartões
      await loadSavedCards();

      Get.snackbar(
        'Sucesso',
        'Cartão adicionado com sucesso',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      debugPrint('Erro geral ao adicionar cartão: $e');

      // Verificar se é erro específico de autenticação
      if (e.toString().contains('unauthenticated') ||
          e.toString().contains('permission-denied')) {
        Get.snackbar(
          'Erro de Autenticação',
          'Sua sessão expirou. Faça login novamente.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Erro',
          'Não foi possível adicionar o cartão: ${e.toString().split(': ').last}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Remover um cartão - ATUALIZADO PARA USAR STRIPE
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

      // Para Stripe, podemos remover o método de pagamento se necessário
      // Aqui apenas removemos do Firestore
      await _firebaseService.firestore
          .collection('credit_cards')
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
          .collection('credit_cards')
          .where('userId', isEqualTo: userId)
          .get();

      // Remover flag de cartão padrão de todos os cartões
      for (var doc in cardsSnapshot.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      // Definir o cartão selecionado como padrão
      batch.update(
          _firebaseService.firestore
              .collection('credit_cards')
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

  // Processar pagamento com cartão - ATUALIZADO PARA STRIPE
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

      debugPrint('Processando pagamento de R\$ ${amount.toStringAsFixed(2)} via Stripe');

      // Processar pagamento com Stripe
      final paymentResponse = await _stripePaymentService.processCardPayment(
        context: Get.context!,
        amount: amount,
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
        // Pagamento falhou
        final errorMessage = paymentResponse['error'] as String? ?? 'Erro desconhecido no pagamento';

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
      debugPrint('Erro geral no pagamento: $e');

      Get.snackbar(
        'Erro',
        'Não foi possível processar o pagamento: ${e.toString().split(': ').last}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
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
    showBackView.value = false;
  }

  // Validar cartão de crédito (algoritmo de Luhn)
  bool validateCardLuhn(String cardNumber) {
    // Remover espaços e caracteres não numéricos
    cardNumber = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (cardNumber.isEmpty || cardNumber.length < 13) {
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
}