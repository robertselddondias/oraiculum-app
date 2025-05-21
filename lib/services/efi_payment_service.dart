import 'package:flutter/foundation.dart';
import 'package:efipay/efipay.dart'; // Import the correct package
import 'dart:convert';

class EfiPayService {
  late EfiPay _efiPay;
  final bool _isSandbox;

  // Updated constructor with certificate and accountId parameters
  EfiPayService({
    required String clientId,
    required String clientSecret,
    required String certificatePath,
    required String accountId,
    bool isSandbox = true,
  }) : _isSandbox = isSandbox {
    // Initialize the Efipay SDK with all required credentials
    _efiPay = EfiPay(
      {
        'client_id': clientId,
        'client_secret': clientSecret,
        'sandbox': isSandbox,
        'certificate': certificatePath,
        'account_id': accountId,
      },
    );
  }

  // Method to create a credit card token
  Future<Map<String, dynamic>> createCardToken({
    required String cardNumber,
    required String cardExpirationMonth,
    required String cardExpirationYear,
    required String cardCvv,
  }) async {
    try {
      final tokenData = {
        'card': {
          'number': cardNumber,
          'cvv': cardCvv,
          'expiration_month': cardExpirationMonth,
          'expiration_year': cardExpirationYear,
        }
      };

      // Call the paymentToken endpoint
      final response = await _efiPay.call('paymentToken', body: tokenData);

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      debugPrint('Error creating card token: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Method to create a credit card payment
  Future<Map<String, dynamic>> createCreditCardPayment({
    required double value,
    required String cardToken,
    required String name,
    required String cpfCnpj,
    String? email,
    String? phoneNumber,
    int installments = 1,
  }) async {
    try {
      final body = {
        'payment': {
          'credit_card': {
            'installments': installments,
            'payment_token': cardToken,
            'billing_address': {
              'street': 'Av. JK',
              'number': '909',
              'neighborhood': 'Bauxita',
              'zipcode': '35400000',
              'city': 'Ouro Preto',
              'state': 'MG'
            }
          }
        },
        'items': [
          {
            'name': 'Créditos Oraculum',
            'value': (value * 100).toInt(), // Convert to cents
            'amount': 1,
          }
        ],
        'customer': {
          'name': name,
          'cpf': cpfCnpj.replaceAll(RegExp(r'[^0-9]'), ''),
          'phone_number': phoneNumber ?? '31986448613',
          'email': email ?? 'email@cliente.com.br',
          'birth': '1985-01-01', // This could be dynamic with more parameters
        },
        'metadata': {
          'custom_id': 'Oraculum-${DateTime.now().millisecondsSinceEpoch}',
          'notification_url': 'https://oraculum-app.com/notifications',
        }
      };

      final response = await _efiPay.call('oneStepCharge', body: body);

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      debugPrint('Error processing credit card payment: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Method to create a PIX payment
  Future<Map<String, dynamic>> createPixCharge({
    required double value,
    required String chavePixDestinatario,
    String? name,
    String? cpfCnpj,
    String? descricao,
  }) async {
    try {
      final body = {
        'calendario': {
          'expiracao': 3600 // 1 hour expiration
        },
        'devedor': {
          'cpf': cpfCnpj?.replaceAll(RegExp(r'[^0-9]'), '') ?? '94271564656',
          'nome': name ?? 'Cliente Oraculum'
        },
        'valor': {
          'original': value.toStringAsFixed(2)
        },
        'chave': chavePixDestinatario,
        'infoAdicionais': [
          {
            'nome': 'Pagamento',
            'valor': descricao ?? 'Créditos Oraculum'
          }
        ]
      };

      final response = await _efiPay.call('pixCreateImmediateCharge', body: body);

      // After creating the charge, generate the QR code
      final qrResponse = await _generatePixQrCode(response['loc']['id']);

      // Combine the responses
      response['qrcode'] = qrResponse;

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      debugPrint('Error creating PIX charge: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Helper method to generate PIX QR code
  Future<Map<String, dynamic>> _generatePixQrCode(String locId) async {
    try {
      final params = {
        'id': locId
      };

      final response = await _efiPay.call('pixGenerateQRCode', params: params);
      return response;
    } catch (e) {
      debugPrint('Error generating PIX QR code: $e');
      throw e;
    }
  }

  // Method to check PIX payment status
  Future<Map<String, dynamic>> checkPixStatus(String txid) async {
    try {
      final params = {
        'txid': txid
      };

      final response = await _efiPay.call('pixDetailCharge', params: params);

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      debugPrint('Error checking PIX status: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Method to create a bank billet (boleto)
  Future<Map<String, dynamic>> createBankBillet({
    required double value,
    required String name,
    required String cpfCnpj,
    required DateTime dueDate,
    String? email,
    String? phoneNumber,
    String? description,
  }) async {
    try {
      final body = {
        'payment': {
          'banking_billet': {
            'expire_at': dueDate.toIso8601String().split('T')[0],
            'customer': {
              'name': name,
              'cpf': cpfCnpj.replaceAll(RegExp(r'[^0-9]'), ''),
              'phone_number': phoneNumber ?? '31986448613',
              'email': email ?? 'email@cliente.com.br',
            }
          }
        },
        'items': [
          {
            'name': description ?? 'Créditos Oraculum',
            'value': (value * 100).toInt(), // Convert to cents
            'amount': 1,
          }
        ],
        'metadata': {
          'custom_id': 'Oraculum-${DateTime.now().millisecondsSinceEpoch}',
          'notification_url': 'https://oraculum-app.com/notifications',
        }
      };

      final response = await _efiPay.call('billCreateCharge', body: body);

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      debugPrint('Error creating bank billet: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}