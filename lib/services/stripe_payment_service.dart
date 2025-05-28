import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:oraculum/services/firebase_service.dart';

class StripePaymentService extends GetxService {
  // ===========================================
  // CONFIGURAÇÕES STRIPE
  // ===========================================
  static const String _publishableKey = 'pk_test_51RTpqm4TyzboYffk5IRBTmwEqPvKtBftyepU82rkCK5j0Bh6TYJ7Ld6e9lqvxoJoNe1xefeE58iFS2Igwvsfnc5q00R2Aztn0o';
  static const String _secretKey = 'sk_test_51RTpqm4TyzboYffkLCT1uIvlITbGX3vgRC6rNnduYStBy2wg99c4DxrraH75S4ATZiPEOdk3KxsYlR8fVQ661CkV00r5Yt8XgO';
  static const String _baseUrl = 'https://api.stripe.com/v1';

  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final RxBool isLoading = false.obs;

  // Headers para requisições à API da Stripe
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_secretKey',
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  @override
  Future<void> onInit() async {
    super.onInit();
    // Inicializar Stripe
    Stripe.publishableKey = _publishableKey;
    await Stripe.instance.applySettings();
  }

  // ===========================================
  // GERENCIAMENTO DE CLIENTES
  // ===========================================

  /// Criar cliente na Stripe
  Future<Map<String, dynamic>> createCustomer({
    required String email,
    String? name,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final body = {
        'email': email,
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (metadata != null)
          ...metadata.map((key, value) => MapEntry('metadata[$key]', value.toString())),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/customers'),
        headers: _headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Erro ao criar cliente: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro na requisição: $e',
      };
    }
  }

  /// Anexar método de pagamento ao customer
  Future<Map<String, dynamic>> attachPaymentMethodToCustomer({
    required String paymentMethodId,
    required String customerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payment_methods/$paymentMethodId/attach'),
        headers: _headers,
        body: {
          'customer': customerId,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error']['message'] ?? 'Erro ao anexar método de pagamento',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro na requisição: $e',
      };
    }
  }

  // ===========================================
  // PAYMENT INTENTS
  // ===========================================

