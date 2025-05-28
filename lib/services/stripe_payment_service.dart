import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:oraculum/services/firebase_service.dart';

class StripePaymentService extends GetxService {
  // Chaves da Stripe (substitua pelas suas chaves)
  static const String _publishableKey = 'pk_test_51RTpqm4TyzboYffk5IRBTmwEqPvKtBftyepU82rkCK5j0Bh6TYJ7Ld6e9lqvxoJoNe1xefeE58iFS2Igwvsfnc5q00R2Aztn0o'; // Sua chave pública
  static const String _secretKey = 'sk_test_51RTpqm4TyzboYffkLCT1uIvlITbGX3vgRC6rNnduYStBy2wg99c4DxrraH75S4ATZiPEOdk3KxsYlR8fVQ661CkV00r5Yt8XgO'; // Sua chave secreta
  static const String _baseUrl = 'https://api.stripe.com/v1';

  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final RxBool isLoading = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    // Inicializar Stripe
    Stripe.publishableKey = _publishableKey;
    await Stripe.instance.applySettings();
  }

  // Headers para requisições à API da Stripe
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_secretKey',
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  // 1. PAGAMENTO COM CARTÃO DE CRÉDITO/DÉBITO

  /// Criar Payment Intent para cartão
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    String? customerId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final amountInCents = (amount * 100).round();

      final body = {
        'amount': amountInCents.toString(),
        'currency': currency.toLowerCase(),
        'payment_method_types[]': 'card',
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

  /// Processar pagamento com cartão
  Future<Map<String, dynamic>> processCardPayment({
    required BuildContext context,
    required double amount,
    required String description,
    required String serviceId,
    required String serviceType,
    String? currency = 'brl',
    bool saveCard = false,
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

      // 2. Apresentar sheet de pagamento
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Oraculum',
          style: ThemeMode.system,
          billingDetails: BillingDetails(
            email: FirebaseAuth.instance.currentUser?.email,
          ),
          allowsDelayedPaymentMethods: false,
        ),
      );

      // 3. Apresentar o Payment Sheet
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
      String errorMessage = 'Erro no pagamento';

      switch (e.error.code) {
        case FailureCode.Canceled:
          errorMessage = 'Pagamento cancelado pelo usuário';
          break;
        case FailureCode.Failed:
          errorMessage = 'Pagamento falhou';
          break;
        case FailureCode.Timeout:
          errorMessage = 'Timeout na operação';
          break;
        default:
          errorMessage = e.error.localizedMessage ?? 'Erro desconhecido';
      }

      return {
        'success': false,
        'error': errorMessage,
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

  // 2. PAGAMENTO COM PIX (via Stripe)

  /// Criar pagamento PIX usando Stripe (disponível no Brasil)
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

      final amountInCents = (amount * 100).round();

      // Criar Payment Intent para PIX
      final body = {
        'amount': amountInCents.toString(),
        'currency': currency!.toLowerCase(),
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

      if (response.statusCode != 200) {
        return {
          'success': false,
          'error': 'Erro ao criar pagamento PIX: ${response.body}',
        };
      }

      final paymentIntentData = json.decode(response.body);
      final paymentIntentId = paymentIntentData['id'];
      final clientSecret = paymentIntentData['client_secret'];

      // Confirmar o Payment Intent para gerar o código PIX
      final confirmResponse = await http.post(
        Uri.parse('$_baseUrl/payment_intents/$paymentIntentId/confirm'),
        headers: _headers,
        body: {
          'payment_method_data[type]': 'pix',
        },
      );

      if (confirmResponse.statusCode != 200) {
        return {
          'success': false,
          'error': 'Erro ao confirmar pagamento PIX: ${confirmResponse.body}',
        };
      }

      final confirmedData = json.decode(confirmResponse.body);
      final pixData = confirmedData['next_action']['pix_display_qr_code'];

      // Salvar registro de pagamento como pendente
      final paymentId = await _savePaymentRecord(
        userId: userId,
        amount: amount,
        description: description,
        serviceId: serviceId,
        serviceType: serviceType,
        paymentMethod: 'pix',
        stripePaymentIntentId: paymentIntentId,
        status: 'pending',
        pixData: pixData,
      );

      // Mostrar QR Code para o usuário
      await _showPixQrCodeDialog(
        qrCodeData: pixData['data'],
        amount: amount,
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      // Iniciar monitoramento do pagamento PIX
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

  /// Mostrar diálogo com QR Code do PIX
  Future<void> _showPixQrCodeDialog({
    required String qrCodeData,
    required double amount,
    required DateTime expiresAt,
  }) async {
    await Get.dialog(
      AlertDialog(
        title: const Text('Pagamento PIX'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escaneie o código QR abaixo ou copie o código PIX:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Container para o QR Code (você pode usar um package como qr_flutter)
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.qr_code_2,
                    size: 150,
                    color: Colors.deepPurple,
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
              Text(
                'Válido até: ${_formatDateTime(expiresAt)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 20),

              // Código PIX para copiar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Código PIX:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            qrCodeData.length > 50
                                ? '${qrCodeData.substring(0, 50)}...'
                                : qrCodeData,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            // Implementar cópia para clipboard
                            Get.snackbar(
                              'Copiado',
                              'Código PIX copiado para área de transferência',
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );
                          },
                        ),
                      ],
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
            child: const Text('Fechar'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Monitorar status do pagamento PIX
  void _monitorPixPayment(String paymentIntentId, String localPaymentId) {
    // Implementar polling ou webhook para verificar status
    // Por simplicidade, vamos simular uma verificação periódica
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      final status = await _checkPaymentStatus(paymentIntentId);

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
            final amount = paymentDoc.data()!['amount'] as double;
            await _addCreditsToUser(userId, amount);
          }
        }

        Get.snackbar(
          'Pagamento Confirmado',
          'Seu pagamento PIX foi confirmado e os créditos foram adicionados!',
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

      // Parar após 30 minutos (180 tentativas de 10 segundos)
      if (timer.tick > 180) {
        timer.cancel();
      }
    });
  }

  // 3. GERENCIAMENTO DE CLIENTES

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

  /// Salvar método de pagamento para uso futuro
  Future<Map<String, dynamic>> savePaymentMethod({
    required String customerId,
    required String paymentMethodId,
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
        return {
          'success': false,
          'error': 'Erro ao salvar método de pagamento: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro na requisição: $e',
      };
    }
  }

  // 4. MÉTODOS AUXILIARES

  /// Verificar status do pagamento
  Future<String> _checkPaymentStatus(String paymentIntentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payment_intents/$paymentIntentId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] as String;
      }
    } catch (e) {
      debugPrint('Erro ao verificar status: $e');
    }
    return 'unknown';
  }

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
    Map<String, dynamic>? pixData,
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
      if (pixData != null) 'pixData': pixData,
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
    });
  }

  /// Adicionar créditos ao usuário
  Future<void> _addCreditsToUser(String userId, double amount) async {
    final userDoc = await _firebaseService.firestore
        .collection('users')
        .doc(userId)
        .get();

    final currentCredits = userDoc.data()?['credits'] ?? 0.0;
    final newCredits = (currentCredits as num).toDouble() + amount;

    await _firebaseService.firestore
        .collection('users')
        .doc(userId)
        .update({'credits': newCredits});
  }

  /// Formatar data e hora
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} às ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // 5. MÉTODOS PÚBLICOS PARA USO NO CONTROLLER

  /// Processar pagamento (método genérico)
  Future<Map<String, dynamic>> processPayment({
    required BuildContext context,
    required String paymentType, // 'card' ou 'pix'
    required double amount,
    required String description,
    required String serviceId,
    required String serviceType,
  }) async {
    switch (paymentType.toLowerCase()) {
      case 'card':
        return await processCardPayment(
          context: context,
          amount: amount,
          description: description,
          serviceId: serviceId,
          serviceType: serviceType,
        );
      case 'pix':
        return await createPixPayment(
          amount: amount,
          description: description,
          serviceId: serviceId,
          serviceType: serviceType,
        );
      default:
        return {
          'success': false,
          'error': 'Tipo de pagamento não suportado: $paymentType',
        };
    }
  }

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

  /// Remover método de pagamento
  Future<bool> removePaymentMethod(String paymentMethodId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payment_methods/$paymentMethodId/detach'),
        headers: _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro ao remover método de pagamento: $e');
      return false;
    }
  }

  /// Criar Payment Method no Stripe
  Future<Map<String, dynamic>> createPaymentMethod({
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvc,
    required String cardHolderName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payment_methods'),
        headers: _headers,
        body: {
          'type': 'card',
          'card[number]': cardNumber,
          'card[exp_month]': expiryMonth.toString(),
          'card[exp_year]': expiryYear.toString(),
          'card[cvc]': cvc,
          'billing_details[name]': cardHolderName,
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
          'error': errorData['error']['message'] ?? 'Erro ao criar método de pagamento',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro na requisição: $e',
      };
    }
  }

  /// Processar pagamento com cartão salvo (sem interação com o usuário)
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

      // 1. Buscar o método de pagamento padrão do customer
      final paymentMethodsResponse = await getSavedPaymentMethods(customerId);

      if (paymentMethodsResponse.isEmpty) {
        return {
          'success': false,
          'error': 'Nenhum método de pagamento encontrado para este customer',
        };
      }

      // Usar o primeiro método de pagamento disponível (ou você pode implementar lógica para escolher o padrão)
      final paymentMethodId = paymentMethodsResponse.first['id'];

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

      // 3. Confirmar Payment Intent com o método de pagamento salvo
      final confirmResponse = await http.post(
        Uri.parse('$_baseUrl/payment_intents/$paymentIntentId/confirm'),
        headers: _headers,
        body: {
          'payment_method': paymentMethodId,
          'return_url': 'https://your-app.com/return', // URL de retorno (pode ser fictícia para apps móveis)
        },
      );

      if (confirmResponse.statusCode != 200) {
        final errorData = json.decode(confirmResponse.body);
        return {
          'success': false,
          'error': errorData['error']['message'] ?? 'Erro ao confirmar pagamento',
        };
      }

      final confirmedData = json.decode(confirmResponse.body);
      final status = confirmedData['status'];

      // 4. Verificar o status do pagamento
      if (status == 'succeeded') {
        // Pagamento bem-sucedido
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

        // Adicionar créditos ao usuário
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
        // Requer ação adicional (3D Secure, etc.)
        return {
          'success': false,
          'requires_action': true,
          'payment_intent_id': paymentIntentId,
          'client_secret': clientSecret,
          'error': 'O pagamento requer autenticação adicional',
        };
      } else if (status == 'requires_payment_method') {
        // Método de pagamento foi recusado
        return {
          'success': false,
          'error': 'Método de pagamento recusado. Tente com outro cartão.',
        };
      } else {
        // Outros status de erro
        return {
          'success': false,
          'error': 'Pagamento não foi aprovado. Status: $status',
        };
      }

    } catch (e) {
      debugPrint('Erro ao processar pagamento com cartão salvo: $e');
      return {
        'success': false,
        'error': 'Erro inesperado: $e',
      };
    } finally {
      isLoading.value = false;
    }
  }

  /// Buscar método de pagamento padrão do customer
  Future<String?> getDefaultPaymentMethod(String customerId) async {
    try {
      final paymentMethods = await getSavedPaymentMethods(customerId);

      if (paymentMethods.isNotEmpty) {
        // Retornar o primeiro método de pagamento
        // Você pode implementar lógica mais sofisticada para determinar o padrão
        return paymentMethods.first['id'];
      }

      return null;
    } catch (e) {
      debugPrint('Erro ao buscar método de pagamento padrão: $e');
      return null;
    }
  }

  /// Processar pagamento com Payment Sheet (método interativo)
  Future<Map<String, dynamic>> processInteractiveCardPayment({
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
      String errorMessage = 'Erro no pagamento';

      switch (e.error.code) {
        case FailureCode.Canceled:
          errorMessage = 'Pagamento cancelado pelo usuário';
          break;
        case FailureCode.Failed:
          errorMessage = 'Pagamento falhou';
          break;
        case FailureCode.Timeout:
          errorMessage = 'Timeout na operação';
          break;
        default:
          errorMessage = e.error.localizedMessage ?? 'Erro desconhecido';
      }

      return {
        'success': false,
        'error': errorMessage,
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

  /// Cancelar um Payment Intent
  Future<Map<String, dynamic>> cancelPaymentIntent(String paymentIntentId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents/$paymentIntentId/cancel'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Erro ao cancelar pagamento: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro na requisição: $e',
      };
    }
  }

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
}