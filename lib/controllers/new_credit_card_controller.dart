// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
// import 'package:oraculum/controllers/auth_controller.dart';
// import 'package:oraculum/services/firebase_service.dart';
// import 'package:oraculum/services/stripe_payment_service.dart';
//
// class NewCreditCardController extends GetxController {
//   // ===========================================
//   // DEPENDÊNCIAS ATUALIZADAS
//   // ===========================================
//   final FirebaseService _firebaseService = Get.find<FirebaseService>();
//   final AuthController _authController = Get.find<AuthController>();
//
//   // Nova dependência do Stripe Gateway Service
//   final StripePaymentService _stripeGatewayService = Get.find<StripePaymentService>();
//
//   // ===========================================
//   // CONTROLADORES DE FORMULÁRIO
//   // ===========================================
//   final TextEditingController cardNumberController = TextEditingController();
//   final TextEditingController cardHolderController = TextEditingController();
//   final TextEditingController expiryDateController = TextEditingController();
//   final TextEditingController cvvController = TextEditingController();
//   final TextEditingController documentController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//
//   // ===========================================
//   // FORMATADORES DE ENTRADA
//   // ===========================================
//   final cardNumberFormatter = MaskTextInputFormatter(
//     mask: '#### #### #### ####',
//     filter: {"#": RegExp(r'[0-9]')},
//   );
//
//   final expiryDateFormatter = MaskTextInputFormatter(
//     mask: '##/##',
//     filter: {"#": RegExp(r'[0-9]')},
//   );
//
//   final cvvFormatter = MaskTextInputFormatter(
//     mask: '####',
//     filter: {"#": RegExp(r'[0-9]')},
//   );
//
//   final documentFormatter = MaskTextInputFormatter(
//     mask: '###.###.###-##',
//     filter: {"#": RegExp(r'[0-9]')},
//   );
//
//   final phoneFormatter = MaskTextInputFormatter(
//     mask: '(##) #####-####',
//     filter: {"#": RegExp(r'[0-9]')},
//   );
//
//   // ===========================================
//   // FOCUS NODES
//   // ===========================================
//   final FocusNode cardNumberFocus = FocusNode();
//   final FocusNode cardHolderFocus = FocusNode();
//   final FocusNode expiryDateFocus = FocusNode();
//   final FocusNode cvvFocus = FocusNode();
//   final FocusNode documentFocus = FocusNode();
//   final FocusNode phoneFocus = FocusNode();
//
//   // ===========================================
//   // VARIÁVEIS REATIVAS
//   // ===========================================
//   final RxString cardType = 'credit'.obs;
//   final RxBool isLoading = false.obs;
//   final RxBool showBackView = false.obs;
//   final RxString cardBrand = ''.obs;
//   final RxList<Map<String, dynamic>> savedCards = <Map<String, dynamic>>[].obs;
//
//   // Chave para o formulário
//   final formKey = GlobalKey<FormState>();
//
//   @override
//   void onInit() {
//     super.onInit();
//     _setupListeners();
//     loadSavedCards();
//   }
//
//   @override
//   void onClose() {
//     _removeListeners();
//     _disposeControllers();
//     _disposeFocusNodes();
//     super.onClose();
//   }
//
//   // ===========================================
//   // CONFIGURAÇÃO DE LISTENERS
//   // ===========================================
//
//   void _setupListeners() {
//     cvvFocus.addListener(_onCvvFocusChange);
//     cardNumberController.addListener(_updateCardBrand);
//   }
//
//   void _removeListeners() {
//     cvvFocus.removeListener(_onCvvFocusChange);
//     cardNumberController.removeListener(_updateCardBrand);
//   }
//
//   void _disposeControllers() {
//     cardNumberController.dispose();
//     cardHolderController.dispose();
//     expiryDateController.dispose();
//     cvvController.dispose();
//     documentController.dispose();
//     phoneController.dispose();
//   }
//
//   void _disposeFocusNodes() {
//     cardNumberFocus.dispose();
//     cardHolderFocus.dispose();
//     expiryDateFocus.dispose();
//     cvvFocus.dispose();
//     documentFocus.dispose();
//     phoneFocus.dispose();
//   }
//
//   // ===========================================
//   // MÉTODOS DE INTERFACE
//   // ===========================================
//
//   void setCardType(String type) {
//     cardType.value = type;
//     _updateCvvMask();
//     update();
//   }
//
//   void _onCvvFocusChange() {
//     showBackView.value = cvvFocus.hasFocus;
//   }
//
//   void flipCard() {
//     showBackView.value = !showBackView.value;
//   }
//
//   void _updateCardBrand() {
//     final cardNumber = cardNumberController.text.replaceAll(' ', '');
//     cardBrand.value = _stripeGatewayService.detectCardBrand(cardNumber);
//     _updateCvvMask();
//   }
//
//   void _updateCvvMask() {
//     // American Express tem CVV de 4 dígitos
//     if (cardBrand.value == 'amex') {
//       cvvFormatter.updateMask(mask: '####');
//     } else {
//       cvvFormatter.updateMask(mask: '###');
//     }
//   }
//
//   // ===========================================
//   // GESTÃO DE CARTÕES
//   // ===========================================
//
//   Future<void> loadSavedCards() async {
//     try {
//       if (_authController.currentUser.value == null) {
//         Get.snackbar('Erro', 'Você precisa estar logado para acessar seus cartões');
//         return;
//       }
//
//       isLoading.value = true;
//       final userId = _authController.currentUser.value!.uid;
//
//       // Usar o novo serviço Stripe Gateway
//       final cards = await _stripeGatewayService.getUserSavedCards(userId);
//       savedCards.value = cards;
//
//       debugPrint('✅ ${cards.length} cartões carregados via Stripe Gateway');
//     } catch (e) {
//       debugPrint('Erro ao carregar cartões: $e');
//       Get.snackbar('Erro', 'Não foi possível carregar os cartões: $e');
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   // ===========================================
//   // ADICIONAR NOVO CARTÃO VIA STRIPE GATEWAY
//   // ===========================================
//
//   Future<bool> addNewCard() async {
//     if (!formKey.currentState!.validate()) {
//       Get.snackbar('Formulário Inválido', 'Por favor, corrija os erros no formulário');
//       return false;
//     }
//
//     try {
//       if (_authController.currentUser.value == null) {
//         Get.snackbar('Erro', 'Você precisa estar logado para adicionar um cartão');
//         return false;
//       }
//
//       isLoading.value = true;
//       final userId = _authController.currentUser.value!.uid;
//
//       // Verificar autenticação
//       final isAuthenticated = await _authController.ensureAuthenticated();
//       if (!isAuthenticated) {
//         Get.snackbar('Erro de Autenticação', 'Sua sessão expirou. Faça login novamente.');
//         return false;
//       }
//
//       // Preparar dados do formulário
//       final cardData = _prepareCardData();
//
//       debugPrint('🔄 Salvando cartão via Stripe Gateway...');
//
//       // Usar o novo serviço Stripe Gateway para salvar o cartão
//       final result = await _stripeGatewayService.saveUserCard(
//         userId: userId,
//         cardNumber: cardData['cardNumber'],
//         expiryMonth: cardData['expiryMonth'].toString(),
//         expiryYear: cardData['expiryYear'].toString(),
//         cvc: cardData['cvv'],
//         cardHolderName: cardData['cardHolder'],
//         cardType: cardType.value,
//         phone: cardData['phone'],
//         document: cardData['document'],
//         billingAddress: {
//           'country': 'BR',
//         },
//         setAsDefault: savedCards.isEmpty, // Primeiro cartão é padrão
//       );
//
//       if (result['success']) {
//         _clearForm();
//         await loadSavedCards();
//
//         Get.snackbar(
//           'Sucesso',
//           result['message'] ?? 'Cartão adicionado com sucesso',
//           backgroundColor: Colors.green,
//           colorText: Colors.white,
//           snackPosition: SnackPosition.BOTTOM,
//         );
//
//         debugPrint('✅ Cartão salvo via Stripe Gateway: ${result['card_id']}');
//         return true;
//       } else {
//         Get.snackbar(
//           'Erro',
//           result['error'] ?? 'Falha ao salvar cartão',
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//           snackPosition: SnackPosition.BOTTOM,
//         );
//         return false;
//       }
//
//     } catch (e) {
//       debugPrint('❌ Erro geral ao adicionar cartão: $e');
//       _handleGeneralError(e);
//       return false;
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   Map<String, dynamic> _prepareCardData() {
//     final expiryParts = expiryDateController.text.split('/');
//     return {
//       'cardNumber': cardNumberController.text.replaceAll(' ', ''),
//       'cardHolder': cardHolderController.text.trim(),
//       'expiryMonth': int.parse(expiryParts[0]),
//       'expiryYear': int.parse('20${expiryParts[1]}'),
//       'cvv': cvvController.text,
//       'document': documentController.text.replaceAll(RegExp(r'[.-]'), ''),
//       'phone': phoneController.text.replaceAll(RegExp(r'[() -]'), ''),
//     };
//   }
//
//   // ===========================================
//   // GERENCIAR CARTÕES EXISTENTES
//   // ===========================================
//
//   Future<bool> removeCard(String cardId) async {
//     try {
//       if (_authController.currentUser.value == null) {
//         Get.snackbar('Erro', 'Você precisa estar logado para remover um cartão');
//         return false;
//       }
//
//       isLoading.value = true;
//       final userId = _authController.currentUser.value!.uid;
//
//       // Usar o serviço Stripe Gateway para remover
//       final result = await _stripeGatewayService.removeUserCard(
//         userId: userId,
//         cardId: cardId,
//       );
//
//       if (result['success']) {
//         // Atualizar lista local
//         savedCards.removeWhere((card) => card['id'] == cardId);
//         savedCards.refresh();
//
//         Get.snackbar(
//           'Sucesso',
//           result['message'] ?? 'Cartão removido com sucesso',
//           backgroundColor: Colors.green,
//           colorText: Colors.white,
//           snackPosition: SnackPosition.BOTTOM,
//         );
//         return true;
//       } else {
//         Get.snackbar('Erro', result['error'] ?? 'Não foi possível remover o cartão');
//         return false;
//       }
//     } catch (e) {
//       Get.snackbar('Erro', 'Não foi possível remover o cartão: $e');
//       return false;
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   Future<bool> setDefaultCard(String cardId) async {
//     try {
//       if (_authController.currentUser.value == null) {
//         Get.snackbar('Erro', 'Você precisa estar logado');
//         return false;
//       }
//
//       isLoading.value = true;
//       final userId = _authController.currentUser.value!.uid;
//
//       // Usar o serviço Stripe Gateway
//       final result = await _stripeGatewayService.setDefaultCard(
//         userId: userId,
//         cardId: cardId,
//       );
//
//       if (result['success']) {
//         // Atualizar lista local
//         for (var card in savedCards) {
//           card['isDefault'] = card['id'] == cardId;
//         }
//         _sortCards();
//         savedCards.refresh();
//
//         Get.snackbar(
//           'Sucesso',
//           result['message'] ?? 'Cartão definido como padrão',
//           backgroundColor: Colors.green,
//           colorText: Colors.white,
//           snackPosition: SnackPosition.BOTTOM,
//         );
//         return true;
//       } else {
//         Get.snackbar('Erro', result['error'] ?? 'Não foi possível definir o cartão como padrão');
//         return false;
//       }
//     } catch (e) {
//       Get.snackbar('Erro', 'Não foi possível definir o cartão como padrão: $e');
//       return false;
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   void _sortCards() {
//     savedCards.sort((a, b) {
//       if (a['isDefault'] == true && b['isDefault'] != true) return -1;
//       if (b['isDefault'] == true && a['isDefault'] != true) return 1;
//       return 0;
//     });
//   }
//
//   // ===========================================
//   // MÉTODOS AUXILIARES
//   // ===========================================
//
//   void _clearForm() {
//     cardNumberController.clear();
//     cardHolderController.clear();
//     expiryDateController.clear();
//     cvvController.clear();
//     documentController.clear();
//     phoneController.clear();
//     cardBrand.value = '';
//     cardType.value = 'credit';
//     showBackView.value = false;
//   }
//
//   Map<String, dynamic>? getDefaultCard() {
//     return savedCards.firstWhereOrNull((card) => card['isDefault'] == true);
//   }
//
//   bool isCardExpired(Map<String, dynamic> card) {
//     try {
//       final expiryMonth = int.parse(card['expiryMonth'] ?? '12');
//       final expiryYear = int.parse(card['expiryYear'] ?? '2099');
//
//       final now = DateTime.now();
//       final cardExpiryDate = DateTime(expiryYear, expiryMonth + 1, 0);
//
//       return cardExpiryDate.isBefore(now);
//     } catch (e) {
//       return false;
//     }
//   }
//
//   // ===========================================
//   // VALIDAÇÃO DE FORMULÁRIO
//   // ===========================================
//
//   String? validateCardNumberField(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Digite o número do cartão';
//     }
//
//     final cardNumber = value.replaceAll(' ', '');
//     if (cardNumber.length < 16) {
//       return 'Número do cartão incompleto';
//     }
//
//     return null;
//   }
//
//   String? validateCardHolderField(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return 'Digite o nome do titular';
//     }
//
//     if (value.trim().length < 3) {
//       return 'Nome muito curto';
//     }
//
//     if (!value.trim().contains(' ')) {
//       return 'Digite nome e sobrenome';
//     }
//
//     return null;
//   }
//
//   String? validateExpiryDateField(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Digite a validade';
//     }
//
//     if (value.length < 5) {
//       return 'Formato inválido';
//     }
//
//     final parts = value.split('/');
//     if (parts.length != 2) {
//       return 'Formato inválido';
//     }
//
//     final month = int.tryParse(parts[0]);
//     final year = int.tryParse('20${parts[1]}');
//
//     if (month == null || year == null || month < 1 || month > 12) {
//       return 'Data inválida';
//     }
//
//     final now = DateTime.now();
//     final cardDate = DateTime(year, month);
//     if (cardDate.isBefore(DateTime(now.year, now.month))) {
//       return 'Cartão expirado';
//     }
//
//     return null;
//   }
//
//   String? validateCvvField(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Digite o CVV';
//     }
//
//     final minLength = cardBrand.value == 'amex' ? 4 : 3;
//     if (value.length < minLength) {
//       return 'CVV inválido';
//     }
//
//     return null;
//   }
//
//   String? validateDocumentField(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Digite o CPF';
//     }
//
//     if (!isValidCPF(value)) {
//       return 'CPF inválido';
//     }
//
//     return null;
//   }
//
//   String? validatePhoneField(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Digite o celular';
//     }
//
//     if (!isValidPhone(value)) {
//       return 'Número de celular inválido';
//     }
//
//     return null;
//   }
//
//   bool isValidCPF(String cpf) {
//     cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
//
//     if (cpf.length != 11) return false;
//
//     // Verificar se todos os dígitos são iguais
//     if (cpf.split('').every((digit) => digit == cpf[0])) return false;
//
//     // Calcular primeiro dígito verificador
//     int sum = 0;
//     for (int i = 0; i < 9; i++) {
//       sum += int.parse(cpf[i]) * (10 - i);
//     }
//     int remainder = sum % 11;
//     int firstDigit = remainder < 2 ? 0 : 11 - remainder;
//
//     if (int.parse(cpf[9]) != firstDigit) return false;
//
//     // Calcular segundo dígito verificador
//     sum = 0;
//     for (int i = 0; i < 10; i++) {
//       sum += int.parse(cpf[i]) * (11 - i);
//     }
//     remainder = sum % 11;
//     int secondDigit = remainder < 2 ? 0 : 11 - remainder;
//
//     return int.parse(cpf[10]) == secondDigit;
//   }
//
//   bool isValidPhone(String phone) {
//     phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
//     return phone.length >= 10 && phone.length <= 11;
//   }
//
//   // ===========================================
//   // TRATAMENTO DE ERROS
//   // ===========================================
//
//   void _handleGeneralError(dynamic error) {
//     String errorMessage = 'Não foi possível adicionar o cartão';
//
//     if (error.toString().contains('unauthenticated') ||
//         error.toString().contains('permission-denied')) {
//       errorMessage = 'Sua sessão expirou. Faça login novamente.';
//       Get.snackbar(
//         'Erro de Autenticação',
//         errorMessage,
//         backgroundColor: Colors.orange,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     } else if (error.toString().contains('network')) {
//       errorMessage = 'Erro de conexão. Verifique sua internet.';
//       Get.snackbar(
//         'Erro de Conexão',
//         errorMessage,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     } else {
//       Get.snackbar(
//         'Erro',
//         '$errorMessage: ${error.toString().split(': ').last}',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     }
//   }
//
//   // ===========================================
//   // MÉTODOS DE UTILIDADE
//   // ===========================================
//
//   void refreshCards() async {
//     await loadSavedCards();
//   }
//
//   int get cardCount => savedCards.length;
//
//   bool get hasCards => savedCards.isNotEmpty;
//
//   bool get hasDefaultCard => savedCards.any((card) => card['isDefault'] == true);
//
//   // ===========================================
//   // MÉTODOS DE TESTE E DIAGNÓSTICO
//   // ===========================================
//
//   /// Testar conexão com Stripe Gateway
//   Future<void> testStripeConnection() async {
//     try {
//       isLoading.value = true;
//
//       final result = await _stripeGatewayService.testConnection();
//
//       if (result['success']) {
//         Get.snackbar(
//           'Conexão OK',
//           'Stripe Gateway funcionando corretamente',
//           backgroundColor: Colors.green,
//           colorText: Colors.white,
//           snackPosition: SnackPosition.BOTTOM,
//         );
//       } else {
//         Get.snackbar(
//           'Erro de Conexão',
//           result['message'] ?? 'Falha na conexão com Stripe',
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//           snackPosition: SnackPosition.BOTTOM,
//         );
//       }
//     } catch (e) {
//       Get.snackbar(
//         'Erro',
//         'Erro ao testar conexão: $e',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   /// Obter informações da conta Stripe
//   Future<void> showStripeAccountInfo() async {
//     try {
//       final result = await _stripeGatewayService.getAccountInfo();
//
//       if (result['success']) {
//         final data = result['data'];
//         Get.dialog(
//           AlertDialog(
//             title: const Text('Informações da Conta Stripe'),
//             content: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text('ID: ${data['id']}'),
//                   Text('Nome: ${data['display_name'] ?? 'N/A'}'),
//                   Text('País: ${data['country'] ?? 'N/A'}'),
//                   Text('Moeda: ${data['default_currency'] ?? 'N/A'}'),
//                   Text('Pagamentos: ${data['charges_enabled'] ? 'Habilitado' : 'Desabilitado'}'),
//                   Text('Transferências: ${data['payouts_enabled'] ? 'Habilitado' : 'Desabilitado'}'),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Get.back(),
//                 child: const Text('Fechar'),
//               ),
//             ],
//           ),
//         );
//       }
//     } catch (e) {
//       Get.snackbar('Erro', 'Não foi possível obter informações da conta');
//     }
//   }
// }