  /// Criar Payment Intent
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    String? customerId,
    Map<String, dynamic>? metadata,
    List<String>? paymentMethodTypes,
  }) async {
    try {
      final amountInCents = (amount * 100).round();

      final body = {
        'amount': amountInCents.toString(),
        'currency': currency.toLowerCase(),
        if (paymentMethodTypes != null)
          ...paymentMethodTypes.asMap().map((index, type) =>
              MapEntry('payment_method_types[$index]', type))
        else
          'payment_method_types[0]': 'card',
        if (customerId != null) 'customer': customerId,
        if (metadata != null)
          ...metadata.map((key, value) => MapEntry('metadata[$key]', value.toString())),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents'),
        headers: _headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Erro ao criar Payment Intent: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro na requisição: $e',
      };
    }
  }

  /// Confirmar Payment Intent
  Future<Map<String, dynamic>> confirmPaymentIntent({
    required String paymentIntentId,
    String? paymentMethodId,
    Map<String, dynamic>? paymentMethodData,
  }) async {
    try {
      final body = <String, String>{};

      if (paymentMethodId != null) {
        body['payment_method'] = paymentMethodId;
      }

      if (paymentMethodData != null) {
        paymentMethodData.forEach((key, value) {
          body['payment_method_data[$key]'] = value.toString();
        });
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents/$paymentIntentId/confirm'),
        headers: _headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error']['message'] ?? 'Erro ao confirmar pagamento',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro na requisição: $e',
      };
    }
  }

  /// Verificar status do Payment Intent
  Future<Map<String, dynamic>> checkPaymentIntentStatus(String paymentIntentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payment_intents/$paymentIntentId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
          'status': data['status'],
        };
      } else {
        return {
          'success': false,
          'error': 'Erro ao verificar status do pagamento: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro na requisição: $e',
      };
    }
  }

  // ===========================================
  // PAGAMENTO COM CARTÃO (CRÉDITO/DÉBITO)
  // ===========================================

  /// Processar pagamento com cartão usando Payment Sheet (Interativo)
  Future<Map<String, dynamic>> processCardPaymentInteractive({
    required BuildContext context,
    required double amount,
    required String description,
    required String serviceId,
    required String serviceType,
    String? customerId,
    String? currency = 'brl',
  }) async {
    try {
      isLoading.value = true;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'error': 'Usuário não autenticado',
        };
      }

      // 1. Criar Payment Intent
      final paymentIntentResult = await createPaymentIntent(
        amount: amount,
        currency: currency ?? 'brl',
        customerId: customerId,
        metadata: {
          'user_id': userId,
          'service_id': serviceId,
          'service_type': serviceType,
          'description': description,
        },
      );

      if (!paymentIntentResult['success']) {
        return paymentIntentResult;
      }

      final clientSecret = paymentIntentResult['data']['client_secret'];

      // 2. Inicializar Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Oraculum',
          customerId: customerId,
          style: ThemeMode.system,
          billingDetails: BillingDetails(
            email: FirebaseAuth.instance.currentUser?.email,
          ),
          allowsDelayedPaymentMethods: false,
        ),
      );

      // 3. Apresentar Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Se chegou até aqui, o pagamento foi bem-sucedido
      final paymentId = await _savePaymentRecord(
        userId: userId,
        amount: amount,
        description: description,
        serviceId: serviceId,
        serviceType: serviceType,
        paymentMethod: 'card',
        stripePaymentIntentId: paymentIntentResult['data']['id'],
        status: 'succeeded',
      );

      // 5. Adicionar créditos ao usuário
      await _addCreditsToUser(userId, amount);

      return {
        'success': true,
        'payment_id': paymentId,
        'stripe_payment_intent_id': paymentIntentResult['data']['id'],
      };

    } on StripeException catch (e) {
      return {
        'success': false,
        'error': _getStripeErrorMessage(e),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro inesperado: $e',
      };
    } finally {
      isLoading.value = false;
    }
  }

  /// Processar pagamento com cartão salvo (Não interativo)
  Future<Map<String, dynamic>> processCardPaymentWithSavedCard({
    required double amount,
    required String customerId,
    required String description,
    required String serviceId,
    required String serviceType,
    String? currency = 'brl',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      isLoading.value = true;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'error': 'Usuário não autenticado',
        };
      }

      // 1. Buscar método de pagamento padrão do customer
      final paymentMethods = await getSavedPaymentMethods(customerId);
      if (paymentMethods.isEmpty) {
        return {
          'success': false,
          'error': 'Nenhum método de pagamento encontrado',
        };
      }

      final paymentMethodId = paymentMethods.first['id'];

      // 2. Criar Payment Intent
      final paymentIntentResult = await createPaymentIntent(
        amount: amount,
        currency: currency ?? 'brl',
        customerId: customerId,
        metadata: {
          'user_id': userId,
          'service_id': serviceId,
          'service_type': serviceType,
          'description': description,
          if (metadata != null) ...metadata,
        },
      );

      if (!paymentIntentResult['success']) {
        return paymentIntentResult;
      }

      final paymentIntentId = paymentIntentResult['data']['id'];
      final clientSecret = paymentIntentResult['data']['client_secret'];

      // 3. Confirmar Payment Intent
      final confirmResult = await confirmPaymentIntent(
        paymentIntentId: paymentIntentId,
        paymentMethodId: paymentMethodId,
      );

      if (!confirmResult['success']) {
        return confirmResult;
      }

      final status = confirmResult['data']['status'];

      // 4. Processar resultado
      if (status == 'succeeded') {
        final paymentId = await _savePaymentRecord(
          userId: userId,
          amount: amount,
          description: description,
          serviceId: serviceId,
          serviceType: serviceType,
          paymentMethod: 'card',
          stripePaymentIntentId: paymentIntentId,
          status: 'succeeded',
        );

        await _addCreditsToUser(userId, amount);

        return {
          'success': true,
          'payment_id': paymentId,
          'payment_intent_id': paymentIntentId,
          'client_secret': clientSecret,
          'payment_method_id': paymentMethodId,
          'status': status,
        };
      } else if (status == 'requires_action') {
        return {
          'success': false,
          'requires_action': true,
          'payment_intent_id': paymentIntentId,
          'client_secret': clientSecret,
          'error': 'O pagamento requer autenticação adicional',
        };
      } else {
        return {
          'success': false,
          'error': 'Pagamento não foi aprovado. Status: $status',
        };
      }

    } catch (e) {
      return {
        'success': false,
        'error': 'Erro inesperado: $e',
      };
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================
  // PAGAMENTO PIX
  // ===========================================

  /// Criar pagamento PIX
  Future<Map<String, dynamic>> createPixPayment({
    required double amount,
    required String description,
    required String serviceId,
    required String serviceType,
    String? currency = 'brl',
  }) async {
    try {
      isLoading.value = true;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'error': 'Usuário não autenticado',
        };
      }

      // 1. Criar Payment Intent para PIX
      final paymentIntentResult = await createPaymentIntent(
        amount: amount,
        currency: currency ?? 'brl',
        paymentMethodTypes: ['pix'],
        metadata: {
          'user_id': userId,
          'service_id': serviceId,
          'service_type': serviceType,
          'description': description,
        },
      );

      if (!paymentIntentResult['success']) {
        return paymentIntentResult;
      }

      final paymentIntentId = paymentIntentResult['data']['id'];

      // 2. Confirmar Payment Intent para gerar QR Code PIX
      final confirmResult = await confirmPaymentIntent(
        paymentIntentId: paymentIntentId,
        paymentMethodData: {'type': 'pix'},
      );

      if (!confirmResult['success']) {
        return confirmResult;
      }

      final confirmedData = confirmResult['data'];

      // Verificar se tem dados do PIX
      if (confirmedData['next_action'] == null ||
          confirmedData['next_action']['pix_display_qr_code'] == null) {
        return {
          'success': false,
          'error': 'Não foi possível gerar QR Code PIX',
        };
      }

      final pixData = confirmedData['next_action']['pix_display_qr_code'];

      // 3. Salvar registro de pagamento
      final paymentId = await _savePaymentRecord(
        userId: userId,
        amount: amount,
        description: description,
        serviceId: serviceId,
        serviceType: serviceType,
        paymentMethod: 'pix',
        stripePaymentIntentId: paymentIntentId,
        status: 'pending',
        additionalData: {
          'pixQrCode': pixData['data'],
          'expiresAt': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        },
      );

      // 4. Iniciar monitoramento do pagamento
      _monitorPixPayment(paymentIntentId, paymentId);

      return {
        'success': true,
        'payment_id': paymentId,
        'stripe_payment_intent_id': paymentIntentId,
        'pix_qr_code': pixData['data'],
      };

    } catch (e) {
      return {
        'success': false,
        'error': 'Erro ao criar pagamento PIX: $e',
      };
    } finally {
      isLoading.value = false;
    }
  }

  /// Monitorar status do pagamento PIX
  void _monitorPixPayment(String paymentIntentId, String localPaymentId) {
    Timer.periodic(const Duration(seconds: 15), (timer) async {
      try {
        final statusResult = await checkPaymentIntentStatus(paymentIntentId);

        if (!statusResult['success']) {
          return;
        }

        final status = statusResult['status'];

        if (status == 'succeeded') {
          timer.cancel();
          await _updatePaymentStatus(localPaymentId, 'succeeded');

          // Adicionar créditos ao usuário
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            final paymentDoc = await _firebaseService.firestore
                .collection('payments')
                .doc(localPaymentId)
                .get();

            if (paymentDoc.exists) {
              final amount = (paymentDoc.data()!['amount'] as num).toDouble();
              await _addCreditsToUser(userId, amount);
            }
          }

          Get.snackbar(
            'Pagamento Confirmado',
            'Seu pagamento PIX foi confirmado!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else if (status == 'failed' || status == 'canceled') {
          timer.cancel();
          await _updatePaymentStatus(localPaymentId, status);

          Get.snackbar(
            'Pagamento Falhou',
            'Seu pagamento PIX não foi confirmado.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }

        // Parar após 30 minutos (120 tentativas de 15 segundos)
        if (timer.tick > 120) {
          timer.cancel();
        }
      } catch (e) {
        debugPrint('Erro no monitoramento PIX: $e');
      }
    });
  }

  // ===========================================
  // MÉTODOS DE PAGAMENTO SALVOS
  // ===========================================

  /// Obter métodos de pagamento salvos do cliente
  Future<List<Map<String, dynamic>>> getSavedPaymentMethods(String customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/customers/$customerId/payment_methods?type=card'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (e) {
      debugPrint('Erro ao buscar métodos de pagamento: $e');
    }
    return [];
  }

  // ===========================================
  // MÉTODOS AUXILIARES
  // ===========================================

  /// Salvar registro de pagamento no Firestore
  Future<String> _savePaymentRecord({
    required String userId,
    required double amount,
    required String description,
    required String serviceId,
    required String serviceType,
    required String paymentMethod,
    required String stripePaymentIntentId,
    required String status,
    Map<String, dynamic>? additionalData,
  }) async {
    final paymentData = {
      'userId': userId,
      'amount': amount,
      'description': description,
      'serviceId': serviceId,
      'serviceType': serviceType,
      'paymentMethod': paymentMethod,
      'stripePaymentIntentId': stripePaymentIntentId,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': DateTime.now().toIso8601String(),
      if (additionalData != null) 'additionalData': additionalData,
    };

    final docRef = await _firebaseService.firestore
        .collection('payments')
        .add(paymentData);

    return docRef.id;
  }

  /// Atualizar status do pagamento
  Future<void> _updatePaymentStatus(String paymentId, String status) async {
    await _firebaseService.firestore
        .collection('payments')
        .doc(paymentId)
        .update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == 'succeeded') 'completedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Adicionar créditos ao usuário
  Future<void> _addCreditsToUser(String userId, double amount) async {
    final userDoc = await _firebaseService.firestore
        .collection('users')
        .doc(userId)
        .get();

    final currentCredits = (userDoc.data()?['credits'] ?? 0.0) as num;
    final newCredits = currentCredits.toDouble() + amount;

    await _firebaseService.firestore
        .collection('users')
        .doc(userId)
        .update({'credits': newCredits});
  }

  /// Obter mensagem de erro amigável do Stripe
  String _getStripeErrorMessage(StripeException e) {
    switch (e.error.code) {
      case FailureCode.Canceled:
        return 'Pagamento cancelado pelo usuário';
      case FailureCode.Failed:
        return 'Pagamento falhou';
      case FailureCode.Timeout:
        return 'Timeout na operação';
      default:
        return e.error.localizedMessage ?? 'Erro desconhecido no pagamento';
    }
  }
}