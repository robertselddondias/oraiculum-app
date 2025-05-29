import 'dart:convert';
import 'package:flutter/material.dart';
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
    await _validateConfiguration();
  }

  // ===========================================
  // VALIDAÇÃO DE CONFIGURAÇÃO
  // ===========================================

  /// Validar se as chaves estão configuradas corretamente
  Future<void> _validateConfiguration() async {
    try {
      debugPrint('🔐 Validando configuração do Stripe...');

      if (_secretKey.isEmpty || _publishableKey.isEmpty) {
        debugPrint('❌ Chaves do Stripe não configuradas');
        return;
      }

      if (!_secretKey.startsWith('sk_')) {
        debugPrint('❌ Secret Key inválida - deve começar com sk_');
        return;
      }

      if (!_publishableKey.startsWith('pk_')) {
        debugPrint('❌ Publishable Key inválida - deve começar com pk_');
        return;
      }

      // Testar conexão
      final testResult = await testStripeConnection();
      if (testResult) {
        debugPrint('✅ Configuração do Stripe válida');
      } else {
        debugPrint('❌ Falha na validação da configuração');
      }
    } catch (e) {
      debugPrint('❌ Erro na validação: $e');
    }
  }

  /// Verificar se o serviço está configurado corretamente
  Future<Map<String, dynamic>> validateSetup() async {
    try {
      debugPrint('🔍 Executando validação completa...');

      // 1. Verificar formato das chaves
      if (_secretKey.isEmpty || !_secretKey.startsWith('sk_')) {
        return {
          'success': false,
          'error': 'Secret Key inválida ou não configurada',
          'checks': {
            'secret_key': false,
            'publishable_key': _publishableKey.startsWith('pk_'),
            'api_connection': false,
          },
        };
      }

      if (_publishableKey.isEmpty || !_publishableKey.startsWith('pk_')) {
        return {
          'success': false,
          'error': 'Publishable Key inválida ou não configurada',
          'checks': {
            'secret_key': true,
            'publishable_key': false,
            'api_connection': false,
          },
        };
      }

      // 2. Testar conexão com API
      final response = await http.get(
        Uri.parse('$_baseUrl/account'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final accountData = json.decode(response.body);
        debugPrint('✅ Validação completa - Conta: ${accountData['display_name']}');

        return {
          'success': true,
          'message': 'Configuração válida',
          'account': {
            'id': accountData['id'],
            'display_name': accountData['display_name'],
            'country': accountData['country'],
            'currency': accountData['default_currency'],
            'business_profile': accountData['business_profile'],
          },
          'checks': {
            'secret_key': true,
            'publishable_key': true,
            'api_connection': true,
          },
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error']['message'] ?? 'Credenciais inválidas',
          'checks': {
            'secret_key': false,
            'publishable_key': true,
            'api_connection': false,
          },
        };
      }

    } catch (e) {
      debugPrint('❌ Erro na validação: $e');
      return {
        'success': false,
        'error': 'Erro na validação: $e',
        'checks': {
          'secret_key': false,
          'publishable_key': false,
          'api_connection': false,
        },
      };
    }
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
      debugPrint('🔄 Criando customer na Stripe para: $email');

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
        final data = json.decode(response.body);
        debugPrint('✅ Customer criado: ${data['id']}');

        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorData = json.decode(response.body);
        debugPrint('❌ Erro ao criar customer: ${errorData['error']['message']}');

        return {
          'success': false,
          'error': errorData['error']['message'] ?? 'Erro ao criar cliente',
        };
      }
    } catch (e) {
      debugPrint('❌ Erro na requisição de criar customer: $e');
      return {
        'success': false,
        'error': 'Erro na requisição: $e',
      };
    }
  }

  // ===========================================
  // MÉTODOS DE PAGAMENTO
  // ===========================================

  /// Criar Payment Method (cartão) diretamente via API
  Future<Map<String, dynamic>> createPaymentMethod({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvc,
    required String cardHolderName,
    String? phone,
  }) async {
    try {
      debugPrint('🔄 Criando PaymentMethod na Stripe');
      debugPrint('Cartão: ${cardNumber.substring(0, 4)}****');

      final body = {
        'type': 'card',
        'card[number]': cardNumber,
        'card[exp_month]': expiryMonth,
        'card[exp_year]': expiryYear,
        'card[cvc]': cvc,
        'billing_details[name]': cardHolderName,
        if (phone != null) 'billing_details[phone]': phone,
        'billing_details[address][country]': 'BR',
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/payment_methods'),
        headers: _headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ PaymentMethod criado: ${data['id']}');

        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']['message'] ?? 'Erro ao criar método de pagamento';
        debugPrint('❌ Erro ao criar PaymentMethod: $errorMessage');

        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      debugPrint('❌ Erro na requisição de PaymentMethod: $e');
      return {
        'success': false,
        'error': 'Erro ao processar cartão: $e',
      };
    }
  }

  /// Anexar Payment Method ao Customer
  Future<Map<String, dynamic>> attachPaymentMethodToCustomer({
    required String paymentMethodId,
    required String customerId,
  }) async {
    try {
      debugPrint('🔄 Anexando PaymentMethod $paymentMethodId ao Customer $customerId');

      final response = await http.post(
        Uri.parse('$_baseUrl/payment_methods/$paymentMethodId/attach'),
        headers: _headers,
        body: {
          'customer': customerId,
        },
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

  // ===========================================
  // PAYMENT INTENTS
  // ===========================================

  /// Criar Payment Intent
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String customerId,
    String currency = 'brl',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final amountInCents = (amount * 100).round();
      debugPrint('🔄 Criando PaymentIntent: R\$ ${amount.toStringAsFixed(2)} ($amountInCents centavos)');

      final body = {
        'amount': amountInCents.toString(),
        'currency': currency.toLowerCase(),
        'customer': customerId,
        'payment_method_types[]': 'card',
        'confirmation_method': 'manual',
        'confirm': 'true',
        if (metadata != null)
          ...metadata.map((key, value) => MapEntry('metadata[$key]', value.toString())),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents'),
        headers: _headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ PaymentIntent criado: ${data['id']} - Status: ${data['status']}');

        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']['message'] ?? 'Erro ao criar pagamento';
        debugPrint('❌ Erro ao criar PaymentIntent: $errorMessage');

        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      debugPrint('❌ Erro na requisição de PaymentIntent: $e');
      return {
        'success': false,
        'error': 'Erro na requisição: $e',
      };
    }
  }

  /// Confirmar Payment Intent com Payment Method
  Future<Map<String, dynamic>> confirmPaymentIntent({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    try {
      debugPrint('🔄 Confirmando PaymentIntent: $paymentIntentId');

      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents/$paymentIntentId/confirm'),
        headers: _headers,
        body: {
          'payment_method': paymentMethodId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ PaymentIntent confirmado: Status ${data['status']}');

        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']['message'] ?? 'Erro ao confirmar pagamento';
        debugPrint('❌ Erro ao confirmar PaymentIntent: $errorMessage');

        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      debugPrint('❌ Erro na requisição de confirmação: $e');
      return {
        'success': false,
        'error': 'Erro na requisição: $e',
      };
    }
  }

  // ===========================================
  // FLUXO COMPLETO DE PAGAMENTO COM CARTÃO SALVO
  // ===========================================

  /// Processar pagamento com cartão salvo (método principal)
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
      debugPrint('🔄 Iniciando pagamento com cartão salvo');

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
      debugPrint('💳 Usando PaymentMethod: $paymentMethodId');

      // 2. Criar Payment Intent
      final paymentIntentResult = await createPaymentIntent(
        amount: amount,
        customerId: customerId,
        currency: currency ?? 'brl',
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
      debugPrint('✅ Status final do pagamento: $status');

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
      debugPrint('❌ Erro no processamento do pagamento: $e');
      return {
        'success': false,
        'error': 'Erro inesperado: $e',
      };
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================
  // PAGAMENTO PIX (SIMPLIFICADO)
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
      debugPrint('🔄 Criando pagamento PIX');

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'error': 'Usuário não autenticado',
        };
      }

      // Criar Payment Intent para PIX
      final amountInCents = (amount * 100).round();

      final body = {
        'amount': amountInCents.toString(),
        'currency': (currency ?? 'brl').toLowerCase(),
        'payment_method_types[]': 'pix',
        'metadata[user_id]': userId,
        'metadata[service_id]': serviceId,
        'metadata[service_type]': serviceType,
        'metadata[description]': description,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents'),
        headers: _headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final paymentIntentId = data['id'];

        // Confirmar para gerar QR Code PIX
        final confirmResponse = await http.post(
          Uri.parse('$_baseUrl/payment_intents/$paymentIntentId/confirm'),
          headers: _headers,
          body: {
            'payment_method_data[type]': 'pix',
            'return_url': 'https://oraculum.app/payment/return',
          },
        );

        if (confirmResponse.statusCode == 200) {
          final confirmedData = json.decode(confirmResponse.body);

          if (confirmedData['next_action'] != null &&
              confirmedData['next_action']['pix_display_qr_code'] != null) {

            final pixData = confirmedData['next_action']['pix_display_qr_code'];

            // Salvar registro de pagamento
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

            return {
              'success': true,
              'payment_id': paymentId,
              'stripe_payment_intent_id': paymentIntentId,
              'pix_qr_code': pixData['data'],
            };
          }
        }
      }

      return {
        'success': false,
        'error': 'Não foi possível gerar QR Code PIX',
      };

    } catch (e) {
      debugPrint('❌ Erro ao criar pagamento PIX: $e');
      return {
        'success': false,
        'error': 'Erro ao criar pagamento PIX: $e',
      };
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================
  // MÉTODOS DE PAGAMENTO SALVOS
  // ===========================================

  /// Obter métodos de pagamento salvos do cliente
  Future<List<Map<String, dynamic>>> getSavedPaymentMethods(String customerId) async {
    try {
      debugPrint('🔄 Buscando PaymentMethods do customer: $customerId');

      final response = await http.get(
        Uri.parse('$_baseUrl/customers/$customerId/payment_methods?type=card'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final paymentMethods = List<Map<String, dynamic>>.from(data['data']);
        debugPrint('✅ Encontrados ${paymentMethods.length} PaymentMethods');
        return paymentMethods;
      } else {
        debugPrint('❌ Erro ao buscar PaymentMethods: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar métodos de pagamento: $e');
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
    try {
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

      debugPrint('✅ Registro de pagamento salvo: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Erro ao salvar registro de pagamento: $e');
      throw Exception('Erro ao salvar pagamento: $e');
    }
  }

  /// Adicionar créditos ao usuário
  Future<void> _addCreditsToUser(String userId, double amount) async {
    try {
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

      debugPrint('✅ Créditos atualizados: R\$ ${amount.toStringAsFixed(2)} adicionados');
    } catch (e) {
      debugPrint('❌ Erro ao adicionar créditos: $e');
      throw Exception('Erro ao adicionar créditos: $e');
    }
  }

  // ===========================================
  // MÉTODOS DE UTILIDADE
  // ===========================================

  /// Verificar status de um Payment Intent
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

  /// Método para testar conectividade com Stripe
  Future<bool> testStripeConnection() async {
    try {
      debugPrint('🔄 Testando conexão com Stripe...');

      final response = await http.get(
        Uri.parse('$_baseUrl/account'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Conexão com Stripe OK - Conta: ${data['display_name']}');
        return true;
      } else {
        debugPrint('❌ Falha na conexão com Stripe: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erro ao testar conexão com Stripe: $e');
      return false;
    }
  }

  // ===========================================
  // GETTERS PARA CHAVES (CASO NECESSÁRIO)
  // ===========================================
  String get publishableKey => _publishableKey;
  String get secretKey => _secretKey; // Use com cuidado - apenas para debug
}