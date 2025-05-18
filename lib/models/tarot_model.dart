import 'package:cloud_firestore/cloud_firestore.dart';

class TarotCard {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final String uprightMeaning;
  final String reversedMeaning;
  final String suit; // Arcanos Maiores, Copas, Espadas, Ouros, Paus
  final int number;
  final List<String> keywords;

  TarotCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.uprightMeaning,
    required this.reversedMeaning,
    required this.suit,
    required this.number,
    required this.keywords,
  });

  factory TarotCard.fromMap(Map<String, dynamic> map, String id) {
    return TarotCard(
      id: id,
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      uprightMeaning: map['uprightMeaning'] ?? '',
      reversedMeaning: map['reversedMeaning'] ?? '',
      suit: map['suit'] ?? '',
      number: map['number'] ?? 0,
      keywords: List<String>.from(map['keywords'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'uprightMeaning': uprightMeaning,
      'reversedMeaning': reversedMeaning,
      'suit': suit,
      'number': number,
      'keywords': keywords,
    };
  }
}

class TarotReading {
  final String id;
  final String userId;
  final List<String> cardIds;
  final String interpretation;
  final DateTime createdAt;
  final bool isFavorite;

  TarotReading({
    required this.id,
    required this.userId,
    required this.cardIds,
    required this.interpretation,
    required this.createdAt,
    this.isFavorite = false,
  });

  factory TarotReading.fromMap(Map<String, dynamic> map, String id) {
    return TarotReading(
      id: id,
      userId: map['userId'] ?? '',
      cardIds: List<String>.from(map['cardIds'] ?? []),
      interpretation: map['interpretation'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'cardIds': cardIds,
      'interpretation': interpretation,
      'createdAt': Timestamp.fromDate(createdAt),
      'isFavorite': isFavorite,
    };
  }
}