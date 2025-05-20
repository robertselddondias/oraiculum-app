import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

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
        final DocumentReference docRef = tarotCardsCollection.doc(Uuid().v6());
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
}