import 'package:cloud_firestore/cloud_firestore.dart';

enum SyncOperation {
  create,
  update,
  archive,
  delete;

  static SyncOperation fromString(String? value) {
    return SyncOperation.values.firstWhere(
      (op) => op.name == value,
      orElse: () => SyncOperation.update,
    );
  }
}

enum SyncStatus {
  pending,
  processing,
  failed,
  completed;

  static SyncStatus fromString(String? value) {
    return SyncStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SyncStatus.pending,
    );
  }
}

class SyncQueueEntry {
  const SyncQueueEntry({
    required this.operationId,
    required this.businessId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
    required this.status,
    this.lastError = '',
  });

  final String operationId;
  final String businessId;
  final String entityType;
  final String entityId;
  final SyncOperation operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final SyncStatus status;
  final String lastError;

  factory SyncQueueEntry.fromMap(Map<String, dynamic> map) {
    return SyncQueueEntry(
      operationId: map['operationId'] as String? ?? '',
      businessId: map['businessId'] as String? ?? '',
      entityType: map['entityType'] as String? ?? '',
      entityId: map['entityId'] as String? ?? '',
      operation: SyncOperation.fromString(map['operation'] as String?),
      payload: Map<String, dynamic>.from(
        map['payload'] as Map<String, dynamic>? ?? const {},
      ),
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      retryCount: map['retryCount'] as int? ?? 0,
      status: SyncStatus.fromString(map['status'] as String?),
      lastError: map['lastError'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'operationId': operationId,
      'businessId': businessId,
      'entityType': entityType,
      'entityId': entityId,
      'operation': operation.name,
      'payload': payload,
      'createdAt': Timestamp.fromDate(createdAt),
      'retryCount': retryCount,
      'status': status.name,
      'lastError': lastError,
    };
  }

  SyncQueueEntry copyWith({
    SyncStatus? status,
    int? retryCount,
    String? lastError,
  }) {
    return SyncQueueEntry(
      operationId: operationId,
      businessId: businessId,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
