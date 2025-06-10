// lib/models/consultation_request_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ConsultationStatus {
  pending,
  scheduled,
  completed,
  cancelled,
}

class ConsultationRequest {
  final String id;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String mediumId;
  final String mediumName;
  final String consultationType;
  final String description;
  final String notes;
  final ConsultationStatus status;
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final DateTime? completedAt;
  final Map<String, dynamic> metadata;

  ConsultationRequest({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.mediumId,
    required this.mediumName,
    required this.consultationType,
    required this.description,
    this.notes = '',
    required this.status,
    required this.createdAt,
    this.scheduledDate,
    this.completedAt,
    this.metadata = const {},
  });

  factory ConsultationRequest.fromMap(Map<String, dynamic> map) {
    return ConsultationRequest(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientEmail: map['clientEmail'] ?? '',
      mediumId: map['mediumId'] ?? '',
      mediumName: map['mediumName'] ?? '',
      consultationType: map['consultationType'] ?? '',
      description: map['description'] ?? '',
      notes: map['notes'] ?? '',
      status: ConsultationStatus.values.firstWhere(
            (e) => e.toString() == 'ConsultationStatus.${map['status']}',
        orElse: () => ConsultationStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      scheduledDate: map['scheduledDate'] != null
          ? (map['scheduledDate'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  factory ConsultationRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return ConsultationRequest.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'mediumId': mediumId,
      'mediumName': mediumName,
      'consultationType': consultationType,
      'description': description,
      'notes': notes,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledDate': scheduledDate != null
          ? Timestamp.fromDate(scheduledDate!)
          : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'metadata': metadata,
    };
  }

  ConsultationRequest copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientEmail,
    String? mediumId,
    String? mediumName,
    String? consultationType,
    String? description,
    String? notes,
    ConsultationStatus? status,
    DateTime? createdAt,
    DateTime? scheduledDate,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ConsultationRequest(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      mediumId: mediumId ?? this.mediumId,
      mediumName: mediumName ?? this.mediumName,
      consultationType: consultationType ?? this.consultationType,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}