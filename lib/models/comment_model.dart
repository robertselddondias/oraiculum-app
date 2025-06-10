// lib/models/comment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String text;
  final String userId;
  final String username;
  final String? userAvatarUrl;
  final Timestamp timestamp;

  CommentModel({
    required this.id,
    required this.text,
    required this.userId,
    required this.username,
    this.userAvatarUrl,
    required this.timestamp,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      id: id,
      text: map['text'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      userAvatarUrl: map['userAvatarUrl'],
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'userId': userId,
      'username': username,
      'userAvatarUrl': userAvatarUrl,
      'timestamp': timestamp,
    };
  }
}