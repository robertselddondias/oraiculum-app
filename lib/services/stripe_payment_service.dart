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

  // Token de acesso (gerado via autenticação das duas chaves)
  String? _accessToken;
  DateTime? _tokenExpiry;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _authenticate();
  }

  // ===========================================
  // AUTENTICAÇÃO COM TOKEN DE ACESSO
  // ===========================================

  /// Autenticar usando as duas chaves para obter token de acesso
  Future<bool> _authenticate() async {
    try {
      debugPrint('🔐 Autenticando com Stripe...');

      // Para o Stripe, o token de acesso é a própria secret key com Basic Auth
      // Vamos validar as credenciais fazendo uma chamada de teste
      final response = await http.get(
        Uri.parse('$_baseUrl/account'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = _secretKey; // A secret key é nosso token de acesso
        _tokenExpiry = DateTime.now().add(const Duration(hours: 1)); // Token válido por 1 hora

        debugPrint('✅ Autenticação Stripe OK - Conta: ${data['display_name']}');
        return true;
      } else {
        debugPrint('❌ Falha na autenticação Stripe: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erro na autenticação: $e');
      return false;
    }
  }

  /// Verificar se o token ainda é válido
  bool _isTokenValid() {
    return _accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!);
  }

  /// Renovar token se necessário
  Future<void> _ensureValidToken() async {
    if (!_isTokenValid()) {
      await _authenticate();
    }
  }

  /// Headers com autenticação
  Map<String, String> _getHeaders() {
    return {
      'Authorization': 'Bearer $_secretKey',
      'Content-Type': 'application/x-www-form-urlencoded',
      'Stripe-Version': '2023-10-16', // Versão da API
    };
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
      await _ensureValidToken();
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
        headers: _getHeaders(),
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Customer criado: ${data['id']}');
        return {'success': true, 'data': data};
      } else {
        final errorData = json.decode(response.body);
        debugPrint('❌ Erro ao criar customer: ${errorData['error']['message']}');
        return {'success': false, 'error': errorData['error']['message']};
      }
    } catch (e) {
      debugPrint('❌ Erro na requisição de criar customer: $e');
      return {'success': false, 'error': 'Erro na requisição: $e'};
    }
  }

  // ===========================================
  // MÉTODOS DE PAGAMENTO SEGUROS
  // ===========================================

  /*
   * IMPORTANTE - SEGURANÇA PCI:
   *
   * O Stripe não permite envio direto de dados de cartão para a API por questões de segurança.
   * Este fluxo usa tokenização para manter a conformidade PCI:
   *
   * 1. Criar token do cartão (dados sensíveis → token seguro)
   * 2. Usar token para criar PaymentMethod
   * 3. Anexar PaymentMethod ao Customer
   *
   * ALTERNATIVAS RECOMENDADAS:
   * - Stripe Elements (JavaScript) - mais seguro
   * - Flutter Stripe SDK - integração nativa
   * - Stripe Payment Links - sem código
   */

  /// Criar token de cartão (primeiro passo seguro)
  Future<Map<String, dynamic>> createCardToken({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvc,
    required String cardHolderName,
    String? phone,
  }) async {
    try {
      await _ensureValidToken();
      debugPrint('🔄 Criando token de cartão na Stripe');

      final body = {
        'card[number]': cardNumber,
        'card[exp_month]': expiryMonth,
        'card[exp_year]': expiryYear,
        'card[cvc]': cvc,
        'card[name]': cardHolderName,
        'card[address_country]': 'BR',
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/tokens'),
        headers: _getHeaders(),
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Token de cartão criado: ${data['id']}');
        return {'success': true, 'data': data};
      } else {
        final errorData = json.decode(response.body);
        return {'success': false, 'error': errorData['error']['message']};
      }
    } catch (e) {
      debugPrint('❌ Erro ao criar token: $e');
      return {'success': false, 'error': 'Erro ao processar cartão: $e'};
    }
  }

  /// Criar PaymentMethod usando token de cartão (seguro)
  Future<Map<String, dynamic>> createPaymentMethodFromToken({
    required String cardToken,
    required String cardHolderName,
    String? phone,
  }) async {
    try {
      await _ensureValidToken();
      debugPrint('🔄 Criando PaymentMethod a partir do token');

      final body = {
        'type': 'card',
        'card[token]': cardToken,
        'billing_details[name]': cardHolderName,
        if (phone != null) 'billing_details[phone]': phone,
        'billing_details[address][country]': 'BR',
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/payment_methods'),
        headers: _getHeaders(),
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ PaymentMethod criado: ${data['id']}');
        return {'success': true, 'data': data};
      } else {
        final errorData = json.decode(response.body);
        return {'success': false, 'error': errorData['error']['message']};
      }
    } catch (e) {
      debugPrint('❌ Erro ao criar PaymentMethod: $e');
      return {'success': false, 'error': 'Erro ao processar cartão: $e'};
    }
  }

  /// Método completo para criar PaymentMethod (tokenização + criação)
  Future<Map<String, dynamic>> createPaymentMethod({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvc,
    required String cardHolderName,
    String? phone,
  }) async {
    try {
      debugPrint('🔄 Iniciando processo seguro de criação de PaymentMethod');

      // 1. Primeiro criar o token do cartão
      final tokenResult = await createCardToken(
        cardNumber: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvc: cvc,
        cardHolderName: cardHolderName,
        phone: phone,
      );

      if (!tokenResult['success']) {
        return tokenResult; // Retorna o erro do token
      }

      final cardToken = tokenResult['data']['id'];
      debugPrint('✅ Token criado, agora criando PaymentMethod');

      // 2. Usar o token para criar o PaymentMethod
      final paymentMethodResult = await createPaymentMethodFromToken(
        cardToken: cardToken,
        cardHolderName: cardHolderName,
        phone: phone,
      );

      return paymentMethodResult;

    } catch (e) {
      debugPrint('❌ Erro no processo completo: $e');
      return {'success': false, 'error': 'Erro ao processar cartão: $e'};
    }
  }

  /// Anexar PaymentMethod ao Customer
  Future<Map<String, dynamic>> attachPaymentMethodToCustomer({
    required String paymentMethodId,
    required String customerId,
  }) async {
    try {
      await _ensureValidToken();
      debugPrint('🔄 Anexando PaymentMethod ao Customer');

      final response = await http.post(
        Uri.parse('$_baseUrl/payment_methods/$paymentMethodId/attach'),
        headers: _getHeaders(),
        body: {'customer': customerId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ PaymentMethod anexado com sucesso');
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final errorData = json.decode(response.body);
        return {'success': false, 'error': errorData['error']['message']};
      }
    } catch (e) {
      debugPrint('❌ Erro ao anexar PaymentMethod: $e');
      return {'success': false, 'error': 'Erro na requisição: $e'};
    }
  }

  /// Obter métodos de pagamento salvos do cliente
  Future<List<Map<String, dynamic>>> getSavedPaymentMethods(String customerId) async {
    try {
      await _ensureValidToken();
      debugPrint('🔄 Buscando PaymentMethods do customer: $customerId');

      final response = await http.get(
        Uri.parse('$_baseUrl/customers/$customerId/payment_methods?type=card'),
        headers: _getHeaders(),
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
  // PAYMENT INTENTS E PROCESSAMENTO
  // ===========================================

  /// Criar e processar pagamento com cartão salvo
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
      await _ensureValidToken();
      isLoading.value = true;
      debugPrint('🔄 Processando pagamento com cartão salvo');

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return {'success': false, 'error': 'Usuário não autenticado'};
      }

      // 1. Buscar método de pagamento padrão
      final paymentMethods = await getSavedPaymentMethods(customerId);
      if (paymentMethods.isEmpty) {
        return {'success': false, 'error': 'Nenhum método de pagamento encontrado'};
      }

      final paymentMethodId = paymentMethods.first['id'];
      debugPrint('💳 Usando PaymentMethod: $paymentMethodId');

      // 2. Criar Payment Intent
      final amountInCents = (amount * 100).round();
      final body = {
        'amount': amountInCents.toString(),
        'currency': currency!.toLowerCase(),
        'customer': customerId,
        'payment_method': paymentMethodId,
        'confirmation_method': 'manual',
        'confirm': 'true',
        'description': description,
        'metadata[user_id]': userId,
        'metadata[service_id]': serviceId,
        'metadata[service_type]': serviceType,
        if (metadata != null)
          ...metadata.map((key, value) => MapEntry('metadata[$key]', value.toString())),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents'),
        headers: _getHeaders(),
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];
        final paymentIntentId = data['id'];

        debugPrint('✅ PaymentIntent criado: $paymentIntentId - Status: $status');

        if (status == 'succeeded') {
          // Pagamento aprovado
          final paymentId = await _savePaymentRecord(
            userId: userId,
            amount: amount,
            description: description,
            serviceId: serviceId,
            serviceType: serviceType,
            stripePaymentIntentId: paymentIntentId,
            status: 'succeeded',
          );

          await _addCreditsToUser(userId, amount);

          return {
            'success': true,
            'payment_id': paymentId,
            'payment_intent_id': paymentIntentId,
            'payment_method_id': paymentMethodId,
            'status': status,
          };
        } else if (status == 'requires_action') {
          return {
            'success': false,
            'requires_action': true,
            'payment_intent_id': paymentIntentId,
            'client_secret': data['client_secret'],
            'error': 'O pagamento requer autenticação adicional',
          };
        } else {
          return {
            'success': false,
            'error': 'Pagamento não foi aprovado. Status: $status',
          };
        }
      } else {
        final errorData = json.decode(response.body);
        return {'success': false, 'error': errorData['error']['message']};
      }

    } catch (e) {
      debugPrint('❌ Erro no processamento do pagamento: $e');
      return {'success': false, 'error': 'Erro inesperado: $e'};
    } finally {
      isLoading.value = false;
    }
  }

  /// Criar pagamento PIX
  Future<Map<String, dynamic>> createPixPayment({
    required double amount,
    required String description,
    required String serviceId,
    required String serviceType,
    String? currency = 'brl',
  }) async {
    try {
      await _ensureValidToken();
      isLoading.value = true;
      debugPrint('🔄 Criando pagamento PIX');

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return {'success': false, 'error': 'Usuário não autenticado'};
      }

      final amountInCents = (amount * 100).round();
      final body = {
        'amount': amountInCents.toString(),
        'currency': currency!.toLowerCase(),
        'payment_method_types[]': 'pix',
        'description': description,
        'metadata[user_id]': userId,
        'metadata[service_id]': serviceId,
        'metadata[service_type]': serviceType,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents'),
        headers: _getHeaders(),
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final paymentIntentId = data['id'];

        // Confirmar para gerar QR Code PIX
        final confirmResponse = await http.post(
          Uri.parse('$_baseUrl/payment_intents/$paymentIntentId/confirm'),
          headers: _getHeaders(),
          body: {
            'payment_method_data[type]': 'pix',
            'return_url': 'https://oraculum.app/payment/return',
          },
        );

        if (confirmResponse.statusCode == 200) {
          final confirmedData = json.decode(confirmResponse.body);

          if (confirmedData['next_action']?['pix_display_qr_code'] != null) {
            final pixData = confirmedData['next_action']['pix_display_qr_code'];

            final paymentId = await _savePaymentRecord(
              userId: userId,
              amount: amount,
              description: description,
              serviceId: serviceId,
              serviceType: serviceType,
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

      return {'success': false, 'error': 'Não foi possível gerar QR Code PIX'};

    } catch (e) {
      debugPrint('❌ Erro ao criar pagamento PIX: $e');
      return {'success': false, 'error': 'Erro ao criar pagamento PIX: $e'};
    } finally {
      isLoading.value = false;
    }
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
        'paymentMethod': 'Stripe',
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

  /// Verificar status de um Payment Intent
  Future<Map<String, dynamic>> checkPaymentIntentStatus(String paymentIntentId) async {
    try {
      await _ensureValidToken();

      final response = await http.get(
        Uri.parse('$_baseUrl/payment_intents/$paymentIntentId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data, 'status': data['status']};
      } else {
        return {'success': false, 'error': 'Erro ao verificar status: ${response.body}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erro na requisição: $e'};
    }
  }

  /// Testar conectividade com Stripe
  Future<bool> testStripeConnection() async {
    try {
      debugPrint('🔄 Testando conexão com Stripe...');
      return await _authenticate();
    } catch (e) {
      debugPrint('❌ Erro ao testar conexão: $e');
      return false;
    }
  }

  // ===========================================
  // GETTERS
  // ===========================================
  String get publishableKey => _publishableKey;
  bool get isAuthenticated => _isTokenValid();
}