import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oraculum/models/mystic_circle_model.dart';

class SharedReading {
  final String id;
  final String circleId;
  final String userId;
  final String userName;
  final String? userImageUrl;
  final String title;
  final String description;
  final ReadingType type;
  final Map<String, dynamic> readingData;
  final List<ReadingComment> comments;
  final List<String> likedBy;
  final List<String> savedBy;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final bool isChallenge;
  final String? challengeId;
  final List<String> tags;
  final ReadingVisibility visibility;

  SharedReading({
    required this.id,
    required this.circleId,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    required this.title,
    required this.description,
    required this.type,
    required this.readingData,
    required this.comments,
    required this.likedBy,
    required this.savedBy,
    required this.createdAt,
    this.scheduledFor,
    this.isChallenge = false,
    this.challengeId,
    required this.tags,
    this.visibility = ReadingVisibility.circle,
  });

  factory SharedReading.fromMap(Map<String, dynamic> map, String id) {
    return SharedReading(
      id: id,
      circleId: map['circleId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userImageUrl: map['userImageUrl'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: ReadingType.values.firstWhere(
            (e) => e.toString().split('.').last == map['type'],
        orElse: () => ReadingType.tarot,
      ),
      readingData: Map<String, dynamic>.from(map['readingData'] ?? {}),
      comments: (map['comments'] as List<dynamic>?)
          ?.map((c) => ReadingComment.fromMap(c as Map<String, dynamic>))
          .toList() ?? [],
      likedBy: List<String>.from(map['likedBy'] ?? []),
      savedBy: List<String>.from(map['savedBy'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledFor: (map['scheduledFor'] as Timestamp?)?.toDate(),
      isChallenge: map['isChallenge'] ?? false,
      challengeId: map['challengeId'],
      tags: List<String>.from(map['tags'] ?? []),
      visibility: ReadingVisibility.values.firstWhere(
            (e) => e.toString().split('.').last == map['visibility'],
        orElse: () => ReadingVisibility.circle,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'circleId': circleId,
      'userId': userId,
      'userName': userName,
      'userImageUrl': userImageUrl,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'readingData': readingData,
      'comments': comments.map((c) => c.toMap()).toList(),
      'likedBy': likedBy,
      'savedBy': savedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledFor': scheduledFor != null ? Timestamp.fromDate(scheduledFor!) : null,
      'isChallenge': isChallenge,
      'challengeId': challengeId,
      'tags': tags,
      'visibility': visibility.toString().split('.').last,
    };
  }

  bool isLikedBy(String userId) => likedBy.contains(userId);
  bool isSavedBy(String userId) => savedBy.contains(userId);
  int get likesCount => likedBy.length;
  int get commentsCount => comments.length;
}

enum ReadingVisibility {
  circle,
  members,
  admins,
}

class ReadingComment {
  final String id;
  final String userId;
  final String userName;
  final String? userImageUrl;
  final String content;
  final DateTime createdAt;
  final List<String> likedBy;
  final String? replyToId;

  ReadingComment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    required this.content,
    required this.createdAt,
    required this.likedBy,
    this.replyToId,
  });

  factory ReadingComment.fromMap(Map<String, dynamic> map) {
    return ReadingComment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userImageUrl: map['userImageUrl'],
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likedBy: List<String>.from(map['likedBy'] ?? []),
      replyToId: map['replyToId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userImageUrl': userImageUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'likedBy': likedBy,
      'replyToId': replyToId,
    };
  }
}