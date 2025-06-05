import 'package:cloud_firestore/cloud_firestore.dart';

class CircleInvitation {
  final String id;
  final String circleId;
  final String circleName;
  final String inviterId;
  final String inviterName;
  final String inviteeId;
  final String inviteeEmail;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? message;

  CircleInvitation({
    required this.id,
    required this.circleId,
    required this.circleName,
    required this.inviterId,
    required this.inviterName,
    required this.inviteeId,
    required this.inviteeEmail,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.message,
  });

  factory CircleInvitation.fromMap(Map<String, dynamic> map, String id) {
    return CircleInvitation(
      id: id,
      circleId: map['circleId'] ?? '',
      circleName: map['circleName'] ?? '',
      inviterId: map['inviterId'] ?? '',
      inviterName: map['inviterName'] ?? '',
      inviteeId: map['inviteeId'] ?? '',
      inviteeEmail: map['inviteeEmail'] ?? '',
      status: InvitationStatus.values.firstWhere(
            (e) => e.toString().split('.').last == map['status'],
        orElse: () => InvitationStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (map['respondedAt'] as Timestamp?)?.toDate(),
      message: map['message'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'circleId': circleId,
      'circleName': circleName,
      'inviterId': inviterId,
      'inviterName': inviterName,
      'inviteeId': inviteeId,
      'inviteeEmail': inviteeEmail,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'message': message,
    };
  }
}

enum InvitationStatus {
  pending,
  accepted,
  declined,
  expired,
}