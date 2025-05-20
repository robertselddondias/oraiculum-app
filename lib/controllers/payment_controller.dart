import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/models/credit_card_model.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/services/pagarme_service.dart';
import 'package:oraculum/services/payment_service.dart';
import 'package:http/http.dart' as http;
import 'package:oraculum/utils/pagarme_payment_status.dart';

class PaymentController extends GetxController {
  final PaymentService _paymentService = Get.find<PaymentService>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthController _authController = Get.find<AuthController>();
  final PagarmeService _pagarmeService = Get.find<PagarmeService>();

  RxBool isLoading = false.obs;
  RxList<Map<String, dynamic>> paymentHistory = <Map<String, dynamic>>[].obs;
  RxDouble userCredits = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
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
  // Este método serve como ponte para os métodos específicos de pagamento
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

        case 'transferência bancária':
        // Simular pagamento e adicionar créditos diretamente
          await addCredits(amount);
          paymentId = 'bank-${DateTime.now().millisecondsSinceEpoch}';
          break;

        case 'pix':
        // Simular pagamento e adicionar créditos diretamente
          await addCredits(amount);
          paymentId = 'pix-${DateTime.now().millisecondsSinceEpoch}';
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

      // Processar pagamento com Google Pay
      final paymentId = await _paymentService.payWithGooglePay(
        amount: amount,
        userId: userId,
        serviceId: serviceId,
        serviceType: serviceType,
        description: description,
        context: context,
      );

