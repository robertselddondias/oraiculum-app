import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:pay/pay.dart';

class PagarmeService {
  final String apiKey = 'sk_test_3f61ed2fcd1b419c91b0743f305efcc2';
  final String baseUrl;

  PagarmeService({
    this.baseUrl = 'https://api.pagar.me/core/v5',
  });

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Basic ${base64.encode(utf8.encode('$apiKey:'))}',
  };

  /// 1. Criação do cliente
  Future<String?> createCustomer(Map<String, dynamic> customerData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers'),
      headers: headers,
      body: jsonEncode(customerData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body);
      return body['id'];
    } else {
      print('Erro ao criar cliente: ${response.body}');
      return null;
    }
  }

  /// 2. Tokenizar cartão
  Future<String?> generateCardToken(Map<String, dynamic> cardData) async {
    final response = await http.post(
      Uri.parse('https://api.pagar.me/core/v5/tokens'),
      headers: headers,
      body: jsonEncode({
        "type": "card",
        "card": cardData,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body);
      return body['id'];
    } else {
      print('Erro ao tokenizar cartão: ${response.body}');
      return null;
    }
  }

  /// 3. Pagamento com Cartão de Crédito
  Future<bool> payWithCreditCard(Map<String, dynamic> paymentData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: headers,
      body: jsonEncode(paymentData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Pagamento com cartão aprovado!');
      return true;
    } else {
      print('Erro no pagamento com cartão: ${response.body}');
      return false;
    }
  }

  /// 4. Pagamento com Pix
  Future<Map<String, dynamic>?> payWithPix({
    required int amountInCents,
    required String customerId,
  }) async {
    final body = {
      "items": [
        {
          "amount": amountInCents,
          "description": "Pedido Pix Flutter",
          "quantity": 1
        }
      ],
      "customer_id": customerId,
      "payments": [
        {
          "payment_method": "pix",
        }
      ]
    };

    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      final pixInfo = json['charges'][0]['last_transaction'];
      return {
        "qr_code": pixInfo['qr_code'],
        "qr_code_url": pixInfo['qr_code_url'],
        "expires_at": pixInfo['expires_at'],
      };
    } else {
      print('Erro no pagamento Pix: ${response.body}');
      return null;
    }
  }

  Future<String?> requestWalletTokenManually({
    required String assetPath,
    required List<PaymentItem> paymentItems,
    required PayProvider provider,
  }) async {
    try {
      String urlPayMethod = Platform.isIOS ? 'assets/pay_configs/pay_apple.json' : 'assets/pay_configs/pay_google.json';

      final payClient = Pay.withAssets(urlPayMethod);

      final paymentResult = await payClient.showPaymentSelector(
        provider: provider,
        paymentItems: paymentItems,
      );

      // Diferença entre Apple Pay e Google Pay:
      if (provider == PayProvider.google_pay) {
        return paymentResult['paymentMethodData']?['tokenizationData']?['token'];
      } else if (provider == PayProvider.apple_pay) {
        return paymentResult['token']?['paymentData'];
      }

      return null;
    } catch (e) {
      debugPrint("Erro ao obter token da carteira: $e");
      return null;
    }
  }
}