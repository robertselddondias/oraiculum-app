import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/services/pagarme_service.dart';
import 'package:uuid/uuid.dart';

/// Um serviço de pagamento simplificado que simula o Google Pay e Apple Pay
class PaymentService extends GetxService {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final uuid = const Uuid();

  final RxBool isLoading = false.obs;

  // Inicializa o serviço
  Future<PaymentService> init() async {
    debugPrint('PaymentService inicializado');
    return this;
  }

  /// Processa um pagamento via Google Pay
  Future<String?> payWithGooglePay({
    required double amount,
    required String userId,
    required String serviceId,
    required String serviceType,
    required String description,
    required BuildContext context,
  }) async {
    try {
      isLoading.value = true;

      // Em um app real, aqui seria a chamada ao Google Pay
      // Simulando o processamento
      await Future.delayed(const Duration(seconds: 2));

      // Usar GooglePay no ambiente real
      // For development, simulate a successful payment
      final paymentId = 'googlepay-${uuid.v4()}';

      // Salvar registro de pagamento
      await _savePaymentRecord(
        userId: userId,
        serviceId: serviceId,
        serviceType: serviceType,
        amount: amount,
        paymentMethod: 'Google Pay',
        paymentId: paymentId,
        status: 'approved',
        description: description,
      );

      // Adicionar créditos à conta do usuário
      await updateUserCredits(userId, amount);

      return paymentId;
    } catch (e) {
      debugPrint('Erro ao processar pagamento Google Pay: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Processa um pagamento via Apple Pay
  Future<String?> payWithApplePay({
    required double amount,
    required String userId,
    required String serviceId,
    required String serviceType,
    required String description,
    required BuildContext context,
  }) async {
    try {
      isLoading.value = true;

      // Em um app real, aqui seria a chamada ao Apple Pay
      // Simulando o processamento
      await Future.delayed(const Duration(seconds: 2));

      // Usar ApplePay no ambiente real
      // For development, simulate a successful payment
      final paymentId = 'applepay-${uuid.v4()}';

      // Salvar registro de pagamento
      await _savePaymentRecord(
        userId: userId,
        serviceId: serviceId,
        serviceType: serviceType,
        amount: amount,
        paymentMethod: 'Apple Pay',
        paymentId: paymentId,
        status: 'approved',
        description: description,
      );

      // Adicionar créditos à conta do usuário
      await updateUserCredits(userId, amount);

      return paymentId;
    } catch (e) {
      debugPrint('Erro ao processar pagamento Apple Pay: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Método para salvar registro de pagamento
  Future<String> _savePaymentRecord({
    required String userId,
    required String serviceId,
    required String serviceType,
    required double amount,
    required String paymentMethod,
    required String paymentId,
    required String status,
    required String description,
  }) async {
    try {
      final paymentData = {
        'userId': userId,
        'serviceId': serviceId,
        'serviceType': serviceType,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'paymentId': paymentId,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'description': description,
      };

      // Salvar registro de pagamento no Firestore
      final docRef = await _firebaseService.firestore
          .collection('payments')
          .add(paymentData);

      return docRef.id;
    } catch (e) {
      debugPrint('Erro ao salvar registro de pagamento: $e');
      throw Exception('Falha ao salvar registro de pagamento');
    }
  }

  /// Verificar se o usuário tem créditos suficientes
  Future<bool> checkUserCredits(String userId, double requiredAmount) async {
    try {
      isLoading.value = true;

      final userData = await _firebaseService.getUserData(userId);
      if (!userData.exists) {
        return false;
      }

      final data = userData.data() as Map<String, dynamic>?;
      if (data == null) {
        return false;
      }

      // Tratar caso onde o campo credits pode não existir ou ser de um tipo diferente
      var userCredits = 0.0;
      if (data.containsKey('credits')) {
        if (data['credits'] is double) {
          userCredits = data['credits'] as double;
        } else if (data['credits'] is int) {
          userCredits = (data['credits'] as int).toDouble();
        } else {
          // Tentar converter o valor para double se for outro tipo
          try {
            userCredits = double.parse(data['credits'].toString());
          } catch (e) {
            debugPrint('Erro ao converter créditos: $e');
            userCredits = 0.0;
          }
        }
      }

      return userCredits >= requiredAmount;
    } catch (e) {
      debugPrint('Erro ao verificar créditos: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Atualizar créditos do usuário
  Future<bool> updateUserCredits(String userId, double amount) async {
    try {
      isLoading.value = true;



      // Primeiro obter créditos atuais
      final userData = await _firebaseService.getUserData(userId);
      if (!userData.exists) {
        throw Exception('Usuário não encontrado');
      }

      final data = userData.data() as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Dados do usuário são nulos');
      }

      // Tratar caso onde o campo credits pode não existir ou ser de um tipo diferente
      var currentCredits = 0.0;
      if (data.containsKey('credits')) {
        if (data['credits'] is double) {
          currentCredits = data['credits'] as double;
        } else if (data['credits'] is int) {
          currentCredits = (data['credits'] as int).toDouble();
        } else {
          // Tentar converter o valor para double se for outro tipo
          try {
            currentCredits = double.parse(data['credits'].toString());
          } catch (e) {
            debugPrint('Erro ao converter créditos: $e');
            currentCredits = 0.0;
          }
        }
      }

      final newCredits = currentCredits + amount;

      // Garantir que os créditos não fiquem abaixo de zero
      if (newCredits < 0) {
        throw Exception('Créditos insuficientes');
      }

      await _firebaseService.updateUserData(userId, {'credits': newCredits});

      // Também registrar esta transação
      await _firebaseService.firestore.collection('credit_transactions').add({
        'userId': userId,
        'amount': amount,
        'previousBalance': currentCredits,
        'newBalance': newCredits,
        'timestamp': FieldValue.serverTimestamp(),
        'type': amount > 0 ? 'credit' : 'debit',
      });

      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar créditos: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Processar pagamento com créditos
  Future<String> processPaymentWithCredits(
      String userId,
      double amount,
      String description,
      String serviceId,
      String serviceType,
      ) async {
    try {
      isLoading.value = true;

      // Verificar se o usuário tem créditos suficientes
      final hasCredits = await checkUserCredits(userId, amount);

      if (!hasCredits) {
        throw Exception('Créditos insuficientes');
      }

      // Criar um ID de pagamento único
      final paymentId = 'credit-${uuid.v4()}';

      // Deduzir créditos
      final creditUpdated = await updateUserCredits(userId, -amount);

      if (!creditUpdated) {
        throw Exception('Falha ao atualizar créditos');
      }

      // Salvar registro de pagamento
      final recordId = await _savePaymentRecord(
        userId: userId,
        serviceId: serviceId,
        serviceType: serviceType,
        amount: amount,
        paymentMethod: 'Credits',
        paymentId: paymentId,
        status: 'approved',
        description: description,
      );

      return recordId;
    } catch (e) {
      debugPrint('Erro ao processar pagamento com créditos: $e');
      throw Exception('Falha ao processar pagamento: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Obter histórico de pagamentos do usuário
  Future<List<Map<String, dynamic>>> getUserPaymentHistory(String userId) async {
    try {
      isLoading.value = true;

      final snapshot = await _firebaseService.firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          // Converter Timestamp para DateTime para facilitar o manuseio
          'timestamp': data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Erro ao obter histórico de pagamentos: $e');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Método auxiliar para obter pagamento por ID
  Future<Map<String, dynamic>?> getPaymentById(String paymentId) async {
    try {
      final doc = await _firebaseService.firestore
          .collection('payments')
          .doc(paymentId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        ...data,
        // Converter Timestamp para DateTime para facilitar o manuseio
        'timestamp': data['timestamp'] != null
            ? (data['timestamp'] as Timestamp).toDate()
            : DateTime.now(),
      };
    } catch (e) {
      debugPrint('Erro ao obter pagamento: $e');
      return null;
    }
  }
}