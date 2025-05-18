import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final DateTime birthDate;
  final String? profileImageUrl;
  final List<String> favoriteReadings;
  final List<String> favoriteReaders;
  final double credits;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.birthDate,
    this.profileImageUrl,
    required this.favoriteReadings,
    required this.favoriteReaders,
    required this.credits,
    required this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      birthDate: (map['birthDate'] as Timestamp).toDate(),
      profileImageUrl: map['profileImageUrl'],
      favoriteReadings: List<String>.from(map['favoriteReadings'] ?? []),
      favoriteReaders: List<String>.from(map['favoriteReaders'] ?? []),
      credits: (map['credits'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLogin: map['lastLogin'] != null
          ? (map['lastLogin'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'birthDate': Timestamp.fromDate(birthDate),
      'profileImageUrl': profileImageUrl,
      'favoriteReadings': favoriteReadings,
      'favoriteReaders': favoriteReaders,
      'credits': credits,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    DateTime? birthDate,
    String? profileImageUrl,
    List<String>? favoriteReadings,
    List<String>? favoriteReaders,
    double? credits,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      favoriteReadings: favoriteReadings ?? this.favoriteReadings,
      favoriteReaders: favoriteReaders ?? this.favoriteReaders,
      credits: credits ?? this.credits,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}