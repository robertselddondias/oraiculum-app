import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

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

  Future<void> updateUserData(String userId, Map<String, dynamic> data) {
    return usersCollection.doc(userId).update(data);
  }

  Future<void> createUserData(String userId, Map<String, dynamic> data) {
    return usersCollection.doc(userId).set(data);
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

  // Métodos de cartas de tarot
  Future<QuerySnapshot> getTarotCards() {
    return tarotCardsCollection.get();
  }

  Future<DocumentSnapshot> getTarotCard(String cardId) {
    return tarotCardsCollection.doc(cardId).get();
  }

  Future<void> saveTarotReading(Map<String, dynamic> readingData) {
    return tarotReadingsCollection.add(readingData);
  }

  Future<QuerySnapshot> getUserTarotReadings(String userId) {
    return tarotReadingsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<void> toggleFavoriteTarotReading(String readingId, bool isFavorite) {
    return tarotReadingsCollection.doc(readingId).update({'isFavorite': isFavorite});
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
}