// lib/services/mystic_circles_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/models/mystic_circle_model.dart';
import 'package:oraculum/models/shared_reading_model.dart';
import 'package:oraculum/models/circle_invitation_model.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:uuid/uuid.dart';

class MysticCirclesService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final Uuid _uuid = const Uuid();

  // Collections
  static const String circlesCollection = 'mystic_circles';
  static const String readingsCollection = 'shared_readings';
  static const String invitationsCollection = 'circle_invitations';
  static const String challengesCollection = 'weekly_challenges';

  // ========== CIRCLE MANAGEMENT ==========

  /// Criar um novo círculo místico
  Future<String> createCircle({
    required String name,
    required String description,
    required CircleType type,
    required String creatorId,
    required String creatorName,
    CircleSettings? settings,
    List<String>? tags,
    String? imageUrl,
  }) async {
    try {
      debugPrint('=== createCircle() ===');
      debugPrint('Nome: $name');
      debugPrint('Criador: $creatorName');

      final circleId = _uuid.v4();

      final circle = MysticCircle(
        id: circleId,
        name: name,
        description: description,
        creatorId: creatorId,
        memberIds: [creatorId], // Criador é automaticamente membro
        adminIds: [creatorId], // Criador é automaticamente admin
        type: type,
        settings: settings ?? CircleSettings(),
        stats: CircleStats(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrl: imageUrl,
        tags: tags ?? [],
      );

      await _firestore
          .collection(circlesCollection)
          .doc(circleId)
          .set(circle.toMap());

      // Atualizar estatísticas do usuário
      await _updateUserCircleStats(creatorId, increment: true);

      debugPrint('✅ Círculo criado com sucesso: $circleId');
      return circleId;

    } catch (e) {
      debugPrint('❌ Erro ao criar círculo: $e');
      rethrow;
    }
  }

  /// Obter círculos do usuário
  Stream<List<MysticCircle>> getUserCircles(String userId) {
    debugPrint('=== getUserCircles() ===');
    debugPrint('UserId: $userId');

    return _firestore
        .collection(circlesCollection)
        .where('memberIds', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MysticCircle.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Obter um círculo específico
  Future<MysticCircle?> getCircle(String circleId) async {
    try {
      final doc = await _firestore
          .collection(circlesCollection)
          .doc(circleId)
          .get();

      if (doc.exists) {
        return MysticCircle.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erro ao obter círculo: $e');
      return null;
    }
  }

  /// Atualizar círculo
  Future<void> updateCircle(String circleId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _firestore
          .collection(circlesCollection)
          .doc(circleId)
          .update(updates);

      debugPrint('✅ Círculo atualizado: $circleId');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar círculo: $e');
      rethrow;
    }
  }

  /// Excluir círculo (soft delete)
  Future<void> deleteCircle(String circleId, String userId) async {
    try {
      final circle = await getCircle(circleId);
      if (circle == null || !circle.isCreator(userId)) {
        throw Exception('Apenas o criador pode excluir o círculo');
      }

      await _firestore
          .collection(circlesCollection)
          .doc(circleId)
          .update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Notificar todos os membros
      await _notifyCircleMembers(
        circleId,
        'Círculo ${circle.name} foi excluído',
        'circle_deleted',
      );

      debugPrint('✅ Círculo excluído: $circleId');
    } catch (e) {
      debugPrint('❌ Erro ao excluir círculo: $e');
      rethrow;
    }
  }

  // ========== MEMBER MANAGEMENT ==========

  /// Convidar usuário para círculo
  Future<String> inviteToCircle({
    required String circleId,
    required String inviterId,
    required String inviterName,
    required String inviteeEmail,
    String? message,
  }) async {
    try {
      debugPrint('=== inviteToCircle() ===');
      debugPrint('Círculo: $circleId');
      debugPrint('Convidado: $inviteeEmail');

      final circle = await getCircle(circleId);
      if (circle == null) {
        throw Exception('Círculo não encontrado');
      }

      if (!circle.settings.allowMemberInvites && !circle.isAdmin(inviterId)) {
        throw Exception('Apenas administradores podem convidar membros');
      }

      // Verificar se o usuário existe no sistema
      final inviteeDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: inviteeEmail)
          .limit(1)
          .get();

      if (inviteeDoc.docs.isEmpty) {
        throw Exception('Usuário não encontrado no sistema');
      }

      final inviteeId = inviteeDoc.docs.first.id;

      // Verificar se já é membro
      if (circle.isMember(inviteeId)) {
        throw Exception('Usuário já é membro do círculo');
      }

      // Verificar se já existe convite pendente
      final existingInvite = await _firestore
          .collection(invitationsCollection)
          .where('circleId', isEqualTo: circleId)
          .where('inviteeId', isEqualTo: inviteeId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingInvite.docs.isNotEmpty) {
        throw Exception('Já existe um convite pendente para este usuário');
      }

      // Criar convite
      final invitationId = _uuid.v4();
      final invitation = CircleInvitation(
        id: invitationId,
        circleId: circleId,
        circleName: circle.name,
        inviterId: inviterId,
        inviterName: inviterName,
        inviteeId: inviteeId,
        inviteeEmail: inviteeEmail,
        status: InvitationStatus.pending,
        createdAt: DateTime.now(),
        message: message,
      );

      await _firestore
          .collection(invitationsCollection)
          .doc(invitationId)
          .set(invitation.toMap());

      // Enviar notificação push
      await _sendInvitationNotification(invitation);

      debugPrint('✅ Convite criado: $invitationId');
      return invitationId;

    } catch (e) {
      debugPrint('❌ Erro ao convidar usuário: $e');
      rethrow;
    }
  }

  /// Responder a convite
  Future<void> respondToInvitation({
    required String invitationId,
    required bool accept,
  }) async {
    try {
      debugPrint('=== respondToInvitation() ===');
      debugPrint('Convite: $invitationId');
      debugPrint('Aceitar: $accept');

      final invitationDoc = await _firestore
          .collection(invitationsCollection)
          .doc(invitationId)
          .get();

      if (!invitationDoc.exists) {
        throw Exception('Convite não encontrado');
      }

      final invitation = CircleInvitation.fromMap(
        invitationDoc.data()!,
        invitationDoc.id,
      );

      if (invitation.status != InvitationStatus.pending) {
        throw Exception('Convite já foi respondido');
      }

      final newStatus = accept ? InvitationStatus.accepted : InvitationStatus.declined;

      // Atualizar convite
      await _firestore
          .collection(invitationsCollection)
          .doc(invitationId)
          .update({
        'status': newStatus.toString().split('.').last,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (accept) {
        // Adicionar usuário ao círculo
        await _firestore
            .collection(circlesCollection)
            .doc(invitation.circleId)
            .update({
          'memberIds': FieldValue.arrayUnion([invitation.inviteeId]),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        // Atualizar estatísticas
        await _updateUserCircleStats(invitation.inviteeId, increment: true);

        // Notificar outros membros
        await _notifyCircleMembers(
          invitation.circleId,
          '${invitation.inviterName} entrou no círculo',
          'member_joined',
          excludeUserId: invitation.inviteeId,
        );
      }

      debugPrint('✅ Resposta ao convite processada');

    } catch (e) {
      debugPrint('❌ Erro ao responder convite: $e');
      rethrow;
    }
  }

  /// Obter convites pendentes do usuário
  Stream<List<CircleInvitation>> getUserInvitations(String userId) {
    return _firestore
        .collection(invitationsCollection)
        .where('inviteeId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CircleInvitation.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Remover membro do círculo
  Future<void> removeMember({
    required String circleId,
    required String memberId,
    required String removedById,
  }) async {
    try {
      final circle = await getCircle(circleId);
      if (circle == null) {
        throw Exception('Círculo não encontrado');
      }

      // Verificar permissões
      if (!circle.isAdmin(removedById) && removedById != memberId) {
        throw Exception('Apenas administradores podem remover membros');
      }

      // Não pode remover o criador
      if (circle.isCreator(memberId)) {
        throw Exception('O criador não pode ser removido do círculo');
      }

      await _firestore
          .collection(circlesCollection)
          .doc(circleId)
          .update({
        'memberIds': FieldValue.arrayRemove([memberId]),
        'adminIds': FieldValue.arrayRemove([memberId]), // Remove também de admin se for
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Atualizar estatísticas
      await _updateUserCircleStats(memberId, increment: false);

      debugPrint('✅ Membro removido do círculo');

    } catch (e) {
      debugPrint('❌ Erro ao remover membro: $e');
      rethrow;
    }
  }

  // ========== SHARED READINGS ==========

  /// Compartilhar leitura no círculo
  Future<String> shareReading({
    required String circleId,
    required String userId,
    required String userName,
    String? userImageUrl,
    required String title,
    required String description,
    required ReadingType type,
    required Map<String, dynamic> readingData,
    List<String>? tags,
    ReadingVisibility visibility = ReadingVisibility.circle,
    bool isChallenge = false,
    String? challengeId,
  }) async {
    try {
      debugPrint('=== shareReading() ===');
      debugPrint('Círculo: $circleId');
      debugPrint('Usuário: $userName');
      debugPrint('Tipo: $type');

      final circle = await getCircle(circleId);
      if (circle == null || !circle.isMember(userId)) {
        throw Exception('Usuário não é membro do círculo');
      }

      if (!circle.settings.allowSharedReadings) {
        throw Exception('Leituras compartilhadas não são permitidas neste círculo');
      }

      final readingId = _uuid.v4();
      final reading = SharedReading(
        id: readingId,
        circleId: circleId,
        userId: userId,
        userName: userName,
        userImageUrl: userImageUrl,
        title: title,
        description: description,
        type: type,
        readingData: readingData,
        comments: [],
        likedBy: [],
        savedBy: [],
        createdAt: DateTime.now(),
        tags: tags ?? [],
        visibility: visibility,
        isChallenge: isChallenge,
        challengeId: challengeId,
      );

      await _firestore
          .collection(readingsCollection)
          .doc(readingId)
          .set(reading.toMap());

      // Atualizar estatísticas do círculo
      await _updateCircleStats(circleId, type, increment: true);

      // Notificar membros do círculo
      await _notifyCircleMembers(
        circleId,
        '$userName compartilhou uma nova leitura: $title',
        'new_reading',
        excludeUserId: userId,
        data: {'readingId': readingId, 'type': type.toString().split('.').last},
      );

      debugPrint('✅ Leitura compartilhada: $readingId');
      return readingId;

    } catch (e) {
      debugPrint('❌ Erro ao compartilhar leitura: $e');
      rethrow;
    }
  }

  /// Obter leituras de um círculo
  Stream<List<SharedReading>> getCircleReadings(String circleId, {int limit = 20}) {
    return _firestore
        .collection(readingsCollection)
        .where('circleId', isEqualTo: circleId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SharedReading.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Curtir leitura
  Future<void> likeReading(String readingId, String userId) async {
    try {
      await _firestore
          .collection(readingsCollection)
          .doc(readingId)
          .update({
        'likedBy': FieldValue.arrayUnion([userId]),
      });

      debugPrint('✅ Leitura curtida');
    } catch (e) {
      debugPrint('❌ Erro ao curtir leitura: $e');
      rethrow;
    }
  }

  /// Descurtir leitura
  Future<void> unlikeReading(String readingId, String userId) async {
    try {
      await _firestore
          .collection(readingsCollection)
          .doc(readingId)
          .update({
        'likedBy': FieldValue.arrayRemove([userId]),
      });

      debugPrint('✅ Leitura descurtida');
    } catch (e) {
      debugPrint('❌ Erro ao descurtir leitura: $e');
      rethrow;
    }
  }

  /// Adicionar comentário
  Future<void> addComment({
    required String readingId,
    required String userId,
    required String userName,
    String? userImageUrl,
    required String content,
    String? replyToId,
  }) async {
    try {
      final commentId = _uuid.v4();
      final comment = ReadingComment(
        id: commentId,
        userId: userId,
        userName: userName,
        userImageUrl: userImageUrl,
        content: content,
        createdAt: DateTime.now(),
        likedBy: [],
        replyToId: replyToId,
      );

      await _firestore
          .collection(readingsCollection)
          .doc(readingId)
          .update({
        'comments': FieldValue.arrayUnion([comment.toMap()]),
      });

      debugPrint('✅ Comentário adicionado');
    } catch (e) {
      debugPrint('❌ Erro ao adicionar comentário: $e');
      rethrow;
    }
  }

  // ========== DISCOVERY & SEARCH ==========

  /// Descobrir círculos públicos
  Stream<List<MysticCircle>> discoverCircles({
    CircleType? type,
    List<String>? tags,
    String? searchTerm,
    int limit = 10,
  }) {
    Query query = _firestore
        .collection(circlesCollection)
        .where('isActive', isEqualTo: true);

    if (type != null) {
      query = query.where('type', isEqualTo: type.toString().split('.').last);
    }

    // Para círculos públicos apenas
    query = query.where('settings.isPrivate', isEqualTo: false);

    return query
        .orderBy('stats.totalMembers', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      var circles = snapshot.docs.map((doc) {
        return MysticCircle.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Filtrar por termo de busca se fornecido
      if (searchTerm != null && searchTerm.isNotEmpty) {
        circles = circles.where((circle) {
          return circle.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
              circle.description.toLowerCase().contains(searchTerm.toLowerCase()) ||
              circle.tags.any((tag) => tag.toLowerCase().contains(searchTerm.toLowerCase()));
        }).toList();
      }

      // Filtrar por tags se fornecidas
      if (tags != null && tags.isNotEmpty) {
        circles = circles.where((circle) {
          return circle.tags.any((tag) => tags.contains(tag));
        }).toList();
      }

      return circles;
    });
  }

  /// Solicitar entrada em círculo público
  Future<void> requestToJoinCircle({
    required String circleId,
    required String userId,
    required String userName,
    String? message,
  }) async {
    try {
      final circle = await getCircle(circleId);
      if (circle == null) {
        throw Exception('Círculo não encontrado');
      }

      if (circle.isMember(userId)) {
        throw Exception('Você já é membro deste círculo');
      }

      if (circle.settings.isPrivate) {
        throw Exception('Este círculo é privado');
      }

      if (circle.settings.requireApproval) {
        // Criar solicitação de entrada
        final requestId = _uuid.v4();
        await _firestore
            .collection('join_requests')
            .doc(requestId)
            .set({
          'circleId': circleId,
          'userId': userId,
          'userName': userName,
          'message': message,
          'status': 'pending',
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });

        // Notificar administradores
        await _notifyCircleAdmins(
          circleId,
          '$userName solicitou entrada no círculo',
          'join_request',
          data: {'requestId': requestId, 'userId': userId},
        );
      } else {
        // Adicionar diretamente
        await _firestore
            .collection(circlesCollection)
            .doc(circleId)
            .update({
          'memberIds': FieldValue.arrayUnion([userId]),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        await _updateUserCircleStats(userId, increment: true);

        await _notifyCircleMembers(
          circleId,
          '$userName entrou no círculo',
          'member_joined',
          excludeUserId: userId,
        );
      }

      debugPrint('✅ Solicitação de entrada processada');
    } catch (e) {
      debugPrint('❌ Erro na solicitação de entrada: $e');
      rethrow;
    }
  }

  // ========== WEEKLY CHALLENGES ==========

  /// Criar desafio semanal
  Future<String> createWeeklyChallenge({
    required String circleId,
    required String creatorId,
    required String title,
    required String description,
    required ReadingType type,
    required Map<String, dynamic> challengeData,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final circle = await getCircle(circleId);
      if (circle == null || !circle.isAdmin(creatorId)) {
        throw Exception('Apenas administradores podem criar desafios');
      }

      if (!circle.settings.allowWeeklyChallenges) {
        throw Exception('Desafios semanais não são permitidos neste círculo');
      }

      final challengeId = _uuid.v4();
      await _firestore
          .collection(challengesCollection)
          .doc(challengeId)
          .set({
        'circleId': circleId,
        'creatorId': creatorId,
        'title': title,
        'description': description,
        'type': type.toString().split('.').last,
        'challengeData': challengeData,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'participants': [],
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isActive': true,
      });

      // Notificar membros
      await _notifyCircleMembers(
        circleId,
        'Novo desafio semanal: $title',
        'weekly_challenge',
        data: {'challengeId': challengeId, 'type': type.toString().split('.').last},
      );

      debugPrint('✅ Desafio semanal criado: $challengeId');
      return challengeId;

    } catch (e) {
      debugPrint('❌ Erro ao criar desafio: $e');
      rethrow;
    }
  }

  // ========== HELPER METHODS ==========

  /// Atualizar estatísticas do círculo
  Future<void> _updateCircleStats(String circleId, ReadingType type, {required bool increment}) async {
    try {
      final increment_value = increment ? 1 : -1;

      await _firestore
          .collection(circlesCollection)
          .doc(circleId)
          .update({
        'stats.totalReadings': FieldValue.increment(increment_value),
        'stats.lastActivity': Timestamp.fromDate(DateTime.now()),
        'stats.weeklyActivity': FieldValue.increment(increment_value),
        'stats.readingsByType.${type.toString().split('.').last}': FieldValue.increment(increment_value),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('❌ Erro ao atualizar estatísticas do círculo: $e');
    }
  }

  /// Atualizar estatísticas do usuário
  Future<void> _updateUserCircleStats(String userId, {required bool increment}) async {
    try {
      final increment_value = increment ? 1 : -1;

      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'circleStats.totalCircles': FieldValue.increment(increment_value),
        'circleStats.lastActivity': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('❌ Erro ao atualizar estatísticas do usuário: $e');
    }
  }

  /// Notificar membros do círculo
  Future<void> _notifyCircleMembers(
      String circleId,
      String message,
      String type, {
        String? excludeUserId,
        Map<String, String>? data,
      }) async {
    try {
      final circle = await getCircle(circleId);
      if (circle == null) return;

      final memberIds = circle.memberIds
          .where((id) => id != excludeUserId)
          .toList();

      for (final memberId in memberIds) {
        // Aqui você integraria com o PushNotificationService
        // Por exemplo:
        // await Get.find<PushNotificationService>().sendNotificationToUser(
        //   userId: memberId,
        //   title: 'Atividade no Círculo',
        //   body: message,
        //   data: {
        //     'type': type,
        //     'circleId': circleId,
        //     ...?data,
        //   },
        // );
      }

      debugPrint('✅ Notificações enviadas para ${memberIds.length} membros');
    } catch (e) {
      debugPrint('❌ Erro ao notificar membros: $e');
    }
  }

  /// Notificar administradores do círculo
  Future<void> _notifyCircleAdmins(
      String circleId,
      String message,
      String type, {
        Map<String, String>? data,
      }) async {
    try {
      final circle = await getCircle(circleId);
      if (circle == null) return;

      for (final adminId in circle.adminIds) {
        // Integração com PushNotificationService
        // Similar ao método acima
      }

      debugPrint('✅ Notificações enviadas para ${circle.adminIds.length} administradores');
    } catch (e) {
      debugPrint('❌ Erro ao notificar administradores: $e');
    }
  }

  /// Enviar notificação de convite
  Future<void> _sendInvitationNotification(CircleInvitation invitation) async {
    try {
      // Integração com PushNotificationService para enviar notificação
      // await Get.find<PushNotificationService>().sendNotificationToUser(
      //   userId: invitation.inviteeId,
      //   title: 'Convite para Círculo Místico',
      //   body: '${invitation.inviterName} convidou você para ${invitation.circleName}',
      //   data: {
      //     'type': 'circle_invitation',
      //     'invitationId': invitation.id,
      //     'circleId': invitation.circleId,
      //   },
      // );

      debugPrint('✅ Notificação de convite enviada');
    } catch (e) {
      debugPrint('❌ Erro ao enviar notificação de convite: $e');
    }
  }

  // ========== UTILITY METHODS ==========

  /// Verificar se usuário pode acessar círculo
  Future<bool> canAccessCircle(String circleId, String userId) async {
    try {
      final circle = await getCircle(circleId);
      return circle != null && circle.isMember(userId);
    } catch (e) {
      debugPrint('❌ Erro ao verificar acesso: $e');
      return false;
    }
  }

  /// Obter estatísticas gerais dos círculos do usuário
  Future<Map<String, dynamic>> getUserCircleStatistics(String userId) async {
    try {
      final userCircles = await _firestore
          .collection(circlesCollection)
          .where('memberIds', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .get();

      int totalCircles = userCircles.docs.length;
      int adminCircles = 0;
      int createdCircles = 0;
      int totalReadings = 0;

      for (final doc in userCircles.docs) {
        final circle = MysticCircle.fromMap(doc.data(), doc.id);

        if (circle.isCreator(userId)) createdCircles++;
        if (circle.isAdmin(userId)) adminCircles++;
      }

      // Contar leituras compartilhadas pelo usuário
      final userReadings = await _firestore
          .collection(readingsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      totalReadings = userReadings.docs.length;

      return {
        'totalCircles': totalCircles,
        'adminCircles': adminCircles,
        'createdCircles': createdCircles,
        'totalReadingsShared': totalReadings,
        'lastActivity': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      debugPrint('❌ Erro ao obter estatísticas: $e');
      return {};
    }
  }

  /// Buscar círculos por nome ou tag
  Future<List<MysticCircle>> searchCircles(String query, {int limit = 10}) async {
    try {
      // Busca básica por nome (Firestore tem limitações de busca de texto)
      final nameResults = await _firestore
          .collection(circlesCollection)
          .where('isActive', isEqualTo: true)
          .where('settings.isPrivate', isEqualTo: false)
          .orderBy('name')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .limit(limit)
          .get();

      final circles = nameResults.docs.map((doc) {
        return MysticCircle.fromMap(doc.data(), doc.id);
      }).toList();

      return circles;
    } catch (e) {
      debugPrint('❌ Erro na busca: $e');
      return [];
    }
  }

  @override
  void onClose() {
    debugPrint('🧹 MysticCirclesService finalizando...');
    super.onClose();
  }
}