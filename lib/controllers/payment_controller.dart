import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/services/stripe_payment_service.dart';
import 'package:oraculum/services/payment_service.dart';

class PaymentController extends GetxController {
  final PaymentService _paymentService = Get.find<PaymentService>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthController _authController = Get.find<AuthController>();

  // Serviço Stripe
  late StripePaymentService _stripePaymentService;

  RxBool isLoading = false.obs;
  RxList<Map<String, dynamic>> paymentHistory = <Map<String, dynamic>>[].obs;
  RxDouble userCredits = 0.0.obs;

  @override
  void onInit() {
    super.onInit();

    _stripePaymentService = Get.find<StripePaymentService>();

    if (_authController.isLoggedIn) {
      loadUserCredits();
    }

    // Observer para atualizar quando o usuário fizer login
    ever(_authController.currentUser, (_) {
      if (_authController.isLoggedIn) {
        loadUserCredits();
      }
    });
  }

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
          // Tentar converter para double se for outro tipo
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
      update();
    }
  }

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

      // Usando o método do PaymentService
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
      update();
    }
  }

  // Método genérico para processamento de pagamento
  Future<String> processPayment({
    required BuildContext context,
    required String description,
    required double amount,
    required String serviceId,
    required String serviceType,
    required String paymentMethod,
  }) async {
    try {
      isLoading.value = true;

      String paymentId = '';

      // Direcionar para o método de pagamento apropriado
      switch (paymentMethod.toLowerCase()) {
        case 'google pay':
          paymentId = await processPaymentWithGooglePay(
            context: context,
            description: description,
            amount: amount,
            serviceId: serviceId,
            serviceType: serviceType,
          );
          break;

        case 'apple pay':
          paymentId = await processPaymentWithApplePay(
            context: context,
            description: description,
            amount: amount,
            serviceId: serviceId,
            serviceType: serviceType,
          );
          break;

        case 'cartão de crédito':
          paymentId = await processPaymentWithCreditCard(
            description: description,
            amount: amount,
            serviceId: serviceId,
            serviceType: serviceType,
          );
          break;

        case 'pix':
          paymentId = await processPaymentWithPix(
            description: description,
            amount: amount,
            serviceId: serviceId,
            serviceType: serviceType,
          );
          break;

        default:
          throw Exception('Método de pagamento não suportado');
      }

      if (paymentId.isEmpty) {
        throw Exception('Falha ao processar o pagamento');
      }

      await loadUserCredits();
      return paymentId;
    } catch (e) {
      debugPrint('Erro ao processar pagamento: $e');
      throw Exception('Falha ao processar pagamento: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Salvar transação no Firestore
  Future<String> _saveTransactionRecord({
    required String userId,
    required double amount,
    required String description,
    required String serviceId,
    required String serviceType,
    required String paymentMethod,
    required String status,
    String? stripePaymentIntentId,
    String? cardLastFourDigits,
    String? cardBrand,
    String? errorDetails,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final transactionData = {
        'userId': userId,
        'amount': amount,
        'description': description,
        'serviceId': serviceId,
        'serviceType': serviceType,
        'paymentMethod': paymentMethod,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
        if (stripePaymentIntentId != null) 'stripePaymentIntentId': stripePaymentIntentId,
        if (cardLastFourDigits != null) 'cardLastFourDigits': cardLastFourDigits,
        if (cardBrand != null) 'cardBrand': cardBrand,
        if (errorDetails != null) 'errorDetails': errorDetails,
        if (additionalData != null) ...additionalData,
      };

      final docRef = await _firebaseService.firestore
          .collection('payments')
          .add(transactionData);

      debugPrint('✅ Transação salva: ${docRef.id} - Status: $status');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Erro ao salvar transação: $e');
      rethrow;
    }
  }

  // Buscar cartão padrão do usuário
  Future<Map<String, dynamic>?> _getDefaultCard(String userId) async {
    try {
      final cardsSnapshot = await _firebaseService.firestore
          .collection('credit_cards')
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (cardsSnapshot.docs.isNotEmpty) {
        final cardData = cardsSnapshot.docs.first.data();
        return {
          'id': cardsSnapshot.docs.first.id,
          ...cardData,
        };
      }

      // Se não há cartão padrão, pegar o primeiro disponível
      final allCardsSnapshot = await _firebaseService.firestore
          .collection('credit_cards')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (allCardsSnapshot.docs.isNotEmpty) {
        final cardData = allCardsSnapshot.docs.first.data();
        return {
          'id': allCardsSnapshot.docs.first.id,
          ...cardData,
        };
      }

      return null;
    } catch (e) {
      debugPrint('Erro ao buscar cartão padrão: $e');
      return null;
    }
  }

  // Buscar cartão específico
  Future<Map<String, dynamic>?> _getCard(String userId, String cardId) async {
    try {
      final cardDoc = await _firebaseService.firestore
          .collection('credit_cards')
          .doc(cardId)
          .get();

      if (cardDoc.exists && cardDoc.data()?['userId'] == userId) {
        return {
          'id': cardDoc.id,
          ...cardDoc.data()!,
        };
      }

      return null;
    } catch (e) {
      debugPrint('Erro ao buscar cartão: $e');
      return null;
    }
  }

  Future<String> processPaymentWithGooglePay({
    required BuildContext context,
    required String description,
    required double amount,
    required String serviceId,
    required String serviceType,
  }) async {
    try {
      isLoading.value = true;

      if (_authController.currentUser.value == null) {
        Get.snackbar(
          'Erro',
          'Você precisa estar logado para realizar um pagamento',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }

      final userId = _authController.currentUser.value!.uid;

      // Salvar transação como pendente
      final transactionId = await _saveTransactionRecord(
        userId: userId,
        amount: amount,
        description: description,
        serviceId: serviceId,
        serviceType: serviceType,
        paymentMethod: 'Google Pay',
        status: 'pending',
      );

      // Usar PaymentService existente para Google Pay
      final paymentId = await _paymentService.payWithGooglePay(
        amount: amount,
        userId: userId,
        serviceId: serviceId,
        serviceType: serviceType,
        description: description,
        context: context,
      );

      if (paymentId != null) {
        // Atualizar transação como aprovada
        await _firebaseService.firestore
            .collection('payments')
            .doc(transactionId)
            .update({
          'status': 'approved',
          'externalPaymentId': paymentId,
          'completedAt': FieldValue.serverTimestamp(),
        });

        await loadUserCredits();

        Get.snackbar(
          'Sucesso',
          'Pagamento aprovado! Seus créditos foram atualizados',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return transactionId;
      } else {
        // Atualizar transação como falha
        await _firebaseService.firestore
            .collection('payments')
            .doc(transactionId)
            .update({
          'status': 'failed',
          'errorDetails': 'Pagamento não foi aprovado pelo Google Pay',
          'failedAt': FieldValue.serverTimestamp(),
        });

        Get.snackbar(
          'Erro',
          'O pagamento não foi aprovado',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }
    } catch (e) {
      debugPrint('Erro ao processar pagamento com Google Pay: $e');
      Get.snackbar(
        'Erro',
        'Falha ao processar o pagamento: ${e.toString().split(': ').last}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return '';
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<String> processPaymentWithApplePay({
    required BuildContext context,
    required String description,
    required double amount,
    required String serviceId,
    required String serviceType,
  }) async {
    try {
      isLoading.value = true;

      if (_authController.currentUser.value == null) {
        Get.snackbar(
          'Erro',
          'Você precisa estar logado para realizar um pagamento',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }

      final userId = _authController.currentUser.value!.uid;

      // Salvar transação como pendente
      final transactionId = await _saveTransactionRecord(
        userId: userId,
        amount: amount,
        description: description,
        serviceId: serviceId,
        serviceType: serviceType,
        paymentMethod: 'Apple Pay',
        status: 'pending',
      );

      // Usar PaymentService existente para Apple Pay
      final paymentId = await _paymentService.payWithApplePay(
        amount: amount,
        userId: userId,
        serviceId: serviceId,
        serviceType: serviceType,
        description: description,
        context: context,
      );

      if (paymentId != null) {
        // Atualizar transação como aprovada
        await _firebaseService.firestore
            .collection('payments')
            .doc(transactionId)
            .update({
          'status': 'approved',
          'externalPaymentId': paymentId,
          'completedAt': FieldValue.serverTimestamp(),
        });

        await loadUserCredits();

        Get.snackbar(
          'Sucesso',
          'Pagamento aprovado! Seus créditos foram atualizados',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return transactionId;
      } else {
        // Atualizar transação como falha
        await _firebaseService.firestore
            .collection('payments')
            .doc(transactionId)
            .update({
          'status': 'failed',
          'errorDetails': 'Pagamento não foi aprovado pelo Apple Pay',
          'failedAt': FieldValue.serverTimestamp(),
        });

        Get.snackbar(
          'Erro',
          'O pagamento não foi aprovado',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }
    } catch (e) {
      debugPrint('Erro ao processar pagamento com Apple Pay: $e');
      Get.snackbar(
        'Erro',
        'Falha ao processar o pagamento: ${e.toString().split(': ').last}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return '';
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // MÉTODO ATUALIZADO: Processamento de pagamento com PIX via Stripe
  Future<String> processPaymentWithPix({
    required String description,
    required double amount,
    required String serviceId,
    required String serviceType,
  }) async {
    try {
      isLoading.value = true;

      if (_authController.currentUser.value == null) {
        Get.snackbar(
          'Erro',
          'Você precisa estar logado para realizar um pagamento',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }

      final userId = _authController.currentUser.value!.uid;

      // Salvar transação como pendente
      final transactionId = await _saveTransactionRecord(
        userId: userId,
        amount: amount,
        description: description,
        serviceId: serviceId,
        serviceType: serviceType,
        paymentMethod: 'PIX',
        status: 'pending',
      );

      // Usar Stripe para criar pagamento PIX
      final pixResponse = await _stripePaymentService.createPixPayment(
        amount: amount,
        description: description,
        serviceId: serviceId,
        serviceType: serviceType,
      );

      if (pixResponse['success']) {
        // Atualizar transação com dados do PIX
        await _firebaseService.firestore
            .collection('payments')
            .doc(transactionId)
            .update({
          'stripePaymentIntentId': pixResponse['stripe_payment_intent_id'],
          'additionalData': {
            'pixQrCode': pixResponse['pix_qr_code'],
            'createdAt': DateTime.now().toIso8601String(),
          },
        });

        Get.snackbar(
          'PIX Gerado',
          'QR Code PIX criado com sucesso! Complete o pagamento para receber os créditos.',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        return transactionId;
      } else {
        // Atualizar transação como falha
        await _firebaseService.firestore
            .collection('payments')
            .doc(transactionId)
            .update({
          'status': 'failed',
          'errorDetails': pixResponse['error'],
          'failedAt': FieldValue.serverTimestamp(),
        });

        Get.snackbar(
          'Erro',
          'Falha ao gerar PIX: ${pixResponse['error']}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }
    } catch (e) {
      debugPrint('Erro ao processar pagamento com Pix: $e');
      Get.snackbar(
        'Erro',
        'Falha ao processar o pagamento: ${e.toString().split(': ').last}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return '';
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // MÉTODO PRINCIPAL: Processamento de pagamento com cartão cadastrado
  Future<String> processPaymentWithCreditCard({
    required String description,
    required double amount,
    required String serviceId,
    required String serviceType,
    String? specificCardId,
  }) async {
    try {
      isLoading.value = true;

      if (_authController.currentUser.value == null) {
        Get.snackbar(
          'Erro',
          'Você precisa estar logado para realizar um pagamento',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }

      final userId = _authController.currentUser.value!.uid;

      // Buscar cartão (específico ou padrão)
      Map<String, dynamic>? cardData;
      if (specificCardId != null) {
        cardData = await _getCard(userId, specificCardId);
      } else {
        cardData = await _getDefaultCard(userId);
      }

      if (cardData == null) {
        Get.snackbar(
          'Erro',
          'Nenhum cartão encontrado para realizar o pagamento. Adicione um cartão primeiro.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }

      // Verificar se o cartão está expirado
      if (_isCardExpired(cardData)) {
        Get.snackbar(
          'Erro',
          'O cartão selecionado está expirado. Adicione um novo cartão.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }

      debugPrint('💳 Processando pagamento com cartão: **** ${cardData['lastFourDigits']}');

      // Salvar transação como pendente
      final transactionId = await _saveTransactionRecord(
        userId: userId,
        amount: amount,
        description: description,
        serviceId: serviceId,
        serviceType: serviceType,
        paymentMethod: 'Cartão de Crédito',
        status: 'pending',
        cardLastFourDigits: cardData['lastFourDigits'],
        cardBrand: cardData['brandType'],
        additionalData: {
          'cardId': cardData['id'],
          'cardHolderName': cardData['cardHolderName'],
        },
      );

      try {
        // Buscar dados do usuário para o Stripe
        final userData = await _firebaseService.getUserData(userId);
        final userDoc = userData.data() as Map<String, dynamic>?;

        if (userDoc == null) {
          throw Exception('Dados do usuário não encontrados');
        }

        // Verificar se temos o customer ID do Stripe
        String? customerId = userDoc['stripeCustomerId'];
        if (customerId == null) {
          throw Exception('Customer ID do Stripe não encontrado. Recadastre o cartão.');
        }

        debugPrint('💳 Processando pagamento para customer: $customerId');

        // Usar o método do StripePaymentService para processar pagamento com cartão salvo
        final paymentResponse = await _stripePaymentService.processCardPaymentWithSavedCard(
          amount: amount,
          customerId: customerId,
          description: description,
          serviceId: serviceId,
          serviceType: serviceType,
          metadata: {
            'user_id': userId,
            'transaction_id': transactionId,
            'card_last_four': cardData['lastFourDigits'],
          },
        );

        if (paymentResponse['success']) {
          // Pagamento bem-sucedido
          await _firebaseService.firestore
              .collection('payments')
              .doc(transactionId)
              .update({
            'status': 'approved',
            'stripePaymentIntentId': paymentResponse['payment_intent_id'],
            'completedAt': FieldValue.serverTimestamp(),
            'additionalData': {
              'clientSecret': paymentResponse['client_secret'],
              'paymentMethodId': paymentResponse['payment_method_id'],
              'stripeStatus': paymentResponse['status'],
              'processedAt': DateTime.now().toIso8601String(),
            },
          });

          // Adicionar créditos ao usuário
          final creditsAdded = await _paymentService.updateUserCredits(userId, amount);
          if (!creditsAdded) {
            debugPrint('⚠️ Falha ao adicionar créditos, mas pagamento foi processado');
          }

          await loadUserCredits();

          Get.snackbar(
            'Sucesso',
            'Pagamento de R\$ ${amount.toStringAsFixed(2)} realizado com sucesso!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );

          debugPrint('✅ Pagamento processado com sucesso: $transactionId');
          return transactionId;
        } else if (paymentResponse['requires_action'] == true) {
          // Requer ação adicional (3D Secure)
          await _firebaseService.firestore
              .collection('payments')
              .doc(transactionId)
              .update({
            'status': 'requires_action',
            'stripePaymentIntentId': paymentResponse['payment_intent_id'] ?? '',
            'additionalData': {
              'clientSecret': paymentResponse['client_secret'],
              'requiresAction': true,
              'processedAt': DateTime.now().toIso8601String(),
            },
          });

          Get.snackbar(
            'Ação Necessária',
            'Seu cartão requer autenticação adicional. Use o método interativo para completar o pagamento.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );

          return '';
        } else {
          // Pagamento falhou
          throw Exception(paymentResponse['error']);
        }

      } catch (stripeError) {
        debugPrint('❌ Erro no processamento Stripe: $stripeError');

        // Atualizar transação como falha
        await _firebaseService.firestore
            .collection('payments')
            .doc(transactionId)
            .update({
          'status': 'failed',
          'errorDetails': stripeError.toString(),
          'failedAt': FieldValue.serverTimestamp(),
        });

        Get.snackbar(
          'Erro no Pagamento',
          'Falha no processamento: ${stripeError.toString().split(': ').last}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        return '';
      }

    } catch (e) {
      debugPrint('❌ Erro geral no pagamento com cartão: $e');
      Get.snackbar(
        'Erro',
        'Falha ao processar o pagamento: ${e.toString().split(': ').last}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return '';
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Verificar se o cartão está expirado
  bool _isCardExpired(Map<String, dynamic> cardData) {
    try {
      final expirationDate = cardData['expirationDate'] as String?;
      if (expirationDate == null) return false;

      final parts = expirationDate.split('/');
      if (parts.length != 2) return false;

      final month = int.parse(parts[0]);
      final year = int.parse(parts[1].length == 2 ? '20${parts[1]}' : parts[1]);

      final now = DateTime.now();
      final cardExpiryDate = DateTime(year, month + 1, 0); // Último dia do mês

      return cardExpiryDate.isBefore(now);
    } catch (e) {
      debugPrint('Erro ao verificar expiração do cartão: $e');
      return false; // Em caso de erro, assumir que não está expirado
    }
  }

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

      // Salvar transação como pendente
      final transactionId = await _saveTransactionRecord(
        userId: userId,
        amount: amount,
        description: description,
        serviceId: serviceId,
        serviceType: serviceType,
        paymentMethod: 'Créditos',
        status: 'pending',
      );

      // Usar o método do PaymentService
      final paymentId = await _paymentService.processPaymentWithCredits(
        userId,
        amount,
        description,
        serviceId,
        serviceType,
      );

      if (paymentId.isNotEmpty) {
        // Atualizar transação como aprovada
        await _firebaseService.firestore
            .collection('payments')
            .doc(transactionId)
            .update({
          'status': 'approved',
          'externalPaymentId': paymentId,
          'completedAt': FieldValue.serverTimestamp(),
        });

        await loadUserCredits();

        Get.snackbar(
          'Sucesso',
          'Pagamento com créditos realizado com sucesso',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        return transactionId;
      } else {
        // Atualizar transação como falha
        await _firebaseService.firestore
            .collection('payments')
            .doc(transactionId)
            .update({
          'status': 'failed',
          'errorDetails': 'Falha no processamento com créditos',
          'failedAt': FieldValue.serverTimestamp(),
        });

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
      update();
    }
  }

  Future<bool> addCredits(double amount) async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar(
          'Erro',
          'Você precisa estar logado para adicionar créditos',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Usar o método de pagamento com cartão cadastrado
      final result = await processPaymentWithCreditCard(
        description: 'Compra de créditos - R\$ ${amount.toStringAsFixed(2)}',
        amount: amount,
        serviceId: 'credits_${DateTime.now().millisecondsSinceEpoch}',
        serviceType: 'credit_purchase',
      );

      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Erro ao adicionar créditos: $e');
      Get.snackbar(
        'Erro',
        'Falha ao adicionar créditos: ${e.toString().split(': ').last}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<bool> removeCredits(double amount) async {
    // Garantir que o valor seja positivo antes de remover
    amount = amount.abs();
    return await _paymentService.updateUserCredits(_authController.currentUser.value!.uid, -amount);
  }

  // MÉTODOS AUXILIARES PARA GERENCIAMENTO DE TRANSAÇÕES

  /// Buscar transação por ID
  Future<Map<String, dynamic>?> getTransactionById(String transactionId) async {
    try {
      final doc = await _firebaseService.firestore
          .collection('payments')
          .doc(transactionId)
          .get();

      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao buscar transação: $e');
      return null;
    }
  }

  /// Atualizar status de uma transação
  Future<bool> updateTransactionStatus(String transactionId, String newStatus, {String? errorDetails}) async {
    try {
      final updateData = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (errorDetails != null) {
        updateData['errorDetails'] = errorDetails;
      }

      if (newStatus == 'approved') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'failed') {
        updateData['failedAt'] = FieldValue.serverTimestamp();
      }

      await _firebaseService.firestore
          .collection('payments')
          .doc(transactionId)
          .update(updateData);

      debugPrint('✅ Status da transação $transactionId atualizado para: $newStatus');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao atualizar status da transação: $e');
      return false;
    }
  }

  /// Buscar transações por status
  Future<List<Map<String, dynamic>>> getTransactionsByStatus(String status) async {
    try {
      if (_authController.currentUser.value == null) return [];

      final userId = _authController.currentUser.value!.uid;
      final snapshot = await _firebaseService.firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: status)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          // Converter Timestamp para DateTime se necessário
          'timestamp': data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Erro ao buscar transações por status: $e');
      return [];
    }
  }

  /// Buscar transações pendentes
  Future<List<Map<String, dynamic>>> getPendingTransactions() async {
    return await getTransactionsByStatus('pending');
  }

  /// Buscar transações aprovadas
  Future<List<Map<String, dynamic>>> getApprovedTransactions() async {
    return await getTransactionsByStatus('approved');
  }

  /// Buscar transações falhadas
  Future<List<Map<String, dynamic>>> getFailedTransactions() async {
    return await getTransactionsByStatus('failed');
  }

  /// Estatísticas de transações do usuário
  Future<Map<String, dynamic>> getTransactionStats() async {
    try {
      if (_authController.currentUser.value == null) {
        return {
          'total': 0,
          'approved': 0,
          'pending': 0,
          'failed': 0,
          'totalAmount': 0.0,
          'approvedAmount': 0.0,
        };
      }

      final userId = _authController.currentUser.value!.uid;
      final snapshot = await _firebaseService.firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .get();

      int total = 0;
      int approved = 0;
      int pending = 0;
      int failed = 0;
      double totalAmount = 0.0;
      double approvedAmount = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

        total++;
        totalAmount += amount;

        switch (status) {
          case 'approved':
            approved++;
            approvedAmount += amount;
            break;
          case 'pending':
            pending++;
            break;
          case 'failed':
            failed++;
            break;
        }
      }

      return {
        'total': total,
        'approved': approved,
        'pending': pending,
        'failed': failed,
        'totalAmount': totalAmount,
        'approvedAmount': approvedAmount,
      };
    } catch (e) {
      debugPrint('Erro ao calcular estatísticas: $e');
      return {
        'total': 0,
        'approved': 0,
        'pending': 0,
        'failed': 0,
        'totalAmount': 0.0,
        'approvedAmount': 0.0,
      };
    }
  }

  /// Reprocessar transação falhada
  Future<String> retryFailedTransaction(String transactionId) async {
    try {
      final transaction = await getTransactionById(transactionId);
      if (transaction == null) {
        Get.snackbar('Erro', 'Transação não encontrada');
        return '';
      }

      if (transaction['status'] != 'failed') {
        Get.snackbar('Erro', 'Apenas transações falhadas podem ser reprocessadas');
        return '';
      }

      // Reprocessar usando os dados originais
      return await processPaymentWithCreditCard(
        description: transaction['description'],
        amount: (transaction['amount'] as num).toDouble(),
        serviceId: transaction['serviceId'],
        serviceType: transaction['serviceType'],
      );
    } catch (e) {
      debugPrint('Erro ao reprocessar transação: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível reprocessar a transação: ${e.toString().split(': ').last}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return '';
    }
  }

  /// Cancelar transação pendente
  Future<bool> cancelPendingTransaction(String transactionId) async {
    try {
      final transaction = await getTransactionById(transactionId);
      if (transaction == null) {
        Get.snackbar('Erro', 'Transação não encontrada');
        return false;
      }

      if (transaction['status'] != 'pending') {
        Get.snackbar('Erro', 'Apenas transações pendentes podem ser canceladas');
        return false;
      }

      // Atualizar status para cancelado
      await _firebaseService.firestore
          .collection('payments')
          .doc(transactionId)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Sucesso',
        'Transação cancelada com sucesso',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      debugPrint('Erro ao cancelar transação: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível cancelar a transação: ${e.toString().split(': ').last}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Verificar se há transações pendentes
  Future<bool> hasPendingTransactions() async {
    try {
      if (_authController.currentUser.value == null) return false;

      final userId = _authController.currentUser.value!.uid;
      final snapshot = await _firebaseService.firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Erro ao verificar transações pendentes: $e');
      return false;
    }
  }

  /// Limpar transações antigas (apenas falhadas com mais de 30 dias)
  Future<void> cleanupOldFailedTransactions() async {
    try {
      if (_authController.currentUser.value == null) return;

      final userId = _authController.currentUser.value!.uid;
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final snapshot = await _firebaseService.firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'failed')
          .where('timestamp', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firebaseService.firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
        debugPrint('✅ ${snapshot.docs.length} transações antigas removidas');
      }
    } catch (e) {
      debugPrint('Erro ao limpar transações antigas: $e');
    }
  }
}