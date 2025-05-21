import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/services/efi_payment_service.dart';
import 'package:oraculum/services/payment_service.dart';

class PaymentController extends GetxController {
  final PaymentService _paymentService = Get.find<PaymentService>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthController _authController = Get.find<AuthController>();

  // Novo serviço EFI
  late EfiPayService _efiPayService;

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

  // NOVO MÉTODO: Processamento de pagamento com PIX
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

      // Obter o CPF do usuário
      final userData = await _firebaseService.getUserData(userId);
      final userDoc = userData.data() as Map<String, dynamic>?;

      if (userDoc == null) {
        Get.snackbar(
          'Erro',
          'Dados do usuário não encontrados',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }

      // Criar cobrança Pix
      final pixResponse = await _efiPayService.createPixCharge(
        value: amount,
        chavePixDestinatario: 'chavepix@oraculum.com.br', // Substitua pela chave Pix real da aplicação
        descricao: description,
      );

      if (!pixResponse['success']) {
        Get.snackbar(
          'Erro',
          'Falha ao gerar cobrança Pix: ${pixResponse['error']}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }

      // Extrair informações da resposta
      final pixData = pixResponse['data'];
      final String txid = pixData['txid']; // ID da transação
      final String qrCode = pixData['qr_code_emv']; // Código QR do Pix
      final String qrCodeImage = pixData['qr_code']; // Imagem do QR code

      // Mostrar QR Code para o usuário
      await _showPixQrCode(qrCode, qrCodeImage, amount);

      // Registrar o pagamento como pendente no Firestore
      final paymentData = {
        'userId': userId,
        'amount': amount,
        'serviceId': serviceId,
        'serviceType': serviceType,
        'description': description,
        'paymentMethod': 'Pix',
        'status': 'pending',
        'efiTxid': txid,
        'timestamp': FieldValue.serverTimestamp(),
      };

      final docRef = await _firebaseService.firestore
          .collection('payments')
          .add(paymentData);

      // Iniciar monitoramento da cobrança (em uma aplicação real)
      // _monitorPixPayment(txid, docRef.id);

      // Para esta demonstração, vamos assumir que o pagamento será bem-sucedido
      // Em um app real, isso seria feito através de webhook ou polling
      await Future.delayed(const Duration(seconds: 2));
      await _updatePixPaymentStatus(docRef.id, 'approved');

      await _paymentService.updateUserCredits(userId, amount);
      await loadUserCredits();

      return docRef.id;
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

  // Mostrar diálogo com QR code do Pix
  Future<void> _showPixQrCode(String qrCode, String qrCodeImage, double amount) async {
    await Get.dialog(
      AlertDialog(
        title: const Text('Pagamento via Pix'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escaneie o QR code abaixo com o aplicativo do seu banco para realizar o pagamento:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Imagem do QR code (em um app real, seria uma imagem do QR code)
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.qr_code_2,
                    size: 150,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Valor: R\$ ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              // Código Pix copia e cola
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        qrCode.length > 30 ? '${qrCode.substring(0, 30)}...' : qrCode,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        // Em um app real, copiar o código para a área de transferência
                        Get.snackbar(
                          'Copiado',
                          'Código PIX copiado para a área de transferência',
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple.shade800,
            ),
            child: const Text('Já paguei'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Atualizar status de pagamento Pix
  Future<void> _updatePixPaymentStatus(String paymentId, String status) async {
    await _firebaseService.firestore
        .collection('payments')
        .doc(paymentId)
        .update({'status': status});
  }

  // Método para processar pagamento com cartão de crédito - ATUALIZADO PARA USAR EFIPAYSERVICE
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

      // Buscar dados do usuário
      final userData = await _firebaseService.getUserData(userId);
      final userDoc = userData.data() as Map<String, dynamic>?;

      if (userDoc == null) {
        Get.snackbar(
          'Erro',
          'Dados do usuário não encontrados',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return '';
      }

      // Processar o pagamento com o EFI
      final paymentResponse = await _efiPayService.createCreditCardPayment(
        value: amount,
        cardToken: cartao['cardId'],
        name: userDoc['name'] ?? '',
        cpfCnpj: cartao['document'] ?? userDoc['document'] ?? '',
        installments: 1,
      );

      if (paymentResponse['success']) {
        // Adicionar créditos à conta do usuário
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
            'efiChargeId': paymentResponse['data']['charge_id'],
            'status': 'approved',
            'timestamp': FieldValue.serverTimestamp(),
          };

          final docRef = await _firebaseService.firestore
              .collection('payments')
              .add(paymentData);

          Get.back();
          Get.snackbar(
            'Sucesso',
            'Pagamento realizado com sucesso',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );

          return docRef.id;
        }
      } else {
        // Pagamento falhou
        Get.snackbar(
          'Erro no Pagamento',
          paymentResponse['error'] ?? 'Falha no processamento do pagamento',
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
          'status': 'failed',
          'errorDetails': paymentResponse['error'],
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

        // Buscar dados do usuário
        final userData = await _firebaseService.getUserData(userId);
        final userDoc = userData.data() as Map<String, dynamic>?;

        if (userDoc == null) {
          Get.snackbar(
            'Erro',
            'Dados do usuário não encontrados',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }

        // Processar pagamento usando EFI
        final paymentResponse = await _efiPayService.createCreditCardPayment(
          value: amount,
          cardToken: cartao['cardId'],
          name: userDoc['name'] ?? '',
          cpfCnpj: cartao['document'] ?? userDoc['document'] ?? '',
        );

        if (paymentResponse['success']) {
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
        } else {
          Get.snackbar(
            'Erro no Pagamento',
            paymentResponse['error'] ?? 'Falha ao adicionar créditos',
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
    return await _paymentService.updateUserCredits(_authController.currentUser.value!.uid, -amount);
  }
}