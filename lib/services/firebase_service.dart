import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/models/tarot_model.dart';
import 'package:oraculum/models/user_model.dart';
import 'package:uuid/uuid.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
  User? get currentUser => _auth.currentUser;
  String? get userId => _auth.currentUser?.uid;

  // Referências de coleções
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get mediumsCollection => _firestore.collection('mediums');
  CollectionReference get appointmentsCollection => _firestore.collection('appointments');
  CollectionReference get horoscopesCollection => _firestore.collection('horoscopes');
  CollectionReference get tarotCardsCollection => _firestore.collection('tarot_cards');
  CollectionReference get tarotReadingsCollection => _firestore.collection('tarot_readings');
  CollectionReference get paymentsCollection => _firestore.collection('payments');
  CollectionReference get creditCardCollection => _firestore.collection('credit_cards');

  // Métodos de usuário
  Future<DocumentSnapshot> getUserData(String userId) {
    return usersCollection.doc(userId).get();
  }

  Future<UserModel?> getUser(String userId) async {
    DocumentSnapshot documentSnapshot = await usersCollection.doc(userId).get();
    if(documentSnapshot.exists) {
      return UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>, documentSnapshot.id);
    }
    return null;
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) {
    return usersCollection.doc(userId).update(data);
  }

  Future<void> createUserData(String userId, Map<String, dynamic> data) {
    return usersCollection.doc(userId).set(data);
  }

  // Métodos de tarô
  Future<void> persistAllCards(List<TarotCard> cards) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (final card in cards) {
        final DocumentReference docRef = tarotCardsCollection.doc(const Uuid().v6());
        batch.set(docRef, card.toMap());
      }
      await batch.commit();
      print('Todas as cartas foram persistidas com sucesso no Firestore.');
    } catch (e) {
      print('Erro ao persistir as cartas no Firestore: $e');
      rethrow;
    }
  }

  Future<QuerySnapshot> getTarotCards() {
    return tarotCardsCollection.get();
  }

  Future<DocumentSnapshot> getTarotCard(String cardId) {
    return tarotCardsCollection.doc(cardId).get();
  }

  // Método melhorado para salvar leituras de tarô, retornando o ID do documento
  Future<String> saveTarotReading(Map<String, dynamic> readingData) async {
    final docRef = await tarotReadingsCollection.add(readingData);
    return docRef.id;
  }

  Future<QuerySnapshot> getUserTarotReadings(String userId) {
    return tarotReadingsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
  }

  // Método para alternar favoritos em leituras de tarô
  Future<void> toggleFavoriteTarotReading(String readingId, bool isFavorite) {
    return tarotReadingsCollection.doc(readingId).update({'isFavorite': isFavorite});
  }

  // Métodos para análise de compatibilidade
  Future<DocumentSnapshot> getCompatibilityAnalysis(String compatibilityId) {
    return _firestore.collection('compatibility_analyses').doc(compatibilityId).get();
  }

  Future<void> saveCompatibilityAnalysis(
      String compatibilityId, Map<String, dynamic> analysisData) {
    return _firestore
        .collection('compatibility_analyses')
        .doc(compatibilityId)
        .set(analysisData);
  }

  // Métodos de médiuns
  Future<QuerySnapshot> getMediums() {
    return mediumsCollection.where('isActive', isEqualTo: true).get();
  }

  Future<DocumentSnapshot> getMediumData(String mediumId) {
    return mediumsCollection.doc(mediumId).get();
  }

  Future<QuerySnapshot> getAvailableMediums() {
    return mediumsCollection
        .where('isActive', isEqualTo: true)
        .where('isAvailable', isEqualTo: true)
        .get();
  }

  // Métodos de agendamento
  Future<void> createAppointment(Map<String, dynamic> appointmentData) {
    return appointmentsCollection.add(appointmentData);
  }

  Future<void> updateAppointment(String appointmentId, Map<String, dynamic> data) {
    return appointmentsCollection.doc(appointmentId).update(data);
  }

  Future<void> updateAppointmentStatus(String appointmentId, String status) {
    return appointmentsCollection.doc(appointmentId).update({'status': status});
  }

  Future<QuerySnapshot> getUserAppointments(String userId) {
    return appointmentsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime', descending: true)
        .get();
  }

  Future<QuerySnapshot> getMediumAppointments(String mediumId) {
    return appointmentsCollection
        .where('mediumId', isEqualTo: mediumId)
        .orderBy('dateTime', descending: false)
        .get();
  }

  // Métodos de horóscopo
  Future<DocumentSnapshot> getDailyHoroscope(String sign, String date) {
    return horoscopesCollection.doc('$sign-$date').get();
  }

  Future<void> saveHoroscope(String documentId, Map<String, dynamic> horoscopeData) {
    return horoscopesCollection.doc(documentId).set(horoscopeData);
  }

  // Métodos de pagamentos
  Future<String> savePaymentRecord(Map<String, dynamic> paymentData) async {
    final docRef = await paymentsCollection.add(paymentData);
    return docRef.id;
  }

  Future<QuerySnapshot> getUserPayments(String userId) {
    return paymentsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();
  }

  Future<QuerySnapshot> getDefaultCreditCard(String userId) {
    return creditCardCollection
        .where('isDefault', isEqualTo: true)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
  }

  // Métodos de storage
  Future<String> uploadProfileImage(String userId, String filePath) async {
    final ref = _storage.ref().child('profile_images/$userId.jpg');
    await ref.putFile(File(filePath));
    return await ref.getDownloadURL();
  }

  Future<String> uploadMediumImage(String mediumId, String filePath) async {
    final ref = _storage.ref().child('medium_images/$mediumId.jpg');
    await ref.putFile(File(filePath));
    return await ref.getDownloadURL();
  }

  // Métodos para upload de imagens de tarô
  Future<String> uploadTarotImage(String cardId, String filePath) async {
    final ref = _storage.ref().child('tarot_cards/$cardId.jpg');
    await ref.putFile(File(filePath));
    return await ref.getDownloadURL();
  }

  // Métodos de favoritos
  Future<void> toggleFavoriteMedium(String userId, String mediumId) async {
    final userDoc = await getUserData(userId);
    final userData = userDoc.data() as Map<String, dynamic>?;

    if (userData != null) {
      final favoriteReaders = List<String>.from(userData['favoriteReaders'] ?? []);

      if (favoriteReaders.contains(mediumId)) {
        favoriteReaders.remove(mediumId);
      } else {
        favoriteReaders.add(mediumId);
      }

      await updateUserData(userId, {'favoriteReaders': favoriteReaders});
    }
  }

  Future<List<String>> getUserFavoriteMediums(String userId) async {
    final userDoc = await getUserData(userId);
    final userData = userDoc.data() as Map<String, dynamic>?;

    if (userData != null) {
      return List<String>.from(userData['favoriteReaders'] ?? []);
    }

    return [];
  }

  // Métodos para favoritos de tarô
  Future<void> toggleFavoriteTarotCard(String userId, String cardId) async {
    final userDoc = await getUserData(userId);
    final userData = userDoc.data() as Map<String, dynamic>?;

    if (userData != null) {
      final favoriteCards = List<String>.from(userData['favoriteCards'] ?? []);

      if (favoriteCards.contains(cardId)) {
        favoriteCards.remove(cardId);
      } else {
        favoriteCards.add(cardId);
      }

      await updateUserData(userId, {'favoriteCards': favoriteCards});
    }
  }

  Future<List<String>> getUserFavoriteTarotCards(String userId) async {
    final userDoc = await getUserData(userId);
    final userData = userDoc.data() as Map<String, dynamic>?;

    if (userData != null) {
      return List<String>.from(userData['favoriteCards'] ?? []);
    }

    return [];
  }

  /// Métodos para gerenciar mapas astrais
  Future<String> saveBirthChart({
    required String userId,
    required String name,
    required String birthDate,
    required String birthTime,
    required String birthPlace,
    required String interpretation,
    required String paymentId,
  }) async {
    try {
      final birthChartData = {
        'userId': userId,
        'name': name,
        'birthDate': birthDate,
        'birthTime': birthTime,
        'birthPlace': birthPlace,
        'interpretation': interpretation,
        'paymentId': paymentId,
        'createdAt': FieldValue.serverTimestamp(),
        'isFavorite': false,
        'tags': _generateTags(name, birthPlace), // Para facilitar buscas
      };

      final docRef = await _firestore.collection('birth_charts').add(birthChartData);
      return docRef.id;
    } catch (e) {
      debugPrint('Erro ao salvar mapa astral: $e');
      throw Exception('Falha ao salvar mapa astral: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserBirthCharts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('birth_charts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Sem nome',
          'birthDate': data['birthDate'] ?? '',
          'birthTime': data['birthTime'] ?? '',
          'birthPlace': data['birthPlace'] ?? '',
          'interpretation': data['interpretation'] ?? '',
          'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
          'paymentId': data['paymentId'] ?? '',
          'isFavorite': data['isFavorite'] ?? false,
          'tags': List<String>.from(data['tags'] ?? []),
        };
      }).toList();
    } catch (e) {
      debugPrint('Erro ao buscar mapas astrais: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFavoriteBirthCharts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('birth_charts')
          .where('userId', isEqualTo: userId)
          .where('isFavorite', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Sem nome',
          'birthDate': data['birthDate'] ?? '',
          'birthTime': data['birthTime'] ?? '',
          'birthPlace': data['birthPlace'] ?? '',
          'interpretation': data['interpretation'] ?? '',
          'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
          'paymentId': data['paymentId'] ?? '',
          'isFavorite': data['isFavorite'] ?? false,
          'tags': List<String>.from(data['tags'] ?? []),
        };
      }).toList();
    } catch (e) {
      debugPrint('Erro ao buscar mapas astrais favoritos: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getBirthChart(String chartId) async {
    try {
      final doc = await _firestore.collection('birth_charts').doc(chartId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'name': data['name'] ?? 'Sem nome',
        'birthDate': data['birthDate'] ?? '',
        'birthTime': data['birthTime'] ?? '',
        'birthPlace': data['birthPlace'] ?? '',
        'interpretation': data['interpretation'] ?? '',
        'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
        'paymentId': data['paymentId'] ?? '',
        'isFavorite': data['isFavorite'] ?? false,
        'tags': List<String>.from(data['tags'] ?? []),
      };
    } catch (e) {
      debugPrint('Erro ao buscar mapa astral: $e');
      return null;
    }
  }

  Future<void> toggleBirthChartFavorite(String chartId, bool isFavorite) async {
    try {
      await _firestore.collection('birth_charts').doc(chartId).update({
        'isFavorite': isFavorite,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erro ao atualizar favorito do mapa astral: $e');
      throw Exception('Falha ao atualizar favorito: $e');
    }
  }

  Future<void> deleteBirthChart(String chartId) async {
    try {
      await _firestore.collection('birth_charts').doc(chartId).delete();
    } catch (e) {
      debugPrint('Erro ao deletar mapa astral: $e');
      throw Exception('Falha ao deletar mapa astral: $e');
    }
  }

  Future<void> updateBirthChart(String chartId, Map<String, dynamic> updates) async {
    try {
      final updateData = {
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('birth_charts').doc(chartId).update(updateData);
    } catch (e) {
      debugPrint('Erro ao atualizar mapa astral: $e');
      throw Exception('Falha ao atualizar mapa astral: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchBirthCharts(String userId, String query) async {
    try {
      final lowercaseQuery = query.toLowerCase();

      // Buscar por tags primeiro (mais eficiente)
      final snapshot = await _firestore
          .collection('birth_charts')
          .where('userId', isEqualTo: userId)
          .where('tags', arrayContains: lowercaseQuery)
          .orderBy('createdAt', descending: true)
          .get();

      final results = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Sem nome',
          'birthDate': data['birthDate'] ?? '',
          'birthTime': data['birthTime'] ?? '',
          'birthPlace': data['birthPlace'] ?? '',
          'interpretation': data['interpretation'] ?? '',
          'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
          'paymentId': data['paymentId'] ?? '',
          'isFavorite': data['isFavorite'] ?? false,
          'tags': List<String>.from(data['tags'] ?? []),
        };
      }).toList();

      // Se não encontrou por tags, buscar todos e filtrar localmente
      if (results.isEmpty) {
        final allCharts = await getUserBirthCharts(userId);
        return allCharts.where((chart) {
          return chart['name'].toString().toLowerCase().contains(lowercaseQuery) ||
              chart['birthPlace'].toString().toLowerCase().contains(lowercaseQuery) ||
              chart['birthDate'].toString().contains(query);
        }).toList();
      }

      return results;
    } catch (e) {
      debugPrint('Erro ao buscar mapas astrais: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getBirthChartStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('birth_charts')
          .where('userId', isEqualTo: userId)
          .get();

      final charts = snapshot.docs;
      final totalCharts = charts.length;
      final favoriteCharts = charts.where((doc) =>
      (doc.data()['isFavorite'] ?? false) == true).length;

      // Agrupar por mês de criação
      final chartsByMonth = <String, int>{};
      for (final doc in charts) {
        final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null) {
          final monthKey = DateFormat('yyyy-MM').format(createdAt);
          chartsByMonth[monthKey] = (chartsByMonth[monthKey] ?? 0) + 1;
        }
      }

      return {
        'totalCharts': totalCharts,
        'favoriteCharts': favoriteCharts,
        'chartsByMonth': chartsByMonth,
        'firstChartDate': charts.isNotEmpty
            ? charts.map((doc) => (doc.data()['createdAt'] as Timestamp?)?.toDate())
            .where((date) => date != null)
            .fold<DateTime?>(null, (earliest, current) =>
        earliest == null || current!.isBefore(earliest) ? current : earliest)
            : null,
      };
    } catch (e) {
      debugPrint('Erro ao obter estatísticas dos mapas astrais: $e');
      return {
        'totalCharts': 0,
        'favoriteCharts': 0,
        'chartsByMonth': <String, int>{},
        'firstChartDate': null,
      };
    }
  }

// Método auxiliar para gerar tags de busca
  List<String> _generateTags(String name, String birthPlace) {
    final tags = <String>[];

    // Adicionar nome em minúsculas e suas palavras
    if (name.isNotEmpty) {
      tags.add(name.toLowerCase());
      tags.addAll(name.toLowerCase().split(' ').where((word) => word.isNotEmpty));
    }

    // Adicionar local de nascimento em minúsculas e suas palavras
    if (birthPlace.isNotEmpty) {
      tags.add(birthPlace.toLowerCase());
      tags.addAll(birthPlace.toLowerCase().split(' ').where((word) => word.isNotEmpty));
    }

    return tags.toSet().toList(); // Remove duplicatas
  }


  // Adicione estes métodos ao FirebaseService existente

  /// Métodos para gerenciar configurações do usuário
  Future<Map<String, dynamic>> getUserSettings(String userId) async {
    try {
      debugPrint('=== getUserSettings() ===');
      debugPrint('UserId: $userId');

      final settingsDoc = await _firestore
          .collection('user_settings')
          .doc(userId)
          .get();

      if (settingsDoc.exists) {
        final data = settingsDoc.data() as Map<String, dynamic>;
        debugPrint('✅ Configurações existentes carregadas: $data');
        return data;
      } else {
        debugPrint('⚠️ Configurações não existem, criando padrões...');

        // Criar configurações padrão automaticamente
        final defaultSettings = {
          'isDarkMode': false,
          'notificationsEnabled': true,
          'emailNotifications': true,
          'language': 'Português',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Salvar as configurações padrão no Firebase
        await _firestore
            .collection('user_settings')
            .doc(userId)
            .set(defaultSettings);

        debugPrint('✅ Configurações padrão criadas e salvas');
        return defaultSettings;
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar configurações: $e');

      // Em caso de erro, ainda retornar configurações padrão para evitar crash
      final defaultSettings = {
        'isDarkMode': false,
        'notificationsEnabled': true,
        'emailNotifications': true,
        'language': 'Português',
      };

      // Tentar criar as configurações padrão mesmo com erro
      try {
        await _firestore
            .collection('user_settings')
            .doc(userId)
            .set({
          ...defaultSettings,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Configurações padrão criadas após erro');
      } catch (createError) {
        debugPrint('❌ Erro ao criar configurações padrão: $createError');
      }

      return defaultSettings;
    }
  }

  Future<void> saveUserSettings(String userId, Map<String, dynamic> settings) async {
    try {
      debugPrint('=== saveUserSettings() ===');
      debugPrint('UserId: $userId');
      debugPrint('Settings: $settings');

      // Adicionar timestamp de atualização
      final settingsWithTimestamp = {
        ...settings,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Verificar se o documento já existe
      final existingDoc = await _firestore
          .collection('user_settings')
          .doc(userId)
          .get();

      if (!existingDoc.exists) {
        settingsWithTimestamp['createdAt'] = FieldValue.serverTimestamp();
        debugPrint('📝 Primeira vez - adicionando createdAt');
      }

      // Usar set com merge para criar ou atualizar
      await _firestore
          .collection('user_settings')
          .doc(userId)
          .set(settingsWithTimestamp, SetOptions(merge: true));

      debugPrint('✅ Configurações salvas com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao salvar configurações: $e');
      throw Exception('Falha ao salvar configurações: $e');
    }
  }

  Future<void> updateUserSetting(String userId, String key, dynamic value) async {
    try {
      debugPrint('=== updateUserSetting() ===');
      debugPrint('UserId: $userId, Key: $key, Value: $value');

      // Primeiro verificar se o documento existe
      final docRef = _firestore.collection('user_settings').doc(userId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        debugPrint('📝 Documento não existe, criando com configurações padrão...');

        // Criar documento com configurações padrão + a nova configuração
        final defaultSettings = {
          'isDarkMode': false,
          'notificationsEnabled': true,
          'emailNotifications': true,
          'language': 'Português',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Sobrescrever com a nova configuração
        defaultSettings[key] = value;

        await docRef.set(defaultSettings);
        debugPrint('✅ Documento criado com configuração $key = $value');
      } else {
        // Documento existe, apenas atualizar
        await docRef.update({
          key: value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Configuração $key atualizada para $value');
      }
    } catch (e) {
      debugPrint('❌ Erro ao atualizar configuração $key: $e');

      // Tentar criar o documento do zero em caso de erro
      try {
        debugPrint('🔄 Tentando criar documento do zero...');
        await _firestore
            .collection('user_settings')
            .doc(userId)
            .set({
          'isDarkMode': key == 'isDarkMode' ? value : false,
          'notificationsEnabled': key == 'notificationsEnabled' ? value : true,
          'emailNotifications': key == 'emailNotifications' ? value : true,
          'language': key == 'language' ? value : 'Português',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint('✅ Documento criado do zero com sucesso');
      } catch (createError) {
        debugPrint('❌ Erro crítico ao criar documento: $createError');
        throw Exception('Falha crítica ao atualizar configuração: $createError');
      }
    }
  }

  /// Método auxiliar para garantir que o documento de configurações existe
  Future<void> ensureUserSettingsExist(String userId) async {
    try {
      debugPrint('=== ensureUserSettingsExist() ===');

      final docRef = _firestore.collection('user_settings').doc(userId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        debugPrint('📝 Criando documento de configurações para novo usuário...');

        await docRef.set({
          'isDarkMode': false,
          'notificationsEnabled': true,
          'emailNotifications': true,
          'language': 'Português',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Documento de configurações criado para usuário: $userId');
      } else {
        debugPrint('✅ Documento de configurações já existe');
      }
    } catch (e) {
      debugPrint('❌ Erro ao garantir existência das configurações: $e');
      // Não fazer throw aqui para não quebrar o fluxo
    }
  }

  /// Deletar todos os dados do usuário no Firestore
  Future<void> deleteAllUserData(String userId) async {
    try {
      debugPrint('=== deleteAllUserData($userId) ===');

      final batch = _firestore.batch();

      // 1. Deletar documento principal do usuário
      final userDocRef = _firestore.collection('users').doc(userId);
      batch.delete(userDocRef);

      // 2. Deletar configurações do usuário
      final settingsDocRef = _firestore.collection('user_settings').doc(userId);
      batch.delete(settingsDocRef);

      // 3. Deletar histórico de pagamentos
      final paymentsQuery = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in paymentsQuery.docs) {
        batch.delete(doc.reference);
      }

      // 4. Deletar outros dados relacionados (adapte conforme suas coleções)
      final collectionsToCheck = [
        'user_favorites',
        'readings_history',
        'user_notifications',
        'user_sessions'
      ];

      for (final collection in collectionsToCheck) {
        try {
          final query = await _firestore
              .collection(collection)
              .where('userId', isEqualTo: userId)
              .get();
          for (final doc in query.docs) {
            batch.delete(doc.reference);
          }
        } catch (e) {
          debugPrint('Collection $collection não existe ou erro: $e');
        }
      }

      await batch.commit();
      debugPrint('✅ Todos os dados do usuário foram deletados');

    } catch (e) {
      debugPrint('❌ Erro ao deletar dados do usuário: $e');
      rethrow;
    }
  }

  /// Deletar imagem de perfil do Storage
  Future<void> deleteProfileImage(String userId) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId');
      await ref.delete();
      debugPrint('✅ Imagem de perfil deletada do Storage');
    } catch (e) {
      debugPrint('❌ Erro ao deletar imagem: $e');
      // Não re-throw pois a imagem pode não existir
    }
  }
}