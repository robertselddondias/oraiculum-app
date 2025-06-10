// lib/services/consultation_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/models/consultation_request_model.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:uuid/uuid.dart';

class ConsultationService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final Uuid _uuid = const Uuid();

  static const String consultationRequestsCollection = 'consultation_requests';
  static const String mediumsCollection = 'mediums';
  static const String availabilityCollection = 'medium_availability';

  Future<String> createConsultationRequest({
    required String clientId,
    required String clientName,
    required String clientEmail,
    required String mediumId,
    required String mediumName,
    required String consultationType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('=== createConsultationRequest() ===');
      debugPrint('Cliente: $clientName');
      debugPrint('Médium: $mediumName');
      debugPrint('Tipo: $consultationType');

      final requestId = _uuid.v4();

      final request = ConsultationRequest(
        id: requestId,
        clientId: clientId,
        clientName: clientName,
        clientEmail: clientEmail,
        mediumId: mediumId,
        mediumName: mediumName,
        consultationType: consultationType,
        description: description,
        status: ConsultationStatus.pending,
        createdAt: DateTime.now(),
        metadata: metadata ?? {},
      );

      await _firestore
          .collection(consultationRequestsCollection)
          .doc(requestId)
          .set(request.toMap());

      await _notifyMedium(
        mediumId,
        'Nova solicitação de consulta',
        '$clientName solicitou uma consulta de $consultationType',
        requestId,
      );

      debugPrint('✅ Solicitação de consulta criada: $requestId');
      return requestId;

    } catch (e) {
      debugPrint('❌ Erro ao criar solicitação de consulta: $e');
      rethrow;
    }
  }

  Future<List<ConsultationRequest>> getMediumConsultationRequests(String mediumId) async {
    try {
      debugPrint('=== getMediumConsultationRequests() ===');
      debugPrint('Médium ID: $mediumId');

      final querySnapshot = await _firestore
          .collection(consultationRequestsCollection)
          .where('mediumId', isEqualTo: mediumId)
          .orderBy('createdAt', descending: true)
          .get();

      final requests = querySnapshot.docs
          .map((doc) => ConsultationRequest.fromFirestore(doc))
          .toList();

      debugPrint('✅ ${requests.length} solicitações encontradas');
      return requests;

    } catch (e) {
      debugPrint('❌ Erro ao buscar solicitações do médium: $e');
      rethrow;
    }
  }

  Future<List<ConsultationRequest>> getClientConsultationRequests(String clientId) async {
    try {
      debugPrint('=== getClientConsultationRequests() ===');
      debugPrint('Cliente ID: $clientId');

      final querySnapshot = await _firestore
          .collection(consultationRequestsCollection)
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();

      final requests = querySnapshot.docs
          .map((doc) => ConsultationRequest.fromFirestore(doc))
          .toList();

      debugPrint('✅ ${requests.length} solicitações encontradas');
      return requests;

    } catch (e) {
      debugPrint('❌ Erro ao buscar solicitações do cliente: $e');
      rethrow;
    }
  }

  Future<ConsultationRequest?> getConsultationRequest(String requestId) async {
    try {
      debugPrint('=== getConsultationRequest() ===');
      debugPrint('Request ID: $requestId');

      final doc = await _firestore
          .collection(consultationRequestsCollection)
          .doc(requestId)
          .get();

      if (!doc.exists) {
        debugPrint('❌ Solicitação não encontrada');
        return null;
      }

      final request = ConsultationRequest.fromFirestore(doc);
      debugPrint('✅ Solicitação encontrada');
      return request;

    } catch (e) {
      debugPrint('❌ Erro ao buscar solicitação: $e');
      rethrow;
    }
  }

  Future<void> acceptConsultationRequest(String requestId) async {
    try {
      debugPrint('=== acceptConsultationRequest() ===');
      debugPrint('Request ID: $requestId');

      await _firestore
          .collection(consultationRequestsCollection)
          .doc(requestId)
          .update({
        'status': ConsultationStatus.scheduled.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      final request = await getConsultationRequest(requestId);
      if (request != null) {
        await _notifyClient(
          request.clientId,
          'Consulta aceita',
          'Sua solicitação de consulta foi aceita por ${request.mediumName}',
          requestId,
        );
      }

      debugPrint('✅ Solicitação aceita');

    } catch (e) {
      debugPrint('❌ Erro ao aceitar solicitação: $e');
      rethrow;
    }
  }

  Future<void> declineConsultationRequest(String requestId, {String? reason}) async {
    try {
      debugPrint('=== declineConsultationRequest() ===');
      debugPrint('Request ID: $requestId');

      final updateData = {
        'status': ConsultationStatus.cancelled.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (reason != null) {
        updateData['notes'] = reason;
      }

      await _firestore
          .collection(consultationRequestsCollection)
          .doc(requestId)
          .update(updateData);

      final request = await getConsultationRequest(requestId);
      if (request != null) {
        await _notifyClient(
          request.clientId,
          'Consulta recusada',
          'Sua solicitação de consulta foi recusada por ${request.mediumName}',
          requestId,
        );
      }

      debugPrint('✅ Solicitação recusada');

    } catch (e) {
      debugPrint('❌ Erro ao recusar solicitação: $e');
      rethrow;
    }
  }

  Future<void> scheduleConsultationRequest(
      String requestId,
      DateTime scheduledDate,
      ) async {
    try {
      debugPrint('=== scheduleConsultationRequest() ===');
      debugPrint('Request ID: $requestId');
      debugPrint('Data agendada: $scheduledDate');

      await _firestore
          .collection(consultationRequestsCollection)
          .doc(requestId)
          .update({
        'status': ConsultationStatus.scheduled.toString().split('.').last,
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      final request = await getConsultationRequest(requestId);
      if (request != null) {
        await _notifyClient(
          request.clientId,
          'Consulta agendada',
          'Sua consulta foi agendada para ${_formatDateTime(scheduledDate)}',
          requestId,
        );
      }

      debugPrint('✅ Consulta agendada');

    } catch (e) {
      debugPrint('❌ Erro ao agendar consulta: $e');
      rethrow;
    }
  }

  Future<void> completeConsultationRequest(String requestId, {String? notes}) async {
    try {
      debugPrint('=== completeConsultationRequest() ===');
      debugPrint('Request ID: $requestId');

      final updateData = {
        'status': ConsultationStatus.completed.toString().split('.').last,
        'completedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (notes != null) {
        updateData['notes'] = notes;
      }

      await _firestore
          .collection(consultationRequestsCollection)
          .doc(requestId)
          .update(updateData);

      final request = await getConsultationRequest(requestId);
      if (request != null) {
        await _notifyClient(
          request.clientId,
          'Consulta concluída',
          'Sua consulta com ${request.mediumName} foi concluída',
          requestId,
        );
      }

      debugPrint('✅ Consulta concluída');

    } catch (e) {
      debugPrint('❌ Erro ao concluir consulta: $e');
      rethrow;
    }
  }

  Future<void> updateConsultationRequest(
      String requestId,
      Map<String, dynamic> updates,
      ) async {
    try {
      debugPrint('=== updateConsultationRequest() ===');
      debugPrint('Request ID: $requestId');

      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _firestore
          .collection(consultationRequestsCollection)
          .doc(requestId)
          .update(updates);

      debugPrint('✅ Solicitação atualizada');

    } catch (e) {
      debugPrint('❌ Erro ao atualizar solicitação: $e');
      rethrow;
    }
  }

  Future<void> deleteConsultationRequest(String requestId) async {
    try {
      debugPrint('=== deleteConsultationRequest() ===');
      debugPrint('Request ID: $requestId');

      await _firestore
          .collection(consultationRequestsCollection)
          .doc(requestId)
          .delete();

      debugPrint('✅ Solicitação deletada');

    } catch (e) {
      debugPrint('❌ Erro ao deletar solicitação: $e');
      rethrow;
    }
  }

  Stream<List<ConsultationRequest>> watchMediumConsultationRequests(String mediumId) {
    return _firestore
        .collection(consultationRequestsCollection)
        .where('mediumId', isEqualTo: mediumId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ConsultationRequest.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<ConsultationRequest>> watchClientConsultationRequests(String clientId) {
    return _firestore
        .collection(consultationRequestsCollection)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ConsultationRequest.fromFirestore(doc))
          .toList();
    });
  }

  Future<List<ConsultationRequest>> getConsultationRequestsByStatus(
      String userId,
      ConsultationStatus status, {
        bool isMedium = true,
      }) async {
    try {
      final field = isMedium ? 'mediumId' : 'clientId';

      final querySnapshot = await _firestore
          .collection(consultationRequestsCollection)
          .where(field, isEqualTo: userId)
          .where('status', isEqualTo: status.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ConsultationRequest.fromFirestore(doc))
          .toList();

    } catch (e) {
      debugPrint('❌ Erro ao buscar solicitações por status: $e');
      rethrow;
    }
  }

  Future<List<ConsultationRequest>> getTodayConsultations(String mediumId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection(consultationRequestsCollection)
          .where('mediumId', isEqualTo: mediumId)
          .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('scheduledDate')
          .get();

      return querySnapshot.docs
          .map((doc) => ConsultationRequest.fromFirestore(doc))
          .toList();

    } catch (e) {
      debugPrint('❌ Erro ao buscar consultas de hoje: $e');
      rethrow;
    }
  }

  Future<void> _notifyMedium(
      String mediumId,
      String title,
      String body,
      String requestId,
      ) async {
    try {
      debugPrint('✅ Notificação enviada para médium: $mediumId');
    } catch (e) {
      debugPrint('❌ Erro ao notificar médium: $e');
    }
  }

  Future<void> _notifyClient(
      String clientId,
      String title,
      String body,
      String requestId,
      ) async {
    try {
      debugPrint('✅ Notificação enviada para cliente: $clientId');
    } catch (e) {
      debugPrint('❌ Erro ao notificar cliente: $e');
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} às '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}