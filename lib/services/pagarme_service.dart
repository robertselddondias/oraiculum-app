import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:oraculum/models/credit_card_model.dart';

class PagarmeService {

  /// Base URL da API do Pagar.me
  static const String baseUrl = 'https://api.pagar.me/core/v5';

  static const String apiKey = "sk_test_3f61ed2fcd1b419c91b0743f305efcc2";

  /// Gera o cabeçalho de autenticação com Basic Authentication
  Future<Map<String, String>> _getAuthHeaders() async {

    final basicAuth = 'Basic ${base64Encode(utf8.encode('$apiKey:'))}';
    return {
      'Content-Type': 'application/json',
      'Authorization': basicAuth,
    };
  }

  /// Cadastra um cartão de crédito ou débito no Pagar.me
  Future<String> createCard({
    required String cardNumber,
    required String cardHolderName,
    required String cardExpirationDate,
    required String cardCvv,
    required String documentNumber,
    String? documentType,
    String? customerId
  }) async {
    final url = Uri.parse('$baseUrl/customers/$customerId/cards');
    final dateSplit = cardExpirationDate.split('/');
    final body = {
      "number": cardNumber.replaceAll(' ', ''),
      "holder_name": cardHolderName,
      "exp_year": dateSplit[1],
      "exp_month": dateSplit[0],
      "cvv": cardCvv,
    };

    try {
      final response = await http.post(
        url,
        headers: await _getAuthHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseSaveCard = jsonDecode(response.body);

        DocumentReference doc = FirebaseFirestore.instance.collection('credit_cards').doc();

        CreditCardUserModel creditCardModel = CreditCardUserModel();
        creditCardModel.cardId = responseSaveCard['id'];
        creditCardModel.lastFourDigits = responseSaveCard['last_four_digits'];
        creditCardModel.brandType = responseSaveCard['brand'];
        creditCardModel.cardHolderName = responseSaveCard['holder_name'];
        creditCardModel.transationalType = responseSaveCard['type'];
        creditCardModel.customerId = responseSaveCard['customer']['id'];
        creditCardModel.expirationDate = '${responseSaveCard['exp_month']}/${responseSaveCard['exp_year']}';
        creditCardModel.userId = FirebaseAuth.instance.currentUser!.uid;
        creditCardModel.id = doc.id;

        await doc.set(creditCardModel.toJson());
        return responseSaveCard['id'];
      } else {
        throw Exception(
          'Erro ao criar cartão: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o Pagar.me: $e');
    }
  }

  /// Obtém os detalhes de um cartão pelo ID
  Future<Map<String, dynamic>> getCardDetails(String cardId) async {
    final url = Uri.parse('$baseUrl/cards/$cardId');

    try {
      final response = await http.get(
        url,
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erro ao buscar detalhes do cartão: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o Pagar.me: $e');
    }
  }

  /// Remove um cartão pelo ID
  Future<void> deleteCard(CreditCardUserModel card) async {
    final url = Uri.parse('$baseUrl/customers/${card.customerId}/cards/${card.cardId}');

    try {
      final response = await http.delete(
        url,
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Erro ao deletar o cartão: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o Pagar.me: $e');
    }
  }

  /// Cadastra um cliente no Pagar.me
  Future<String> createCustomer(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/customers');
    try {
      final response = await http.post(
        url,
        headers: await _getAuthHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body)['id'];
      } else {
        throw Exception(
          'Erro ao criar cliente: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o Pagar.me: $e');
    }
  }

  /// Obtém os detalhes de um cliente pelo ID
  Future<Map<String, dynamic>> getCustomerDetails(String customerId) async {
    final url = Uri.parse('$baseUrl/customers/$customerId');

    try {
      final response = await http.get(
        url,
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erro ao buscar detalhes do cliente: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o Pagar.me: $e');
    }
  }

  /// Atualiza os dados de um cliente
  Future<Map<String, dynamic>> updateCustomer({
    required String customerId,
    String? name,
    String? email,
    String? documentNumber,
    String? documentType,
    String? phone
  }) async {
    final url = Uri.parse('$baseUrl/customers/$customerId');

    final body = {
      if (name != null) "name": name,
      if (email != null) "email": email,
      if (documentNumber != null) "document": documentNumber.replaceAll(RegExp(r'[^0-9]'), ''),
      if (documentType != null) "document_type": documentType,
      "type": documentType == 'CPF' ? 'individual' : 'company',
      "code": FirebaseAuth.instance.currentUser!.uid
    };

    try {
      final response = await http.put(
        url,
        headers: await _getAuthHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erro ao atualizar cliente: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o Pagar.me: $e');
    }
  }

  /// Cria um pedido na API do Pagar.me
  Future<http.Response> createOrder(
      {
        required CreditCardUserModel creditCard,
        required int amount,
        required String orderId
      }
      ) async {
    final url = Uri.parse('$baseUrl/orders');


    final body = {
      "customer_id": creditCard.customerId,
      "code": orderId,
      "items": [
        {
          'amount': amount,
          'description': 'Viagem customerId: ${creditCard.customerId} - UsuarioId: ${creditCard.userId}',
          'quantity': 1,
          'code': 1
        },
      ],
      "payments": [{
        'credit_card':{
          'card_id': creditCard.cardId
        },
        'amount': amount,
        'payment_method': 'credit_card'
      }]
    };

    try {
      final response = await http.post(
        url,
        headers: await _getAuthHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response;
      } else {
        throw Exception(
          'Erro ao criar pedido: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o Pagar.me: $e');
    }
  }

  /// Cria uma transação Pix
  Future<http.Response> createPixTransaction({
    required int amount,
    required String orderId,
    required String customerId
  }) async {

    final url = Uri.parse("$baseUrl/orders");

    final body = {
      "items": [
        {
          "amount": amount,
          "quantity": 1,
          "code": "pix_payment",
          "description": "Pagamento via Pix"
        }
      ],
      "customer_id": customerId,
      "code": orderId,
      "payments": [
        {
          "payment_method": "pix",
          "pix": {
            "expires_in": '360'
          }
        }
      ]
    };

    final response = await http.post(url, headers: await _getAuthHeaders(), body: jsonEncode(body));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response;
    } else {
      throw Exception("Erro ao criar transação Pix: ${response.body}");
    }
  }
}
