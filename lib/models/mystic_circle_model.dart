import 'package:cloud_firestore/cloud_firestore.dart';

enum CircleType {
  friends,
  family,
  studyGroup,
  open,
}

enum ReadingType {
  tarot,
  astrology,
  oracle,
  runes,
  numerology,
}

enum CircleRole {
  creator,
  admin,
  member,
}

class MysticCircle {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final List<String> memberIds;
  final List<String> adminIds;
  final CircleType type;
  final CircleSettings settings;
  final CircleStats stats;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;
  final List<String> tags;
  final bool isActive;

  MysticCircle({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.memberIds,
    required this.adminIds,
    required this.type,
    required this.settings,
    required this.stats,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    required this.tags,
    this.isActive = true,
  });

  factory MysticCircle.fromMap(Map<String, dynamic> map, String id) {
    return MysticCircle(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      creatorId: map['creatorId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      adminIds: List<String>.from(map['adminIds'] ?? []),
      type: CircleType.values.firstWhere(
            (e) => e.toString().split('.').last == map['type'],
        orElse: () => CircleType.friends,
      ),
      settings: CircleSettings.fromMap(map['settings'] ?? {}),
      stats: CircleStats.fromMap(map['stats'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'],
      tags: List<String>.from(map['tags'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'type': type.toString().split('.').last,
      'settings': settings.toMap(),
      'stats': stats.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'imageUrl': imageUrl,
      'tags': tags,
      'isActive': isActive,
    };
  }

  MysticCircle copyWith({
    String? name,
    String? description,
    List<String>? memberIds,
    List<String>? adminIds,
    CircleSettings? settings,
    CircleStats? stats,
    DateTime? updatedAt,
    String? imageUrl,
    List<String>? tags,
    bool? isActive,
  }) {
    return MysticCircle(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      type: type,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
    );
  }

  bool isCreator(String userId) => creatorId == userId;
  bool isAdmin(String userId) => adminIds.contains(userId) || isCreator(userId);
  bool isMember(String userId) => memberIds.contains(userId);
  int get totalMembers => memberIds.length;
}

class CircleSettings {
  final bool isPrivate;
  final bool allowMemberInvites;
  final bool requireApproval;
  final bool allowSharedReadings;
  final bool allowComments;
  final bool allowWeeklyChallenges;
  final int maxMembers;
  final List<String> bannedWords;

  CircleSettings({
    this.isPrivate = true,
    this.allowMemberInvites = true,
    this.requireApproval = false,
    this.allowSharedReadings = true,
    this.allowComments = true,
    this.allowWeeklyChallenges = true,
    this.maxMembers = 50,
    this.bannedWords = const [],
  });

  factory CircleSettings.fromMap(Map<String, dynamic> map) {
    return CircleSettings(
      isPrivate: map['isPrivate'] ?? true,
      allowMemberInvites: map['allowMemberInvites'] ?? true,
      requireApproval: map['requireApproval'] ?? false,
      allowSharedReadings: map['allowSharedReadings'] ?? true,
      allowComments: map['allowComments'] ?? true,
      allowWeeklyChallenges: map['allowWeeklyChallenges'] ?? true,
      maxMembers: map['maxMembers'] ?? 50,
      bannedWords: List<String>.from(map['bannedWords'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isPrivate': isPrivate,
      'allowMemberInvites': allowMemberInvites,
      'requireApproval': requireApproval,
      'allowSharedReadings': allowSharedReadings,
      'allowComments': allowComments,
      'allowWeeklyChallenges': allowWeeklyChallenges,
      'maxMembers': maxMembers,
      'bannedWords': bannedWords,
    };
  }
}

class CircleStats {
  final int totalReadings;
  final int totalComments;
  final int weeklyActivity;
  final DateTime? lastActivity;
  final Map<ReadingType, int> readingsByType;

  CircleStats({
    this.totalReadings = 0,
    this.totalComments = 0,
    this.weeklyActivity = 0,
    this.lastActivity,
    this.readingsByType = const {},
  });

  factory CircleStats.fromMap(Map<String, dynamic> map) {
    final readingsByTypeMap = map['readingsByType'] as Map<String, dynamic>? ?? {};
    final readingsByType = <ReadingType, int>{};

    for (final entry in readingsByTypeMap.entries) {
      final type = ReadingType.values.firstWhere(
            (e) => e.toString().split('.').last == entry.key,
        orElse: () => ReadingType.tarot,
      );
      readingsByType[type] = entry.value as int;
    }

    return CircleStats(
      totalReadings: map['totalReadings'] ?? 0,
      totalComments: map['totalComments'] ?? 0,
      weeklyActivity: map['weeklyActivity'] ?? 0,
      lastActivity: (map['lastActivity'] as Timestamp?)?.toDate(),
      readingsByType: readingsByType,
    );
  }

  Map<String, dynamic> toMap() {
    final readingsByTypeMap = <String, dynamic>{};
    for (final entry in readingsByType.entries) {
      readingsByTypeMap[entry.key.toString().split('.').last] = entry.value;
    }

    return {
      'totalReadings': totalReadings,
      'totalComments': totalComments,
      'weeklyActivity': weeklyActivity,
      'lastActivity': lastActivity != null ? Timestamp.fromDate(lastActivity!) : null,
      'readingsByType': readingsByTypeMap,
    };
  }
}