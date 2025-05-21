import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class EfiPayService {
  final String _clientId;
  final String _clientSecret;
  final bool _isSandbox;

  // Configurações de ambiente
  static const String _sandboxBaseUrl = 'https://cobrancas-h.api.efipay.com.br';
  static const String _productionBaseUrl = 'https://api.efipay.com.br';

  EfiPayService({
    required String clientId,
    required String clientSecret,
    bool isSandbox = true,
  })  : _clientId = clientId,
        _clientSecret = clientSecret,
        _isSandbox = isSandbox;

  // Método para obter token de autenticação
  Future<String?> _getAccessToken() async {
    try {
      final baseUrl = _isSandbox ? _sandboxBaseUrl : _productionBaseUrl;
      final url = Uri.parse('$baseUrl/oauth/token');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ' + base64Encode(
            utf8.encode('$_clientId:$_clientSecret'),
          ),
        },
        body: json.encode({
          'grant_type': 'client_credentials',
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        return responseBody['access_token'];
      } else {
        debugPrint('Erro ao obter token: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erro na autenticação: $e');
      return null;
    }
  }

  // Método genérico para requisições
  Future<Map<String, dynamic>> _makeRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    try {
      // Obter token de acesso
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'error': 'Falha na autenticação',
        };
      }

      final baseUrl = _isSandbox ? _sandboxBaseUrl : _productionBaseUrl;
      final url = Uri.parse('$baseUrl$endpoint');

      http.Response response;
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: json.encode(body),
          );
          break;
        case 'GET':
          response = await http.get(
            url,
            headers: headers,
          );
          break;
        default:
          throw UnsupportedError('Método HTTP não suportado');
      }

      // Processar resposta
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': response.body,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      debugPrint('Erro na requisição: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Método para criar cobrança Pix
  Future<Map<String, dynamic>> createPixCharge({
    required double value,
    required String chavePixDestinatario,
    String? descricao,
  }) async {
    try {
      final response = await _makeRequest(
        endpoint: '/v1/cob',
        method: 'POST',
        body: {
          'calendario': {
            'expiracao': 3600, // 1 hora de expiração
          },
          'valor': {
            'original': value.toStringAsFixed(2),
          },
          'chave': chavePixDestinatario,
          'solicitacaoPagador': descricao ?? '',
        },
      );

      return response;
    } catch (e) {
      debugPrint('Erro ao criar cobrança Pix: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Método para consultar cobrança Pix
  Future<Map<String, dynamic>> consultPixCharge(String txid) async {
    try {
      final response = await _makeRequest(
        endpoint: '/v1/cob/$txid',
        method: 'GET',
      );

      return response;
    } catch (e) {
      debugPrint('Erro ao consultar cobrança Pix: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Método para criar cobrança de boleto
  Future<Map<String, dynamic>> createBankBillet({
    required double value,
    required String name,
    required String cpfCnpj,
    required DateTime dueDate,
    String? description,
  }) async {
    try {
      final response = await _makeRequest(
        endpoint: '/v1/charge/one-step',
        method: 'POST',
        body: {
          'payment': {
            'banking_billet': {
              'expire_at': dueDate.toIso8601String().split('T')[0],
              'message': description ?? '',
            }
          },
          'items': [
            {
              'name': description ?? 'Cobrança',
              'value': value,
              'amount': 1,
            }
          ],
          'customer': {
            'name': name,
            'cpf': cpfCnpj,
          }
        },
      );

      return response;
    } catch (e) {
      debugPrint('Erro ao criar boleto: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Método para processar pagamento com cartão de crédito
  Future<Map<String, dynamic>> createCreditCardPayment({
    required double value,
    required String cardToken,
    required String name,
    required String cpfCnpj,
    int installments = 1,
  }) async {
    try {
      final response = await _makeRequest(
        endpoint: '/v1/charge/one-step',
        method: 'POST',
        body: {
          'payment': {
            'credit_card': {
              'installments': installments,
              'card_token': cardToken,
            }
          },
          'items': [
            {
              'name': 'Pagamento',
              'value': value,
              'amount': 1,
            }
          ],
          'customer': {
            'name': name,
            'cpf': cpfCnpj,
          }
        },
      );

      return response;
    } catch (e) {
      debugPrint('Erro ao processar pagamento com cartão de crédito: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Exemplo de criação de token de cartão
  Future<Map<String, dynamic>> createCardToken({
    required String cardNumber,
    required String cardExpirationMonth,
    required String cardExpirationYear,
    required String cardCvv,
  }) async {
    try {
      final response = await _makeRequest(
        endpoint: '/v1/card-token',
        method: 'POST',
        body: {
          'card': {
            'number': cardNumber,
            'expiration_month': cardExpirationMonth,
            'expiration_year': cardExpirationYear,
            'cvv': cardExpirationYear,
          }
        },
      );

      return response;
    } catch (e) {
      debugPrint('Erro ao criar token de cartão: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

// Exemplo de uso
class PaymentExample {
  final EfiPayService _efiPayService;

  PaymentExample(this._efiPayService);

  Future<void> exampleUsage() async {
    // Criar cobrança Pix
    final pixResponse = await _efiPayService.createPixCharge(
      value: 100.00,
      chavePixDestinatario: 'chavepix@exemplo.com',
      descricao: 'Pagamento de serviço',
    );

    // Criar boleto
    final boletoResponse = await _efiPayService.createBankBillet(
      value: 200.00,
      name: 'João Silva',
      cpfCnpj: '000.000.000-00',
      dueDate: DateTime.now().add(Duration(days: 30)),
      description: 'Mensalidade',
    );

    // Criar token de cartão (primeiro passo para pagamento com cartão)
    final tokenResponse = await _efiPayService.createCardToken(
      cardNumber: '4111111111111111',
      cardExpirationMonth: '12',
      cardExpirationYear: '2025',
      cardCvv: '123',
    );

    // Pagamento com cartão de crédito usando token
    if (tokenResponse['success']) {
      final cardToken = tokenResponse['data']['card_token'];
      final creditCardPayment = await _efiPayService.createCreditCardPayment(
        value: 300.00,
        cardToken: cardToken,
        name: 'Maria Souza',
        cpfCnpj: '111.111.111-11',
        installments: 3,
      );
    }
  }
}