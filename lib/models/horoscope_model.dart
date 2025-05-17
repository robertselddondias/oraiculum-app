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
      'date': date,
      'content': content,
      'createdAt': createdAt,
    };
  }
}

class Timestamp {
  Timestamp();

  static Timestamp fromDate(DateTime date) => Timestamp();

  DateTime toDate() => DateTime.now();
}