      if (paymentId != null) {
        // Os créditos já são adicionados no serviço
        await loadUserCredits();

        Get.snackbar(
          'Sucesso',
          'Pagamento aprovado! Seus créditos foram atualizados',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return paymentId;
      } else {
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

      // Processar pagamento com Apple Pay
      final paymentId = await _paymentService.payWithApplePay(
        amount: amount,
        userId: userId,
        serviceId: serviceId,
        serviceType: serviceType,
        description: description,
        context: context,
      );

      if (paymentId != null) {
        // Os créditos já são adicionados no serviço
        await loadUserCredits();

        Get.snackbar(
          'Sucesso',
          'Pagamento aprovado! Seus créditos foram atualizados',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return paymentId;
      } else {
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

  // Novo método implementado com a classe PagarmePaymentStatus
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

      // Buscar o cartão padrão ou o cartão específico
      QuerySnapshot querySnapshot;
      if (specificCardId != null) {
        querySnapshot = await _firebaseService.firestore
            .collection('credit_cards')
            .where('id', isEqualTo: specificCardId)
            .limit(1)
            .get();
      } else {
        querySnapshot = await _firebaseService.getDefaultCreditCard(userId);
      }

      if (querySnapshot.docs.isEmpty) {
        Get.snackbar(
          'Erro',
          'Nenhum cartão encontrado para realizar o pagamento',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }

      final cartao = querySnapshot.docs.first.data() as Map<String, dynamic>;

      // Processar o pagamento com o Pagar.me
      http.Response response = await _pagarmeService.createOrder(
          creditCardId: cartao['cardId'],
          customerId: cartao['customerId'],
          userId: userId,
          amount: (amount * 100).toInt(), // Converter para centavos
          orderId: 'credit-$userId-${DateTime.now().millisecondsSinceEpoch}'
      );

      Map<String, dynamic> responseBody = json.decode(response.body);

      // Verificar o status da resposta usando a classe PagarmePaymentStatus
      if (response.statusCode == 200 && PagarmePaymentStatus.isSuccessful(responseBody['status'])) {
        // Pagamento bem-sucedido, adicionar créditos
        final success = await _paymentService.updateUserCredits(userId, amount);

        if (success) {
          await loadUserCredits();

          // Registrar o pagamento no Firestore
          final paymentData = {
            'userId': userId,
            'amount': amount,
            'serviceId': serviceId,
            'serviceType': serviceType,
            'description': description,
            'paymentMethod': 'Cartão de Crédito',
            'cardLastFourDigits': cartao['lastFourDigits'] ?? '****',
            'cardBrand': cartao['brandType'] ?? 'unknown',
            'pagarmeOrderId': responseBody['id'],
            'pagarmeChargeId': responseBody['charges']?[0]?['id'] ?? '',
            'status': responseBody['status'],
            'statusMessage': PagarmePaymentStatus.getStatusMessage(responseBody['status']),
            'timestamp': FieldValue.serverTimestamp(),
          };

          final docRef = await _firebaseService.firestore
              .collection('payments')
              .add(paymentData);

          Get.back();
          Get.snackbar(
            'Sucesso',
            'Pagamento ${PagarmePaymentStatus.getStatusMessage(responseBody['status'])}',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );

          return docRef.id;
        }
      } else if (PagarmePaymentStatus.isInProgress(responseBody['status'])) {
        // Pagamento em processamento
        final paymentData = {
          'userId': userId,
          'amount': amount,
          'serviceId': serviceId,
          'serviceType': serviceType,
          'description': description,
          'paymentMethod': 'Cartão de Crédito',
          'cardLastFourDigits': cartao['lastFourDigits'] ?? '****',
          'cardBrand': cartao['brandType'] ?? 'unknown',
          'pagarmeOrderId': responseBody['id'],
          'pagarmeChargeId': responseBody['charges']?[0]?['id'] ?? '',
          'status': responseBody['status'],
          'statusMessage': PagarmePaymentStatus.getStatusMessage(responseBody['status']),
          'timestamp': FieldValue.serverTimestamp(),
        };

        final docRef = await _firebaseService.firestore
            .collection('payments')
            .add(paymentData);

        Get.snackbar(
          'Processando',
          'Seu pagamento está sendo processado: ${PagarmePaymentStatus.getStatusMessage(responseBody['status'])}',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        return docRef.id;
      } else {
        // Pagamento falhou
        final failMessage = responseBody['charges']?[0]?['last_transaction']?['acquirer_message'] ??
            PagarmePaymentStatus.getStatusMessage(responseBody['status']);

        Get.snackbar(
          'Erro no Pagamento',
          failMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        // Registrar a falha no pagamento no Firestore
        final paymentData = {
          'userId': userId,
          'amount': amount,
          'serviceId': serviceId,
          'serviceType': serviceType,
          'description': description,
          'paymentMethod': 'Cartão de Crédito',
          'cardLastFourDigits': cartao['lastFourDigits'] ?? '****',
          'cardBrand': cartao['brandType'] ?? 'unknown',
          'pagarmeOrderId': responseBody['id'] ?? '',
          'pagarmeChargeId': responseBody['charges']?[0]?['id'] ?? '',
          'status': responseBody['status'] ?? 'failed',
          'statusMessage': failMessage,
          'errorDetails': responseBody['charges']?[0]?['last_transaction']?['acquirer_message'] ?? '',
          'timestamp': FieldValue.serverTimestamp(),
        };

        await _firebaseService.firestore
            .collection('failed_payments')
            .add(paymentData);

        return '';
      }

      return '';
    } catch (e) {
      debugPrint('Erro ao processar pagamento com cartão de crédito: $e');
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

      // Usar o método do PaymentService
      final paymentId = await _paymentService.processPaymentWithCredits(
        userId,
        amount,
        description,
        serviceId,
        serviceType,
      );

      await loadUserCredits();

      Get.snackbar(
        'Sucesso',
        'Pagamento com créditos realizado com sucesso',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      return paymentId;
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

      QuerySnapshot querySnapshot = await _firebaseService.getDefaultCreditCard(_firebaseService.userId!);
      if(!querySnapshot.docs.isEmpty) {
        final userId = _authController.currentUser.value!.uid;
        Map<String, dynamic> cartao = querySnapshot.docs.first.data() as Map<String, dynamic>;

        http.Response response = await _pagarmeService.createOrder(
            creditCardId: cartao['cardId'],
            customerId: cartao['customerId'],
            userId: cartao['userId'],
            amount: amount.toInt(),
            orderId: 'credit-$userId}'
        );
        Map<String, dynamic> body = json.decode(response.body);

        // Usando a classe PagarmePaymentStatus para verificar o status
        if(response.statusCode == 200 && PagarmePaymentStatus.isSuccessful(body['status'])) {
          final success = await _paymentService.updateUserCredits(userId, amount);

          if (success) {
            await loadUserCredits();

            Get.snackbar(
              'Sucesso',
              'Créditos adicionados com sucesso',
              backgroundColor: Colors.green,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );

            return true;
          }
        } else if (PagarmePaymentStatus.isInProgress(body['status'])) {
          Get.snackbar(
            'Processando',
            'Seu pagamento está sendo processado: ${PagarmePaymentStatus.getStatusMessage(body['status'])}',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        } else {
          // Pagamento falhou
          final failMessage = body['charges']?[0]?['last_transaction']?['acquirer_message'] ??
              PagarmePaymentStatus.getStatusMessage(body['status']);

          Get.snackbar(
            'Erro no Pagamento',
            failMessage,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }
      }

      return false;
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
    return await addCredits(-amount);
  }
}