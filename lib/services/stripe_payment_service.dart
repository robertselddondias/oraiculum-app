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

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeStripe();
  }

  // ===========================================
  // INICIALIZAÇÃO DA SDK
  // ===========================================

  Future<void> _initializeStripe() async {
    try {
      debugPrint('🔄 Inicializando Flutter Stripe SDK...');

      Stripe.publishableKey = _publishableKey;
      Stripe.merchantIdentifier = 'merchant.com.oraculum.app';

      // Configurações adicionais
      await Stripe.instance.applySettings();

      debugPrint('✅ Flutter Stripe SDK inicializado com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar Stripe SDK: $e');
    }
  }

  // ===========================================
  // HEADERS PARA REQUISIÇÕES À API
  // ===========================================

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_secretKey',
    'Content-Type': 'application/x-www-form-urlencoded',
    'Stripe-Version': '2023-10-16',
  };

  // ===========================================
  // GESTÃO DE CLIENTES
  // ===========================================

  /// Criar ou obter cliente existente
  Future<String?> _getOrCreateCustomer({
    required String userId,
    required String email,
    String? name,
    String? phone,
  }) async {
    try {
      // Verificar se já existe um customer ID salvo
      final userData = await _firebaseService.getUserData(userId);
      final userDoc = userData.data() as Map<String, dynamic>?;

      if (userDoc?['stripeCustomerId'] != null) {
        return userDoc!['stripeCustomerId'];
      }

      // Criar novo customer
      final body = {
        'email': email,
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        'metadata[user_id]': userId,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/customers'),
        headers: _headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final customerId = data['id'];

        // Salvar customer ID no perfil do usuário
        await _firebaseService.updateUserData(userId, {
          'stripeCustomerId': customerId,
        });

        debugPrint('✅ Customer criado: $customerId');
        return customerId;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Erro ao criar/obter customer: $e');
      return null;
    }
  }

  // ===========================================
  // PAGAMENTO COM CARTÃO (NOVA COMPRA)
  // ===========================================

  /// Processar pagamento com cartão usando a tela nativa da SDK
  Future<Map<String, dynamic>> processCardPayment({
    required double amount,
    required String description,
    required String serviceId,
    required String serviceType,
    String? currency = 'brl',
    bool saveCard = true,
  }) async {
    try {
      isLoading.value = true;
      debugPrint('🔄 Iniciando pagamento com cartão');

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return {'success': false, 'error': 'Usuário não autenticado'};
      }

      final user = FirebaseAuth.instance.currentUser!;

      // 1. Obter ou criar customer
      final customerId = await _getOrCreateCustomer(
        userId: userId,
        email: user.email!,
        name: user.displayName,
      );

      if (customerId == null) {
        return {'success': false, 'error': 'Falha ao criar cliente'};
      }

      // 2. Criar Payment Intent
      final paymentIntentResult = await _createPaymentIntent(
        amount: amount,
        currency: currency!,
        customerId: saveCard ? customerId : null,
        description: description,
        serviceId: serviceId,
        serviceType: serviceType,
        userId: userId,
        setupFutureUsage: saveCard ? 'off_session' : null,
      );

      if (!paymentIntentResult['success']) {
        return paymentIntentResult;
      }

      final clientSecret = paymentIntentResult['client_secret'];
      final paymentIntentId = paymentIntentResult['payment_intent_id'];

      // 3. Inicializar Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Oraculum',
          customerId: customerId,
          customerEphemeralKeySecret: await _createEphemeralKey(customerId),
          allowsDelayedPaymentMethods: true,
          billingDetails: const BillingDetails(
            address: Address(
              country: 'BR',
            ),
          ),
          style: ThemeMode.system,
        ),
      );

      // 4. Apresentar Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // 5. Verificar resultado
      final paymentResult = await _checkPaymentIntentStatus(paymentIntentId);

      if (paymentResult['status'] == 'succeeded') {
        // Salvar transação no Firebase
        final transactionId = await _savePaymentTransaction(
          userId: userId,
          amount: amount,
          description: description,
          serviceId: serviceId,
          serviceType: serviceType,
          paymentIntentId: paymentIntentId,
          paymentMethod: 'card',
          status: 'succeeded',
        );

        // Adicionar créditos ao usuário
        await _addCreditsToUser(userId, amount);

        // Se foi salvo um cartão, adicionar aos salvos
        if (saveCard) {
          await _saveCardFromPaymentIntent(userId, customerId, paymentIntentId);
        }

        return {
          'success': true,
          'transaction_id': transactionId,
          'payment_intent_id': paymentIntentId,
        };
      }

      return {'success': false, 'error': 'Pagamento não foi completado'};

    } on StripeException catch (e) {
      debugPrint('❌ Erro Stripe: ${e.error.localizedMessage}');
      return {'success': false, 'error': e.error.localizedMessage ?? 'Erro no pagamento'};
    } catch (e) {
      debugPrint('❌ Erro geral: $e');
      return {'success': false, 'error': 'Erro inesperado: $e'};
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================
  // PAGAMENTO COM CARTÃO SALVO
  // ===========================================

  /// Processar pagamento com cartão salvo
  Future<Map<String, dynamic>> processPaymentWithSavedCard({
    required String paymentMethodId,
    required double amount,
    required String description,
    required String serviceId,
    required String serviceType,
    String? currency = 'brl',
  }) async {
    try {
      isLoading.value = true;
      debugPrint('🔄 Processando pagamento com cartão salvo');

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return {'success': false, 'error': 'Usuário não autenticado'};
      }

      // 1. Criar Payment Intent
      final paymentIntentResult = await _createPaymentIntent(
        amount: amount,
        currency: currency!,
        paymentMethodId: paymentMethodId,
        description: description,
        serviceId: serviceId,
        serviceType: serviceType,
        userId: userId,
      );

      if (!paymentIntentResult['success']) {
        return paymentIntentResult;
      }

      final paymentIntentId = paymentIntentResult['payment_intent_id'];

      // 2. Confirmar pagamento
      final confirmResult = await _confirmPaymentIntent(paymentIntentId);

      if (confirmResult['status'] == 'succeeded') {
        // Salvar transação
        final transactionId = await _savePaymentTransaction(
          userId: userId,
          amount: amount,
          description: description,
          serviceId: serviceId,
          serviceType: serviceType,
          paymentIntentId: paymentIntentId,
          paymentMethod: 'saved_card',
          status: 'succeeded',
        );

        // Adicionar créditos
        await _addCreditsToUser(userId, amount);

        return {
          'success': true,
          'transaction_id': transactionId,
          'payment_intent_id': paymentIntentId,
        };
      } else if (confirmResult['status'] == 'requires_action') {
        // Requer autenticação 3D Secure
        try {
          final paymentIntent = await Stripe.instance.handleNextAction(
            confirmResult['client_secret'],
          );

          if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
            // Pagamento bem-sucedido após autenticação
            final transactionId = await _savePaymentTransaction(
              userId: userId,
              amount: amount,
              description: description,
              serviceId: serviceId,
              serviceType: serviceType,
              paymentIntentId: paymentIntentId,
              paymentMethod: 'saved_card_3ds',
              status: 'succeeded',
            );

            await _addCreditsToUser(userId, amount);

            return {
              'success': true,
              'transaction_id': transactionId,
              'payment_intent_id': paymentIntentId,
            };
          }
        } catch (e) {
          return {'success': false, 'error': 'Falha na autenticação'};
        }
      }

      return {'success': false, 'error': 'Pagamento não foi aprovado'};

    } catch (e) {
      debugPrint('❌ Erro no pagamento com cartão salvo: $e');
      return {'success': false, 'error': 'Erro no pagamento: $e'};
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================
  // APPLE PAY
  // ===========================================

  /// Verificar se Apple Pay está disponível
  Future<bool> isApplePaySupported() async {
    try {
      return await Stripe.instance.isApplePaySupported();
    } catch (e) {
      return false;
    }
  }

  /// Processar pagamento com Apple Pay
  Future<Map<String, dynamic>> processApplePayPayment({
    required double amount,
    required String description,
    required String serviceId,
    required String serviceType,
    String? currency = 'brl',
  }) async {
    try {
      isLoading.value = true;
      debugPrint('🔄 Iniciando pagamento com Apple Pay');

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return {'success': false, 'error': 'Usuário não autenticado'};
      }

      // Verificar suporte
      if (!await isApplePaySupported()) {
        return {'success': false, 'error': 'Apple Pay não está disponível'};
      }

      // Criar Payment Intent
      final paymentIntentResult = await _createPaymentIntent(
        amount: amount,
        currency: currency!,
        description: description,
        serviceId: serviceId,
        serviceType: serviceType,
        userId: userId,
      );

      if (!paymentIntentResult['success']) {
        return paymentIntentResult;
      }

      final clientSecret = paymentIntentResult['client_secret'];
      final paymentIntentId = paymentIntentResult['payment_intent_id'];

      // Configurar Apple Pay
      await Stripe.instance.confirmApplePayPayment(
        clientSecret,
        const ApplePayParams(
          currencyCode: 'BRL',
          countryCode: 'BR',
          merchantDisplayName: 'Oraculum',
          merchantIdentifier: 'merchant.com.oraculum.app',
        ),
      );

      // Verificar resultado
      final paymentResult = await _checkPaymentIntentStatus(paymentIntentId);

      if (paymentResult['status'] == 'succeeded') {
        final transactionId = await _savePaymentTransaction(
          userId: userId,
          amount: amount,
          description: description,
          serviceId: serviceId,
          serviceType: serviceType,
          paymentIntentId: paymentIntentId,
          paymentMethod: 'apple_pay',
          status: 'succeeded',
        );

        await _addCreditsToUser(userId, amount);

        return {
          'success': true,
          'transaction_id': transactionId,
          'payment_intent_id': paymentIntentId,
        };
      }

      return {'success': false, 'error': 'Pagamento Apple Pay não foi completado'};

    } on StripeException catch (e) {
      debugPrint('❌ Erro Apple Pay: ${e.error.localizedMessage}');
      return {'success': false, 'error': e.error.localizedMessage ?? 'Erro no Apple Pay'};
    } catch (e) {
      debugPrint('❌ Erro geral Apple Pay: $e');
      return {'success': false, 'error': 'Erro no Apple Pay: $e'};
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================
  // GOOGLE PAY
  // ===========================================

  /// Verificar se Google Pay está disponível
  Future<bool> isGooglePaySupported() async {
    try {
      return await Stripe.instance.isGooglePaySupported(
        const IsGooglePaySupportedParams(),
      );
    } catch (e) {
      return false;
    }
  }

  /// Processar pagamento com Google Pay
  Future<Map<String, dynamic>> processGooglePayPayment({
    required double amount,
    required String description,
    required String serviceId,
    required String serviceType,
    String? currency = 'brl',
  }) async {
    try {
      isLoading.value = true;
      debugPrint('🔄 Iniciando pagamento com Google Pay');

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return {'success': false, 'error': 'Usuário não autenticado'};
      }

      // Verificar suporte
      if (!await isGooglePaySupported()) {
        return {'success': false, 'error': 'Google Pay não está disponível'};
      }

      // Criar Payment Intent
      final paymentIntentResult = await _createPaymentIntent(
        amount: amount,
        currency: currency!,
        description: description,
        serviceId: serviceId,
        serviceType: serviceType,
        userId: userId,
      );

      if (!paymentIntentResult['success']) {
        return paymentIntentResult;
      }

      final clientSecret = paymentIntentResult['client_secret'];
      final paymentIntentId = paymentIntentResult['payment_intent_id'];

      // Inicializar Google Pay
      await Stripe.instance.initGooglePay(
        GooglePayInitParams(
          testEnv: true, // Mudar para false em produção
          merchantName: 'Oraculum',
          countryCode: 'BR',
          currencyCode: 'BRL',
        ),
      );

      // Apresentar Google Pay
      await Stripe.instance.presentGooglePay(
        PresentGooglePayParams(
          clientSecret: clientSecret,
          forSetupIntent: false,
        ),
      );

      // Verificar resultado
      final paymentResult = await _checkPaymentIntentStatus(paymentIntentId);

      if (paymentResult['status'] == 'succeeded') {
        final transactionId = await _savePaymentTransaction(
          userId: userId,
          amount: amount,
          description: description,
          serviceId: serviceId,
          serviceType: serviceType,
          paymentIntentId: paymentIntentId,
          paymentMethod: 'google_pay',
          status: 'succeeded',
        );

        await _addCreditsToUser(userId, amount);

        return {
          'success': true,
          'transaction_id': transactionId,
          'payment_intent_id': paymentIntentId,
        };
      }

      return {'success': false, 'error': 'Pagamento Google Pay não foi completado'};

    } on StripeException catch (e) {
      debugPrint('❌ Erro Google Pay: ${e.error.localizedMessage}');
      return {'success': false, 'error': e.error.localizedMessage ?? 'Erro no Google Pay'};
    } catch (e) {
      debugPrint('❌ Erro geral Google Pay: $e');
      return {'success': false, 'error': 'Erro no Google Pay: $e'};
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================
  // PIX (VIA STRIPE)
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

          String? pixQrCode;
          if (confirmedData['next_action']?['pix_display_qr_code'] != null) {
            pixQrCode = confirmedData['next_action']['pix_display_qr_code']['data'];
          }

          // Salvar transação como pendente
          final transactionId = await _savePaymentTransaction(
            userId: userId,
            amount: amount,
            description: description,
            serviceId: serviceId,
            serviceType: serviceType,
            paymentIntentId: paymentIntentId,
            paymentMethod: 'pix',
            status: 'pending',
            additionalData: {
              'pixQrCode': pixQrCode,
              'expiresAt': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
            },
          );

          return {
            'success': true,
            'transaction_id': transactionId,
            'payment_intent_id': paymentIntentId,
            'pix_qr_code': pixQrCode,
          };
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
  // GESTÃO DE CARTÕES SALVOS
  // ===========================================

  /// Obter cartões salvos do usuário
  Future<List<Map<String, dynamic>>> getSavedCards(String userId) async {
    try {
      final cardsSnapshot = await _firebaseService.firestore
          .collection('user_payment_methods')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'card')
          .get();

      return cardsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar cartões salvos: $e');
      return [];
    }
  }

  /// Remover cartão salvo
  Future<bool> removeCard(String userId, String cardId) async {
    try {
      // Remover do Stripe
      await http.post(
        Uri.parse('$_baseUrl/payment_methods/$cardId/detach'),
        headers: _headers,
      );

      // Remover do Firebase
      await _firebaseService.firestore
          .collection('user_payment_methods')
          .doc(cardId)
          .delete();

      return true;
    } catch (e) {
      debugPrint('❌ Erro ao remover cartão: $e');
      return false;
    }
  }

  // ===========================================
  // MÉTODOS AUXILIARES DA API
  // ===========================================

  /// Criar Payment Intent
  Future<Map<String, dynamic>> _createPaymentIntent({
    required double amount,
    required String currency,
    required String description,
    required String serviceId,
    required String serviceType,
    required String userId,
    String? customerId,
    String? paymentMethodId,
    String? setupFutureUsage,
  }) async {
    try {
      final amountInCents = (amount * 100).round();
      final body = {
        'amount': amountInCents.toString(),
        'currency': currency.toLowerCase(),
        'description': description,
        'metadata[user_id]': userId,
        'metadata[service_id]': serviceId,
        'metadata[service_type]': serviceType,
        if (customerId != null) 'customer': customerId,
        if (paymentMethodId != null) 'payment_method': paymentMethodId,
        if (setupFutureUsage != null) 'setup_future_usage': setupFutureUsage,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents'),
        headers: _headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'payment_intent_id': data['id'],
          'client_secret': data['client_secret'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {'success': false, 'error': errorData['error']['message']};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erro ao criar Payment Intent: $e'};
    }
  }

  /// Confirmar Payment Intent
  Future<Map<String, dynamic>> _confirmPaymentIntent(String paymentIntentId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents/$paymentIntentId/confirm'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'status': data['status'],
          'client_secret': data['client_secret'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {'success': false, 'error': errorData['error']['message']};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erro ao confirmar Payment Intent: $e'};
    }
  }

  /// Verificar status do Payment Intent
  Future<Map<String, dynamic>> _checkPaymentIntentStatus(String paymentIntentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payment_intents/$paymentIntentId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'status': data['status'],
          'data': data,
        };
      }

      return {'success': false, 'error': 'Erro ao verificar status'};
    } catch (e) {
      return {'success': false, 'error': 'Erro na verificação: $e'};
    }
  }

  /// Criar Ephemeral Key para customer
  Future<String?> _createEphemeralKey(String customerId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ephemeral_keys'),
        headers: {
          ..._headers,
          'Stripe-Version': '2023-10-16',
        },
        body: {'customer': customerId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['secret'];
      }

      return null;
    } catch (e) {
      debugPrint('❌ Erro ao criar ephemeral key: $e');
      return null;
    }
  }

  // ===========================================
  // MÉTODOS AUXILIARES DO FIREBASE
  // ===========================================

  /// Salvar transação no Firebase
  Future<String> _savePaymentTransaction({
    required String userId,
    required double amount,
    required String description,
    required String serviceId,
    required String serviceType,
    required String paymentIntentId,
    required String paymentMethod,
    required String status,
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
        'stripePaymentIntentId': paymentIntentId,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
        if (additionalData != null) 'additionalData': additionalData,
      };

      final docRef = await _firebaseService.firestore
          .collection('payments')
          .add(transactionData);

      debugPrint('✅ Transação salva: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Erro ao salvar transação: $e');
      throw Exception('Erro ao salvar transação: $e');
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

      debugPrint('✅ Créditos atualizados: +R\$ ${amount.toStringAsFixed(2)}');
    } catch (e) {
      debugPrint('❌ Erro ao adicionar créditos: $e');
    }
  }

  /// Salvar cartão do Payment Intent
  Future<void> _saveCardFromPaymentIntent(String userId, String customerId, String paymentIntentId) async {
    try {
      // Buscar Payment Intent para obter o Payment Method
      final paymentIntentData = await _checkPaymentIntentStatus(paymentIntentId);

      if (paymentIntentData['success']) {
        final paymentMethodId = paymentIntentData['data']['payment_method'];

        if (paymentMethodId != null) {
          // Buscar detalhes do Payment Method
          final pmResponse = await http.get(
            Uri.parse('$_baseUrl/payment_methods/$paymentMethodId'),
            headers: _headers,
          );

          if