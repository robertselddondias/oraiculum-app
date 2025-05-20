import 'dart:convert';

import 'package:http/http.dart' as http;

class PagarmeWalletService {
  final String apiKey = 'sk_test_3f61ed2fcd1b419c91b0743f305efcc2';
  final String baseUrl;

  PagarmeWalletService({
    this.baseUrl = 'https://api.pagar.me/core/v5',
  });

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Basic ${base64.encode(utf8.encode('$apiKey:'))}',
  };

  /// Pagamento via Apple Pay ou Google Pay (wallet_token)
  Future<bool> payWithWalletToken({
    required String customerId,
    required int amountInCents,
    required String walletToken, // token retornado pelo Apple/Google Pay
    required String brand, // 'visa', 'mastercard', etc.
  }) async {
    final body = {
      "items": [
        {
          "amount": amountInCents,
          "description": "Pagamento com carteira digital",
          "quantity": 1
        }
      ],
      "customer_id": customerId,
      "payments": [
        {
          "payment_method": "credit_card",
          "credit_card": {
            "installments": 1,
            "card": {
              "token": walletToken,
              "store": false,
              "brand": brand
            }
          }
        }
      ]
    };

    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Pagamento com Apple Pay/Google Pay aprovado!');
      return true;
    } else {
      print('Erro no pagamento com carteira digital: ${response.body}');
      return false;
    }
  }
}