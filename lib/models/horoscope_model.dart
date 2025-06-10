import 'package:cloud_firestore/cloud_firestore.dart';

class HoroscopeModel {
  final String id;
  final String sign;
  final DateTime date;
  final String content;
  final DateTime createdAt;

  HoroscopeModel({
    required this.id,
    required this.sign,
    required this.date,
    required this.content,
    required this.createdAt,
  });

  factory HoroscopeModel.fromMap(Map<String, dynamic> map, String id) {
    return HoroscopeModel(
      id: id,
      sign: map['sign'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sign': sign,
      'date': Timestamp.fromDate(date),
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}