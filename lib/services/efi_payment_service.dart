import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_functions/cloud_functions.dart';

class EfiPayService {
  // Instância do Firebase Functions
  final FirebaseFunctions _functions;

  // Construtor que pode receber uma instância personalizada de FirebaseFunctions
  EfiPayService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  Future<void> ensureTokenIsValid() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Obter um token fresco
        await currentUser.getIdToken(true);
      } else {
        throw Exception('Usuário não autenticado');
      }
    } catch (e) {
      debugPrint('Erro ao atualizar token: $e');
      throw Exception('Falha na autenticação: $e');
    }
  }

  // 1. Método para criar token de cartão
  Future<Map<String, dynamic>> createCardToken({
    required String cardNumber,
    required String cardExpirationMonth,
    required String cardExpirationYear,
    required String cardCvv,
    required String brand
  }) async {
    try {
      debugPrint('Solicitando criação de token de cartão');

      // Removendo espaços do número do cartão
      final sanitizedCardNumber = cardNumber.replaceAll(' ', '');

      await ensureTokenIsValid();

      // Chamando a Cloud Function
      final result = await _functions
          .httpsCallable('createCardToken')
          .call({
        'cardNumber': sanitizedCardNumber,
        'cardCvv': cardCvv,
        'cardExpirationMonth': cardExpirationMonth,
        'cardExpirationYear': cardExpirationYear,
      });

      // Processando o resultado
      final responseData = result.data as Map<String, dynamic>;

      debugPrint('Token de cartão criado com sucesso');
      return responseData;
    } catch (e) {
      debugPrint('Erro ao criar token do cartão: $e');

      // Garantindo retorno padronizado mesmo em caso de erro
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // 2. Método para criar pagamento com cartão de crédito
  Future<Map<String, dynamic>> createCreditCardPayment({
    required double value,
    required String cardToken,
    required String name,
    required String cpfCnpj,
    String? email,
    String? phoneNumber,
    int installments = 1,
    String? cardLastFourDigits,
    String? cardBrand,
    String? description,
  }) async {
    try {
      debugPrint('Processando pagamento com cartão de crédito: R\$ ${value.toStringAsFixed(2)}');

      // Removendo formatação do CPF/CNPJ
      final sanitizedCpfCnpj = cpfCnpj.replaceAll(RegExp(r'[^0-9]'), '');

      // Chamando a Cloud Function
      final result = await _functions
          .httpsCallable('createCreditCardPayment')
          .call({
        'amount': (value * 100).toInt(), // Convertendo para centavos
        'cardToken': cardToken,
        'name': name,
        'cpfCnpj': sanitizedCpfCnpj,
        'email': email,
        'phoneNumber': phoneNumber,
        'installments': installments,
        'description': description ?? 'Créditos Oraculum',
        'cardLastFourDigits': cardLastFourDigits,
        'cardBrand': cardBrand,
      });

      // Processando o resultado
      final responseData = result.data as Map<String, dynamic>;

      debugPrint('Pagamento com cartão de crédito processado com sucesso');
      return responseData;
    } catch (e) {
      debugPrint('Erro ao processar pagamento com cartão de crédito: $e');

      // Garantindo retorno padronizado mesmo em caso de erro
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // 3. Método para criar pagamento com cartão de débito
  Future<Map<String, dynamic>> createDebitCardPayment({
    required double value,
    required String cardToken,
    required String name,
    required String cpfCnpj,
    String? email,
    String? phoneNumber,
    String? cardLastFourDigits,
    String? cardBrand,
    String? description,
  }) async {
    try {
      debugPrint('Processando pagamento com cartão de débito: R\$ ${value.toStringAsFixed(2)}');

      // Removendo formatação do CPF/CNPJ
      final sanitizedCpfCnpj = cpfCnpj.replaceAll(RegExp(r'[^0-9]'), '');

      // Chamando a Cloud Function
      final result = await _functions
          .httpsCallable('createDebitCardPayment')
          .call({
        'amount': (value * 100).toInt(), // Convertendo para centavos
        'cardToken': cardToken,
        'name': name,
        'cpfCnpj': sanitizedCpfCnpj,
        'email': email,
        'phoneNumber': phoneNumber,
        'description': description ?? 'Créditos Oraculum',
        'cardLastFourDigits': cardLastFourDigits,
        'cardBrand': cardBrand,
      });

      // Processando o resultado
      final responseData = result.data as Map<String, dynamic>;

      // Verificar se há URL para autenticação (normalmente presente em cartões de débito)
      if (responseData['success'] == true &&
          responseData['data'] != null &&
          responseData['data']['payment_url'] != null) {

        // Aqui você pode implementar a lógica para redirecionar o usuário
        // para a URL de autenticação do cartão de débito
        debugPrint('URL para autenticação do débito: ${responseData['data']['payment_url']}');
      }

      debugPrint('Pagamento com cartão de débito processado com sucesso');
      return responseData;
    } catch (e) {
      debugPrint('Erro ao processar pagamento com cartão de débito: $e');

      // Garantindo retorno padronizado mesmo em caso de erro
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // 4. Método para criar cobrança PIX
  Future<Map<String, dynamic>> createPixCharge({
    required double value,
    required String name,
    required String cpfCnpj,
    String? description,
    int expirationSeconds = 3600, // 1 hora por padrão
  }) async {
    try {
      debugPrint('Criando cobrança PIX: R\$ ${value.toStringAsFixed(2)}');

      // Removendo formatação do CPF/CNPJ
      final sanitizedCpfCnpj = cpfCnpj.replaceAll(RegExp(r'[^0-9]'), '');

      // Chamando a Cloud Function
      final result = await _functions
          .httpsCallable('createPixCharge')
          .call({
        'amount': (value * 100).toInt(), // Convertendo para centavos
        'name': name,
        'cpfCnpj': sanitizedCpfCnpj,
        'description': description ?? 'Créditos Oraculum',
        'expirationSeconds': expirationSeconds,
      });

      // Processando o resultado
      final responseData = result.data as Map<String, dynamic>;

      debugPrint('Cobrança PIX criada com sucesso');
      return responseData;
    } catch (e) {
      debugPrint('Erro ao criar cobrança PIX: $e');

      // Garantindo retorno padronizado mesmo em caso de erro
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // 5. Método para verificar o status do pagamento PIX
  Future<Map<String, dynamic>> checkPixStatus({
    required String txid,
    String? paymentId,
  }) async {
    try {
      debugPrint('Verificando status do PIX: $txid');

      // Chamando a Cloud Function
      final result = await _functions
          .httpsCallable('checkPixStatus')
          .call({
        'txid': txid,
        'paymentId': paymentId,
      });

      // Processando o resultado
      final responseData = result.data as Map<String, dynamic>;

      if (responseData['success'] == true && responseData['isPaid'] == true) {
        debugPrint('PIX pago com sucesso!');
      } else {
        debugPrint('PIX ainda não pago ou ocorreu um erro na consulta');
      }

      return responseData;
    } catch (e) {
      debugPrint('Erro ao verificar status do PIX: $e');

      // Garantindo retorno padronizado mesmo em caso de erro
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Métodos auxiliares para o Pix

  // Extrair QR Code do Pix da resposta
  String? extractPixQrCodeImage(Map<String, dynamic> pixResponse) {
    try {
      if (pixResponse['success'] == true &&
          pixResponse['data'] != null &&
          pixResponse['data']['qrcode'] != null &&
          pixResponse['data']['qrcode']['imagemQrcode'] != null) {
        return pixResponse['data']['qrcode']['imagemQrcode'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao extrair QR Code: $e');
      return null;
    }
  }

  // Extrair texto do "Pix Copia e Cola"
  String? extractPixCopyPasteText(Map<String, dynamic> pixResponse) {
    try {
      if (pixResponse['success'] == true &&
          pixResponse['data'] != null &&
          pixResponse['data']['qrcode'] != null &&
          pixResponse['data']['qrcode']['qrcode'] != null) {
        return pixResponse['data']['qrcode']['qrcode'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao extrair texto de Copia e Cola: $e');
      return null;
    }
  }

  // Extrair TxID do Pix
  String? extractPixTxId(Map<String, dynamic> pixResponse) {
    try {
      if (pixResponse['success'] == true &&
          pixResponse['data'] != null &&
          pixResponse['data']['txid'] != null) {
        return pixResponse['data']['txid'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao extrair TxID: $e');
      return null;
    }
  }
}