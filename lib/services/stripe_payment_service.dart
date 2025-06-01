import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:oraculum/services/firebase_service.dart';

class StripePaymentService extends GetxService {
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

  Future<void> _initializeStripe() async {
    try {
      debugPrint('🔄 Inicializando Flutter Stripe SDK...');
      Stripe.publishableKey = _publishableKey;
      Stripe.merchantIdentifier = 'merchant.com.oraculum.app';
      await Stripe.instance.applySettings();
      debugPrint('✅ Flutter Stripe SDK inicializado com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar Stripe SDK: $e');
    }
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_secretKey',
    'Content-Type': 'application/x-www-form-urlencoded',
    'Stripe-Version': '2023-10-16',
  };

  Future<String?> _getOrCreateCustomer({
    required String userId,
    required String email,
    String? name,
    String? phone,
  }) async {
    try {
      final userData = await _firebaseService.getUserData(userId);
      final userDoc = userData.data() as Map<String, dynamic>?;

      if (userDoc?['stripeCustomerId'] != null) {
        return userDoc!['stripeCustomerId'];
      }

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

  Future<Map<String, dynamic>> processCardPayment({
    required double amount,
    required int bonus,
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

      final customerId = await _getOrCreateCustomer(
        userId: userId,
        email: user.email!,
        name: user.displayName,
      );

      if (customerId == null) {
        return {'success': false, 'error': 'Falha ao criar cliente'};
      }

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
              line2: '',
              line1: '',
              state: '',
              postalCode: '',
              city: ''
            ),
          ),
          style: ThemeMode.system,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final paymentResult = await _checkPaymentIntentStatus(paymentIntentId);

      if (paymentResult['status'] == 'succeeded') {
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

        await _addCreditsToUser(userId, amount, bonus);

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

  Future<Map<String, dynamic>> processPaymentWithSavedCard({
    required String paymentMethodId,
    required double amount,
    required int bonus,
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

      final confirmResult = await _confirmPaymentIntent(paymentIntentId);

      if (confirmResult['status'] == 'succeeded') {
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

        await _addCreditsToUser(userId, amount, bonus);

        return {
          'success': true,
          'transaction_id': transactionId,
          'payment_intent_id': paymentIntentId,
        };
      } else if (confirmResult['status'] == 'requires_action') {
        try {
          final paymentIntent = await Stripe.instance.handleNextAction(
            confirmResult['client_secret'],
          );

          if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
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

            await _addCreditsToUser(userId, amount, bonus);

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

  Future<bool> isApplePaySupported() async {
    try {
      return true;//await Stripe.instance.isApplePaySupported();
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> processApplePayPayment({
    required double amount,
    required int bonus,
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

      if (!await isApplePaySupported()) {
        return {'success': false, 'error': 'Apple Pay não está disponível'};
      }

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

      // await Stripe.instance.confirmApplePayPayment(
      //   clientSecret,
      //   const ApplePayParams(
      //     currencyCode: 'BRL',
      //     merchantCountryCode: 'BR',
      //     cartItems: [],
      //   ),
      // );

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

        await _addCreditsToUser(userId, amount, bonus);

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

  Future<bool> isGooglePaySupported() async {
    try {
      return await Stripe.instance.isGooglePaySupported(
        const IsGooglePaySupportedParams(),
      );
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> processGooglePayPayment({
    required double amount,
    required int bonus,
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

      if (!await isGooglePaySupported()) {
        return {'success': false, 'error': 'Google Pay não está disponível'};
      }

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

      await Stripe.instance.initGooglePay(
        const GooglePayInitParams(
          testEnv: true,
          merchantName: 'Oraculum',
          countryCode: 'BR',
        ),
      );

      await Stripe.instance.presentGooglePay(
        PresentGooglePayParams(
          clientSecret: clientSecret,
          forSetupIntent: false,
        ),
      );

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

        await _addCreditsToUser(userId, amount, bonus);

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

  Future<Map<String, dynamic>> setupCardForFutureUse() async {
    try {
      isLoading.value = true;
      debugPrint('🔄 Configurando cartão para uso futuro');

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return {'success': false, 'error': 'Usuário não autenticado'};
      }

      final user = FirebaseAuth.instance.currentUser!;

      final customerId = await _getOrCreateCustomer(
        userId: userId,
        email: user.email!,
        name: user.displayName,
      );

      if (customerId == null) {
        return {'success': false, 'error': 'Falha ao criar cliente'};
      }

      final setupIntentResult = await _createSetupIntent(
        customerId: customerId,
        userId: userId,
      );

      if (!setupIntentResult['success']) {
        return setupIntentResult;
      }

      final clientSecret = setupIntentResult['client_secret'];
      final setupIntentId = setupIntentResult['setup_intent_id'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: clientSecret,
          merchantDisplayName: 'Oraculum',
          customerId: customerId,
          customerEphemeralKeySecret: await _createEphemeralKey(customerId),
          billingDetails: const BillingDetails(
            address: Address(
              country: 'BR',
              city: 'SP',
              postalCode: '03334-040',
              line1: 'Endereco teste',
              state: 'SP',
              line2: ''
            ),
          ),
          style: ThemeMode.system,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final setupResult = await _checkSetupIntentStatus(setupIntentId);

      if (setupResult['status'] == 'succeeded') {
        await _saveCardFromSetupIntent(userId, customerId, setupIntentId);

        return {
          'success': true,
          'setup_intent_id': setupIntentId,
        };
      }

      return {'success': false, 'error': 'Não foi possível adicionar o cartão'};

    } on StripeException catch (e) {
      debugPrint('❌ Erro Stripe Setup: ${e.error.localizedMessage}');
      return {'success': false, 'error': e.error.localizedMessage ?? 'Erro ao adicionar cartão'};
    } catch (e) {
      debugPrint('❌ Erro geral Setup: $e');
      return {'success': false, 'error': 'Erro inesperado: $e'};
    } finally {
      isLoading.value = false;
    }
  }

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
          'stripePaymentMethodId': data['stripePaymentMethodId'],
          'last4': data['last4'],
          'brand': data['brand'],
          'expMonth': data['expMonth'],
          'expYear': data['expYear'],
          'isDefault': data['isDefault'] ?? false,
          'cardHolderName': data['cardHolderName'],
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar cartões salvos: $e');
      return [];
    }
  }

  Future<bool> removeCard(String userId, String cardId) async {
    try {
      final cardDoc = await _firebaseService.firestore
          .collection('user_payment_methods')
          .doc(cardId)
          .get();

      if (!cardDoc.exists) {
        return false;
      }

      final cardData = cardDoc.data() as Map<String, dynamic>;
      final stripePaymentMethodId = cardData['stripePaymentMethodId'];

      await http.post(
        Uri.parse('$_baseUrl/payment_methods/$stripePaymentMethodId/detach'),
        headers: _headers,
      );

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

  Future<Map<String, dynamic>> _createSetupIntent({
    required String customerId,
    required String userId,
  }) async {
    try {
      final body = {
        'customer': customerId,
        'usage': 'off_session',
        'metadata[user_id]': userId,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/setup_intents'),
        headers: _headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'setup_intent_id': data['id'],
          'client_secret': data['client_secret'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {'success': false, 'error': errorData['error']['message']};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erro ao criar Setup Intent: $e'};
    }
  }

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

  Future<Map<String, dynamic>> _checkSetupIntentStatus(String setupIntentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/setup_intents/$setupIntentId'),
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

      return {'success': false, 'error': 'Erro ao verificar status do setup'};
    } catch (e) {
      return {'success': false, 'error': 'Erro na verificação do setup: $e'};
    }
  }

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

  Future<void> _addCreditsToUser(String userId, double amount, int bonus) async {
    try {
      final userDoc = await _firebaseService.firestore
          .collection('users')
          .doc(userId)
          .get();

      final currentCredits = (userDoc.data()?['credits'] ?? 0.0) as num;

      if (bonus > 0) {
        amount = amount + (amount * bonus / 100);
      }

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

  Future<void> _saveCardFromPaymentIntent(String userId, String customerId, String paymentIntentId) async {
    try {
      final paymentIntentData = await _checkPaymentIntentStatus(paymentIntentId);

      if (paymentIntentData['success']) {
        final paymentMethodId = paymentIntentData['data']['payment_method'];

        if (paymentMethodId != null) {
          final pmResponse = await http.get(
            Uri.parse('$_baseUrl/payment_methods/$paymentMethodId'),
            headers: _headers,
          );

          if (pmResponse.statusCode == 200) {
            final pmData = json.decode(pmResponse.body);
            final cardData = pmData['card'];

            await _firebaseService.firestore
                .collection('user_payment_methods')
                .add({
              'userId': userId,
              'customerId': customerId,
              'stripePaymentMethodId': paymentMethodId,
              'type': 'card',
              'brand': cardData['brand'],
              'last4': cardData['last4'],
              'expMonth': cardData['exp_month'],
              'expYear': cardData['exp_year'],
              'cardHolderName': cardData['holder_name'] ?? '',
              'isDefault': false,
              'createdAt': FieldValue.serverTimestamp(),
            });

            debugPrint('✅ Cartão salvo do Payment Intent');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar cartão do Payment Intent: $e');
    }
  }

  Future<void> _saveCardFromSetupIntent(String userId, String customerId, String setupIntentId) async {
    try {
      final setupIntentData = await _checkSetupIntentStatus(setupIntentId);

      if (setupIntentData['success']) {
        final paymentMethodId = setupIntentData['data']['payment_method'];

        if (paymentMethodId != null) {
          final pmResponse = await http.get(
            Uri.parse('$_baseUrl/payment_methods/$paymentMethodId'),
            headers: _headers,
          );

          if (pmResponse.statusCode == 200) {
            final pmData = json.decode(pmResponse.body);
            final cardData = pmData['card'];

            final existingCards = await getSavedCards(userId);
            final isFirstCard = existingCards.isEmpty;

            await _firebaseService.firestore
                .collection('user_payment_methods')
                .add({
              'userId': userId,
              'customerId': customerId,
              'stripePaymentMethodId': paymentMethodId,
              'type': 'card',
              'brand': cardData['brand'],
              'last4': cardData['last4'],
              'expMonth': cardData['exp_month'],
              'expYear': cardData['exp_year'],
              'cardHolderName': cardData['holder_name'] ?? '',
              'isDefault': isFirstCard,
              'createdAt': FieldValue.serverTimestamp(),
            });

            debugPrint('✅ Cartão salvo do Setup Intent');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar cartão do Setup Intent: $e');
    }
  }

  Future<Map<String, bool>> checkAvailableFeatures() async {
    try {
      final features = <String, bool>{};

      // features['apple_pay'] = await isApplePaySupported();
      // features['google_pay'] = await isGooglePaySupported();
      features['card_payments'] = true;
      features['pix'] = true;
      features['save_cards'] = true;

      return features;
    } catch (e) {
      debugPrint('❌ Erro ao verificar recursos: $e');
      return {
        'card_payments': true,
        'pix': true,
        'save_cards': true,
      };
    }
  }

  String detectCardBrand(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (cleanNumber.isEmpty) return '';

    if (cleanNumber.startsWith('4')) {
      return 'visa';
    }

    if (cleanNumber.startsWith(RegExp(r'^5[1-5]')) ||
        cleanNumber.startsWith(RegExp(r'^2[2-7]'))) {
      return 'mastercard';
    }

    if (cleanNumber.startsWith(RegExp(r'^3[47]'))) {
      return 'amex';
    }

    if (cleanNumber.startsWith(RegExp(r'^3[0689]'))) {
      return 'diners';
    }

    if (cleanNumber.startsWith('6011') ||
        cleanNumber.startsWith(RegExp(r'^65'))) {
      return 'discover';
    }

    if (cleanNumber.startsWith(RegExp(r'^(4011|4312|4389|4514|4573|6362|6363)'))) {
      return 'elo';
    }

    return 'unknown';
  }

  Future<Map<String, dynamic>> getPaymentStats(String userId) async {
    try {
      final paymentsSnapshot = await _firebaseService.firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .get();

      final payments = paymentsSnapshot.docs.map((doc) => doc.data()).toList();

      double totalAmount = 0;
      int successfulPayments = 0;
      int failedPayments = 0;
      final methodCounts = <String, int>{};

      for (final payment in payments) {
        final amount = (payment['amount'] ?? 0.0) as num;
        final status = payment['status'] as String? ?? '';
        final method = payment['paymentMethod'] as String? ?? '';

        totalAmount += amount.toDouble();

        if (status == 'succeeded') {
          successfulPayments++;
        } else {
          failedPayments++;
        }

        methodCounts[method] = (methodCounts[method] ?? 0) + 1;
      }

      return {
        'totalAmount': totalAmount,
        'totalTransactions': payments.length,
        'successfulPayments': successfulPayments,
        'failedPayments': failedPayments,
        'successRate': payments.isNotEmpty
            ? (successfulPayments / payments.length) * 100
            : 0.0,
        'methodCounts': methodCounts,
      };
    } catch (e) {
      debugPrint('❌ Erro ao obter estatísticas: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> generateTransactionReport({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _firebaseService.firestore
          .collection('payments')
          .where('userId', isEqualTo: userId);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot = await query.get();
      final transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      return {
        'transactions': transactions,
        'period': {
          'start': startDate?.toIso8601String(),
          'end': endDate?.toIso8601String(),
        },
        'summary': await getPaymentStats(userId),
      };
    } catch (e) {
      debugPrint('❌ Erro ao gerar relatório: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getUserPaymentSettings(String userId) async {
    try {
      final settingsDoc = await _firebaseService.firestore
          .collection('user_payment_settings')
          .doc(userId)
          .get();

      if (settingsDoc.exists) {
        return settingsDoc.data() as Map<String, dynamic>;
      }

      return {
        'defaultPaymentMethod': null,
        'saveCards': true,
        'notifications': {
          'paymentSuccess': true,
          'paymentFailed': true,
          'lowCredits': true,
        },
        'autoRecharge': false,
        'autoRechargeThreshold': 10.0,
        'autoRechargeAmount': 50.0,
      };
    } catch (e) {
      debugPrint('❌ Erro ao obter configurações: $e');
      return {};
    }
  }

  Future<bool> updateUserPaymentSettings(String userId, Map<String, dynamic> settings) async {
    try {
      await _firebaseService.firestore
          .collection('user_payment_settings')
          .doc(userId)
          .set(settings, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('❌ Erro ao atualizar configurações: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> checkExpiringCards(String userId) async {
    try {
      final cards = await getSavedCards(userId);
      final expiringCards = <Map<String, dynamic>>[];
      final now = DateTime.now();
      final threeMonthsFromNow = now.add(const Duration(days: 90));

      for (final card in cards) {
        final expMonth = card['expMonth'] as int;
        final expYear = card['expYear'] as int;
        final cardExpiry = DateTime(expYear, expMonth + 1, 0);

        if (cardExpiry.isBefore(threeMonthsFromNow)) {
          expiringCards.add({
            ...card,
            'expiryDate': cardExpiry,
            'daysUntilExpiry': cardExpiry.difference(now).inDays,
          });
        }
      }

      return expiringCards;
    } catch (e) {
      debugPrint('❌ Erro ao verificar cartões expirando: $e');
      return [];
    }
  }

  Future<void> processWebhook(Map<String, dynamic> event) async {
    try {
      final eventType = event['type'] as String;
      final eventData = event['data']['object'] as Map<String, dynamic>;

      switch (eventType) {
        case 'payment_intent.succeeded':
          await _handlePaymentIntentSucceeded(eventData);
          break;
        case 'payment_intent.payment_failed':
          await _handlePaymentIntentFailed(eventData);
          break;
        case 'payment_method.attached':
          await _handlePaymentMethodAttached(eventData);
          break;
        case 'customer.subscription.created':
          await _handleSubscriptionCreated(eventData);
          break;
        default:
          debugPrint('⚠️ Evento não tratado: $eventType');
      }
    } catch (e) {
      debugPrint('❌ Erro ao processar webhook: $e');
    }
  }

  Future<void> _handlePaymentIntentSucceeded(Map<String, dynamic> data) async {
    try {
      final paymentIntentId = data['id'];
      final userId = data['metadata']?['user_id'];

      if (userId != null) {
        final paymentsSnapshot = await _firebaseService.firestore
            .collection('payments')
            .where('stripePaymentIntentId', isEqualTo: paymentIntentId)
            .limit(1)
            .get();

        if (paymentsSnapshot.docs.isNotEmpty) {
          await paymentsSnapshot.docs.first.reference.update({
            'status': 'succeeded',
            'completedAt': FieldValue.serverTimestamp(),
          });
        }

        debugPrint('✅ Payment Intent succeeded processado: $paymentIntentId');
      }
    } catch (e) {
      debugPrint('❌ Erro ao tratar Payment Intent succeeded: $e');
    }
  }

  Future<void> _handlePaymentIntentFailed(Map<String, dynamic> data) async {
    try {
      final paymentIntentId = data['id'];
      final userId = data['metadata']?['user_id'];

      if (userId != null) {
        final paymentsSnapshot = await _firebaseService.firestore
            .collection('payments')
            .where('stripePaymentIntentId', isEqualTo: paymentIntentId)
            .limit(1)
            .get();

        if (paymentsSnapshot.docs.isNotEmpty) {
          await paymentsSnapshot.docs.first.reference.update({
            'status': 'failed',
            'failedAt': FieldValue.serverTimestamp(),
            'failureReason': data['last_payment_error']?['message'],
          });
        }

        debugPrint('✅ Payment Intent failed processado: $paymentIntentId');
      }
    } catch (e) {
      debugPrint('❌ Erro ao tratar Payment Intent failed: $e');
    }
  }

  Future<void> _handlePaymentMethodAttached(Map<String, dynamic> data) async {
    try {
      final customerId = data['customer'];
      debugPrint('✅ Payment Method attached para customer: $customerId');
    } catch (e) {
      debugPrint('❌ Erro ao tratar Payment Method attached: $e');
    }
  }

  Future<void> _handleSubscriptionCreated(Map<String, dynamic> data) async {
    try {
      final subscriptionId = data['id'];
      final customerId = data['customer'];
      debugPrint('✅ Subscription created: $subscriptionId para customer: $customerId');
    } catch (e) {
      debugPrint('❌ Erro ao tratar Subscription created: $e');
    }
  }

  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/balance'),
        headers: _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Erro no teste de conexão: $e');
      return false;
    }
  }

  Future<void> clearTestData(String userId) async {
    try {
      final paymentsSnapshot = await _firebaseService.firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .where('stripePaymentIntentId', arrayContains: 'pi_test_')
          .get();

      for (final doc in paymentsSnapshot.docs) {
        await doc.reference.delete();
      }

      final cardsSnapshot = await _firebaseService.firestore
          .collection('user_payment_methods')
          .where('userId', isEqualTo: userId)
          .where('stripePaymentMethodId', arrayContains: 'pm_test_')
          .get();

      for (final doc in cardsSnapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('✅ Dados de teste limpos para usuário: $userId');
    } catch (e) {
      debugPrint('❌ Erro ao limpar dados de teste: $e');
    }
  }

  Future<Map<String, dynamic>> getAccountInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/account'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': {
            'id': data['id'],
            'display_name': data['display_name'],
            'country': data['country'],
            'default_currency': data['default_currency'],
            'charges_enabled': data['charges_enabled'],
            'payouts_enabled': data['payouts_enabled'],
          }
        };
      }

      return {'success': false, 'error': 'Falha ao obter informações da conta'};
    } catch (e) {
      debugPrint('❌ Erro ao obter informações da conta: $e');
      return {'success': false, 'error': 'Erro: $e'};
    }
  }

  bool validateCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }

    int sum = 0;
    bool alternate = false;

    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  bool validateExpiryDate(String expiry) {
    if (expiry.length != 5 || !expiry.contains('/')) {
      return false;
    }

    final parts = expiry.split('/');
    if (parts.length != 2) {
      return false;
    }

    final month = int.tryParse(parts[0]);
    final year = int.tryParse('20${parts[1]}');

    if (month == null || year == null || month < 1 || month > 12) {
      return false;
    }

    final now = DateTime.now();
    final cardDate = DateTime(year, month);

    return cardDate.isAfter(DateTime(now.year, now.month));
  }

  bool validateCVV(String cvv, String cardBrand) {
    final requiredLength = cardBrand == 'amex' ? 4 : 3;
    return cvv.length == requiredLength && RegExp(r'^\d+').hasMatch(cvv);
  }

  String formatCardNumber(String input) {
    final cleanInput = input.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < cleanInput.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleanInput[i]);
    }

    return buffer.toString();
  }

  Widget getCardBrandIcon(String brand, {double size = 24}) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Container(
          width: size * 1.5,
          height: size,
          decoration: BoxDecoration(
            color: Colors.blue.shade800,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              'VISA',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      case 'mastercard':
        return SizedBox(
          width: size * 1.5,
          height: size,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: Container(
                  width: size * 0.6,
                  height: size * 0.6,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: Container(
                  width: size * 0.6,
                  height: size * 0.6,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      case 'amex':
        return Container(
          width: size * 1.5,
          height: size,
          decoration: BoxDecoration(
            color: Colors.blue.shade900,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              'AMEX',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.35,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      case 'elo':
        return Container(
          width: size * 1.5,
          height: size,
          decoration: BoxDecoration(
            color: Colors.yellow.shade700,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              'ELO',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      default:
        return Icon(
          Icons.credit_card,
          size: size,
          color: Colors.grey,
        );
    }
  }

  Color getCardBrandColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Colors.blue.shade800;
      case 'mastercard':
        return Colors.red.shade700;
      case 'amex':
        return Colors.blue.shade900;
      case 'elo':
        return Colors.yellow.shade700;
      case 'diners':
        return Colors.grey.shade700;
      case 'discover':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  int convertToCents(double amount) {
    return (amount * 100).round();
  }

  double convertFromCents(int cents) {
    return cents / 100.0;
  }

  String formatCurrency(double amount, {String currency = 'BRL'}) {
    switch (currency.toUpperCase()) {
      case 'BRL':
        return 'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
      case 'USD':
        return '\${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      default:
        return '${amount.toStringAsFixed(2)} $currency';
    }
  }

  String generateTransactionId() {
    return 'txn_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (999 * (DateTime.now().microsecond / 1000000))).round()}';
  }

  bool get isTestEnvironment => _secretKey.contains('test');

  String get webhookUrl => 'https://your-backend.com/stripe/webhook';

  void logPaymentAttempt({
    required String method,
    required double amount,
    required String userId,
    String? error,
  }) {
    final logData = {
      'timestamp': DateTime.now().toIso8601String(),
      'method': method,
      'amount': amount,
      'userId': userId,
      'success': error == null,
      if (error != null) 'error': error,
    };

    debugPrint('💳 Payment Log: ${json.encode(logData)}');
  }

  void dispose() {
    debugPrint('🧹 StripePaymentService disposed');
  }
}