import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/services/payment_service.dart';
import 'package:oraculum/services/stripe_payment_service.dart';

class PaymentController extends GetxController {
  final PaymentService _paymentService = Get.find<PaymentService>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthController _authController = Get.find<AuthController>();
  final StripePaymentService _stripeService = Get.find<StripePaymentService>();

  // Estados observáveis
  RxBool isLoading = false.obs;
  RxList<Map<String, dynamic>> paymentHistory = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> savedCards = <Map<String, dynamic>>[].obs;
  RxDouble userCredits = 0.0.obs;
  RxMap<String, bool> availablePaymentMethods = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initializePaymentMethods();

    if (_authController.isLoggedIn) {
      loadUserCredits();
      loadSavedCards();
    }

    // Observer para atualizar quando o usuário fizer login
    ever(_authController.currentUser, (_) {
      if (_authController.isLoggedIn) {
        loadUserCredits();
        loadSavedCards();
      } else {
        _clearUserData();
      }
    });
  }

  // ===========================================
  // INICIALIZAÇÃO
  // ===========================================

  Future<void> _initializePaymentMethods() async {
    try {
      final features = await _stripeService.checkAvailableFeatures();
      availablePaymentMethods.value = features;
    } catch (e) {
      debugPrint('Erro ao verificar métodos disponíveis: $e');
      // Definir padrões se houver erro
      availablePaymentMethods.value = {
        'card_payments': true,
        'pix': true,
      };
    }
  }

  void _clearUserData() {
    userCredits.value = 0.0;
    paymentHistory.clear();
    savedCards.clear();
  }

  // ===========================================
  // GERENCIAMENTO DE CRÉDITOS
  // ===========================================

  Future<void> loadUserCredits() async {
    try {
      if (_authController.currentUser.value == null) return;

      isLoading.value = true;
      final userId = _authController.currentUser.value!.uid;
      final userData = await _firebaseService.getUserData(userId);

      if (!userData.exists) {
        userCredits.value = 0.0;
        return;
      }

      final data = userData.data() as Map<String, dynamic>?;
      if (data == null) {
        userCredits.value = 0.0;
        return;
      }

      // Tratamento robusto do valor de créditos
      var credits = 0.0;
      if (data.containsKey('credits')) {
        if (data['credits'] is double) {
          credits = data['credits'] as double;
        } else if (data['credits'] is int) {
          credits = (data['credits'] as int).toDouble();
        } else {
          try {
            credits = double.parse(data['credits'].toString());
          } catch (e) {
            debugPrint('Erro ao converter créditos: $e');
            credits = 0.0;
          }
        }
      }

      userCredits.value = credits;
    } catch (e) {
      debugPrint('Erro ao carregar créditos: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível carregar os créditos',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================
  // PAGAMENTOS COM CARTÃO NOVO
  // ===========================================

  /// Processar pagamento com cartão novo usando tela nativa da SDK
  Future<String> processCardPayment({
    required double amount,
    required int bonus,
    required String description,
    required String serviceId,
    required String serviceType,
    bool saveCard = true,
  }) async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para realizar um pagamento');
        return '';
      }

      isLoading.value = true;

      final result = await _stripeService.processCardPayment(
        amount: amount,
        bonus: bonus,
        description: description,
        serviceId: serviceId,
        serviceType: serviceType,
        saveCard: saveCard,
      );

      if (result['success']) {
        await loadUserCredits();
        if (saveCard) {
          await loadSavedCards();
        }

        Get.snackbar(
          'Sucesso',
          'Pagamento de R\$ ${amount.toStringAsFixed(2)} realizado com sucesso!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        return result['transaction_id'] ?? result['payment_intent_id'];
      } else {
        Get.snackbar(
          'Erro no Pagamento',
          result['error'] ?? 'Falha no processamento',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }
    } catch (e) {
      debugPrint('Erro no pagamento com cartão: $e');
      Get.snackbar(
        'Erro',
        'Falha inesperada no pagamento',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return '';
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================
  // PAGAMENTOS COM CARTÃO SALVO
  // ===========================================

  /// Processar pagamento com cartão salvo
  Future<String> processPaymentWithSavedCard({
    required String paymentMethodId,
    required double amount,
    required int bonus,
    required String description,
    required String serviceId,
    required String serviceType,
  }) async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para realizar um pagamento');
        return '';
      }

      isLoading.value = true;

      final result = await _stripeService.processPaymentWithSavedCard(
        paymentMethodId: paymentMethodId,
        amount: amount,
        bonus: bonus,
        description: description,
        serviceId: serviceId,
        serviceType: serviceType,
      );

      if (result['success']) {
        await loadUserCredits();

        Get.snackbar(
          'Sucesso',
          'Pagamento de R\$ ${amount.toStringAsFixed(2)} realizado com sucesso!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        return result['transaction_id'] ?? result['payment_intent_id'];
      } else {
        Get.snackbar(
          'Erro no Pagamento',
          result['error'] ?? 'Falha no processamento',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }
    } catch (e) {
      debugPrint('Erro no pagamento com cartão salvo: $e');
      Get.snackbar(
        'Erro',
        'Falha inesperada no pagamento',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return '';
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================
  // APPLE PAY
  // ===========================================

  /// Processar pagamento com Apple Pay
  Future<String> processApplePayPayment({
    required double amount,
    required int bonus,
    required String description,
    required String serviceId,
    required String serviceType,
  }) async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para realizar um pagamento');
        return '';
      }

      // Verificar se Apple Pay está disponível
      if (!availablePaymentMethods['apple_pay']!) {
        Get.snackbar(
          'Indisponível',
          'Apple Pay não está disponível neste dispositivo',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }

      isLoading.value = true;

      final result = await _stripeService.processApplePayPayment(
        amount: amount,
        bonus: bonus,
        description: description,
        serviceId: serviceId,
        serviceType: serviceType,
      );

      if (result['success']) {
        await loadUserCredits();

        Get.snackbar(
          'Sucesso',
          'Pagamento Apple Pay de R\$ ${amount.toStringAsFixed(2)} realizado!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        return result['transaction_id'] ?? result['payment_intent_id'];
      } else {
        Get.snackbar(
          'Erro Apple Pay',
          result['error'] ?? 'Falha no Apple Pay',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }
    } catch (e) {
      debugPrint('Erro no Apple Pay: $e');
      Get.snackbar(
        'Erro',
        'Falha no Apple Pay',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return '';
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================
  // GOOGLE PAY
  // ===========================================

  /// Processar pagamento com Google Pay
  Future<String> processGooglePayPayment({
    required double amount,
    required int bonus,
    required String description,
    required String serviceId,
    required String serviceType,
  }) async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para realizar um pagamento');
        return '';
      }

      // Verificar se Google Pay está disponível
      if (!availablePaymentMethods['google_pay']!) {
        Get.snackbar(
          'Indisponível',
          'Google Pay não está disponível neste dispositivo',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }

      isLoading.value = true;

      final result = await _stripeService.processGooglePayPayment(
        amount: amount,
        bonus: bonus,
        description: description,
        serviceId: serviceId,
        serviceType: serviceType,
      );

      if (result['success']) {
        await loadUserCredits();

        Get.snackbar(
          'Sucesso',
          'Pagamento Google Pay de R\$ ${amount.toStringAsFixed(2)} realizado!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        return result['transaction_id'] ?? result['payment_intent_id'];
      } else {
        Get.snackbar(
          'Erro Google Pay',
          result['error'] ?? 'Falha no Google Pay',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }
    } catch (e) {
      debugPrint('Erro no Google Pay: $e');
      Get.snackbar(
        'Erro',
        'Falha no Google Pay',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return '';
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================
  // PIX
  // ===========================================

  /// Processar pagamento com PIX
  Future<Map<String, dynamic>> processPixPayment({
    required double amount,
    required String description,
    required String serviceId,
    required String serviceType,
  }) async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para realizar um pagamento');
        return {'success': false, 'error': 'Usuário não logado'};
      }

      isLoading.value = true;

      final result = await _stripeService.createPixPayment(
        amount: amount,
        description: description,
        serviceId: serviceId,
        serviceType: serviceType,
      );

      if (result['success']) {
        Get.snackbar(
          'PIX Gerado',
          'QR Code PIX criado! Complete o pagamento para receber os créditos.',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        return {
          'success': true,
          'transaction_id': result['transaction_id'],
          'payment_intent_id': result['payment_intent_id'],
          'pix_qr_code': result['pix_qr_code'],
        };
      } else {
        Get.snackbar(
          'Erro PIX',
          result['error'] ?? 'Falha ao gerar PIX',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return result;
      }
    } catch (e) {
      debugPrint('Erro no PIX: $e');
      Get.snackbar(
        'Erro',
        'Falha no PIX',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return {'success': false, 'error': 'Falha no PIX: $e'};
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================
  // GERENCIAMENTO DE CARTÕES SALVOS
  // ===========================================

  /// Carregar cartões salvos do usuário
  Future<void> loadSavedCards() async {
    try {
      if (_authController.currentUser.value == null) return;

      isLoading.value = true;
      final userId = _authController.currentUser.value!.uid;

      final cards = await _stripeService.getSavedCards(userId);
      savedCards.value = cards;
    } catch (e) {
      debugPrint('Erro ao carregar cartões salvos: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Adicionar novo cartão sem cobrança
  Future<bool> addNewCard() async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para adicionar um cartão');
        return false;
      }

      isLoading.value = true;

      final result = await _stripeService.setupCardForFutureUse();

      if (result['success']) {
        await loadSavedCards();

        Get.snackbar(
          'Sucesso',
          'Cartão adicionado com sucesso!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      } else {
        Get.snackbar(
          'Erro',
          result['error'] ?? 'Falha ao adicionar cartão',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      debugPrint('Erro ao adicionar cartão: $e');
      Get.snackbar(
        'Erro',
        'Falha ao adicionar cartão',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Remover cartão salvo
  Future<bool> removeCard(String cardId) async {
    try {
      if (_authController.currentUser.value == null) return false;

      isLoading.value = true;
      final userId = _authController.currentUser.value!.uid;

      final success = await _stripeService.removeCard(userId, cardId);

      if (success) {
        await loadSavedCards();

        Get.snackbar(
          'Sucesso',
          'Cartão removido com sucesso',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      } else {
        Get.snackbar(
          'Erro',
          'Não foi possível remover o cartão',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      debugPrint('Erro ao remover cartão: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================
  // HISTÓRICO DE PAGAMENTOS
  // ===========================================

  Future<void> loadPaymentHistory() async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar(
          'Erro',
          'Você precisa estar logado para ver seu histórico de pagamentos',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      isLoading.value = true;
      final userId = _authController.currentUser.value!.uid;

      final payments = await _paymentService.getUserPaymentHistory(userId);
      paymentHistory.value = payments;
    } catch (e) {
      debugPrint('Erro ao carregar histórico de pagamentos: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível carregar o histórico de pagamentos',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================
  // MÉTODO GENÉRICO DE PAGAMENTO
  // ===========================================

  /// Método genérico para processamento de pagamento
  Future<String> processPayment({
    required BuildContext context,
    required String description,
    required double amount,
    required int bonus,
    required String serviceId,
    required String serviceType,
    required String paymentMethod,
    String? specificCardId,
  }) async {
    try {
      String paymentId = '';

      // Direcionar para o método de pagamento apropriado
      switch (paymentMethod.toLowerCase()) {
        case 'card':
        case 'cartão de crédito':
        case 'credit_card':
          if (specificCardId != null) {
            paymentId = await processPaymentWithSavedCard(
              paymentMethodId: specificCardId,
              amount: amount,
              bonus: bonus,
              description: description,
              serviceId: serviceId,
              serviceType: serviceType,
            );
          } else {
            paymentId = await processCardPayment(
              amount: amount,
              bonus: bonus,
              description: description,
              serviceId: serviceId,
              serviceType: serviceType,
              saveCard: true,
            );
          }
          break;

        case 'apple_pay':
        case 'apple pay':
          paymentId = await processApplePayPayment(
            amount: amount,
            bonus: bonus,
            description: description,
            serviceId: serviceId,
            serviceType: serviceType,
          );
          break;

        case 'google_pay':
        case 'google pay':
          paymentId = await processGooglePayPayment(
            amount: amount,
            bonus: bonus,
            description: description,
            serviceId: serviceId,
            serviceType: serviceType,
          );
          break;

        case 'pix':
          final pixResult = await processPixPayment(
            amount: amount,
            description: description,
            serviceId: serviceId,
            serviceType: serviceType,
          );
          paymentId = pixResult['success'] ? pixResult['transaction_id'] ?? '' : '';
          break;

        case 'credits':
        case 'créditos':
          paymentId = await processPaymentWithCredits(
            _authController.currentUser.value!.uid,
            amount,
            description,
            serviceId,
            serviceType,
          );
          break;

        default:
          throw Exception('Método de pagamento não suportado: $paymentMethod');
      }

      return paymentId;
    } catch (e) {
      debugPrint('Erro ao processar pagamento: $e');
      Get.snackbar(
        'Erro',
        'Falha ao processar pagamento: ${e.toString().split(': ').last}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return '';
    }
  }

  // ===========================================
  // PAGAMENTO COM CRÉDITOS
  // ===========================================

  Future<bool> checkUserCredits(String userId, double requiredAmount) async {
    try {
      return await _paymentService.checkUserCredits(userId, requiredAmount);
    } catch (e) {
      debugPrint('Erro ao verificar créditos: $e');
      return false;
    }
  }

  Future<String> processPaymentWithCredits(
      String userId,
      double amount,
      String description,
      String serviceId,
      String serviceType,
      ) async {
    try {
      isLoading.value = true;

      final paymentId = await _paymentService.processPaymentWithCredits(
        userId,
        amount,
        description,
        serviceId,
        serviceType,
      );

      if (paymentId.isNotEmpty) {
        await loadUserCredits();

        Get.snackbar(
          'Sucesso',
          'Pagamento com créditos realizado com sucesso',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        return paymentId;
      } else {
        Get.snackbar(
          'Erro',
          'Falha no processamento com créditos',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }
    } catch (e) {
      debugPrint('Erro ao processar pagamento com créditos: $e');
      Get.snackbar(
        'Erro',
        'Falha ao processar o pagamento com créditos: ${e.toString().split(': ').last}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return '';
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================
  // ANÁLISES E RELATÓRIOS
  // ===========================================

  /// Obter estatísticas de pagamento
  Future<Map<String, dynamic>> getPaymentStats() async {
    try {
      if (_authController.currentUser.value == null) return {};

      final userId = _authController.currentUser.value!.uid;
      return await _stripeService.getPaymentStats(userId);
    } catch (e) {
      debugPrint('Erro ao obter estatísticas: $e');
      return {};
    }
  }

  /// Gerar relatório de transações
  Future<Map<String, dynamic>> generateTransactionReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (_authController.currentUser.value == null) return {};

      final userId = _authController.currentUser.value!.uid;
      return await _stripeService.generateTransactionReport(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('Erro ao gerar relatório: $e');
      return {};
    }
  }

  // ===========================================
  // CONFIGURAÇÕES E PREFERÊNCIAS
  // ===========================================

  /// Obter configurações de pagamento
  Future<Map<String, dynamic>> getPaymentSettings() async {
    try {
      if (_authController.currentUser.value == null) return {};

      final userId = _authController.currentUser.value!.uid;
      return await _stripeService.getUserPaymentSettings(userId);
    } catch (e) {
      debugPrint('Erro ao obter configurações: $e');
      return {};
    }
  }

  /// Atualizar configurações de pagamento
  Future<bool> updatePaymentSettings(Map<String, dynamic> settings) async {
    try {
      if (_authController.currentUser.value == null) return false;

      final userId = _authController.currentUser.value!.uid;
      return await _stripeService.updateUserPaymentSettings(userId, settings);
    } catch (e) {
      debugPrint('Erro ao atualizar configurações: $e');
      return false;
    }
  }

  // ===========================================
  // NOTIFICAÇÕES E ALERTAS
  // ===========================================

  /// Verificar cartões próximos do vencimento
  Future<List<Map<String, dynamic>>> checkExpiringCards() async {
    try {
      if (_authController.currentUser.value == null) return [];

      final userId = _authController.currentUser.value!.uid;
      return await _stripeService.checkExpiringCards(userId);
    } catch (e) {
      debugPrint('Erro ao verificar cartões expirando: $e');
      return [];
    }
  }

  /// Processar webhook do Stripe
  Future<void> processStripeWebhook(Map<String, dynamic> event) async {
    try {
      await _stripeService.processWebhook(event);

      // Atualizar dados locais se necessário
      if (_authController.isLoggedIn) {
        final eventType = event['type'];
        if (eventType == 'payment_intent.succeeded' ||
            eventType == 'invoice.payment_succeeded') {
          await loadUserCredits();
          await loadPaymentHistory();
        }
      }
    } catch (e) {
      debugPrint('Erro ao processar webhook: $e');
    }
  }

  // ===========================================
  // MÉTODOS DE UTILIDADE
  // ===========================================

  /// Verificar se um método de pagamento está disponível
  bool isPaymentMethodAvailable(String method) {
    return availablePaymentMethods[method] ?? false;
  }

  /// Obter lista de métodos de pagamento disponíveis
  List<Map<String, dynamic>> getAvailablePaymentMethods() {
    final methods = <Map<String, dynamic>>[];

    if (availablePaymentMethods['card_payments'] == true) {
      methods.add({
        'id': 'card',
        'name': 'Cartão de Crédito/Débito',
        'icon': Icons.credit_card,
        'description': 'Pague com seu cartão',
        'available': true,
      });
    }

    if (availablePaymentMethods['pix'] == true) {
      methods.add({
        'id': 'pix',
        'name': 'PIX',
        'icon': Icons.qr_code,
        'description': 'Pagamento instantâneo',
        'available': true,
      });
    }

    return methods;
  }

  /// Testar conectividade com Stripe
  Future<bool> testStripeConnection() async {
    try {
      return await _stripeService.testConnection();
    } catch (e) {
      debugPrint('Erro ao testar conexão: $e');
      return false;
    }
  }

  /// Limpar dados de teste
  Future<void> clearTestData() async {
    try {
      if (_authController.currentUser.value == null) return;

      final userId = _authController.currentUser.value!.uid;
      await _stripeService.clearTestData(userId);

      // Recarregar dados
      await loadUserCredits();
      await loadSavedCards();
      await loadPaymentHistory();

      Get.snackbar(
        'Sucesso',
        'Dados de teste limpos',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Erro ao limpar dados de teste: $e');
    }
  }

  // ===========================================
  // GETTERS DE CONVENIÊNCIA
  // ===========================================

  bool get hasCards => savedCards.isNotEmpty;
  bool get hasCredits => userCredits.value > 0;
  bool get canUseApplePay => availablePaymentMethods['apple_pay'] == true;
  bool get canUseGooglePay => availablePaymentMethods['google_pay'] == true;
  bool get canUsePix => availablePaymentMethods['pix'] == true;
  bool get canSaveCards => availablePaymentMethods['save_cards'] == true;

  Map<String, dynamic>? get defaultCard {
    try {
      return savedCards.firstWhere((card) => card['isDefault'] == true);
    } catch (e) {
      return null;
    }
  }

  int get totalTransactions => paymentHistory.length;

  double get totalSpent {
    return paymentHistory.fold(0.0, (sum, payment) {
      final amount = payment['amount'] as num? ?? 0;
      return sum + amount.toDouble();
    });
  }
}