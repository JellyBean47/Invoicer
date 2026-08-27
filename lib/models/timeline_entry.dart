import 'package:cloud_firestore/cloud_firestore.dart';

class TimelineEntry {
  const TimelineEntry({
    required this.logId,
    required this.businessId,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.timestamp,
    this.oldValue,
    this.newValue,
    this.device = 'mobile',
    this.isManualNote = false,
  });

  final String logId;
  final String businessId;
  final String userId;
  final String entityType;
  final String entityId;
  final String action;
  final String? oldValue;
  final String? newValue;
  final DateTime timestamp;
  final String device;
  final bool isManualNote;

  bool get canEdit => isManualNote;

  String get title {
    switch (action) {
      case 'customer_created':
        return 'Customer created';
      case 'customer_updated':
        return 'Customer updated';
      case 'customer_archived':
        return 'Customer archived';
      case 'customer_restored':
        return 'Customer restored';
      case 'job_created':
        return 'Job created';
      case 'job_updated':
        return 'Job updated';
      case 'job_scheduled':
        return 'Job scheduled';
      case 'job_started':
        return 'Job started';
      case 'job_completed':
        return 'Job completed';
      case 'job_cancelled':
        return 'Job cancelled';
      case 'quote_created':
        return 'Quote created';
      case 'quote_updated':
        return 'Quote updated';
      case 'quote_sent':
        return 'Quote sent';
      case 'quote_accepted':
        return 'Quote accepted';
      case 'quote_rejected':
        return 'Quote rejected';
      case 'quote_expired':
        return 'Quote expired';
      case 'quote_converted':
        return 'Quote converted to job';
      case 'invoice_created':
        return 'Invoice generated';
      case 'invoice_updated':
        return 'Invoice updated';
      case 'invoice_finalized':
        return 'Invoice finalized';
      case 'invoice_cancelled':
        return 'Invoice cancelled';
      case 'invoice_duplicated':
        return 'Invoice duplicated';
      case 'payment_recorded':
        return 'Payment recorded';
      case 'expense_created':
        return 'Expense added';
      case 'expense_updated':
        return 'Expense updated';
      case 'expense_archived':
        return 'Expense archived';
      case 'expense_restored':
        return 'Expense restored';
      case 'note':
        return 'Note';
      default:
        return action.replaceAll('_', ' ');
    }
  }

  String get detail {
    if (action == 'note') return newValue ?? '';
    return newValue ?? '';
  }

  factory TimelineEntry.fromMap(Map<String, dynamic> map) {
    final action = map['action'] as String? ?? '';
    return TimelineEntry(
      logId: map['logId'] as String? ?? '',
      businessId: map['businessId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      entityType: map['entityType'] as String? ?? '',
      entityId: map['entityId'] as String? ?? '',
      action: action,
      oldValue: map['oldValue'] as String?,
      newValue: map['newValue'] as String?,
      timestamp: _readDate(map['timestamp']) ?? DateTime.now(),
      device: map['device'] as String? ?? 'mobile',
      isManualNote: action == 'note' || map['isManualNote'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'businessId': businessId,
      'userId': userId,
      'entityType': entityType,
      'entityId': entityId,
      'action': action,
      'oldValue': oldValue,
      'newValue': newValue,
      'timestamp': Timestamp.fromDate(timestamp),
      'device': device,
      'isManualNote': isManualNote,
    };
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
