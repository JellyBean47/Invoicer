import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum JobStatus {
  draft,
  scheduled,
  inProgress,
  completed,
  cancelled;

  static JobStatus fromString(String? value) {
    switch (value) {
      case 'scheduled':
        return JobStatus.scheduled;
      case 'in_progress':
        return JobStatus.inProgress;
      case 'completed':
        return JobStatus.completed;
      case 'cancelled':
        return JobStatus.cancelled;
      default:
        return JobStatus.draft;
    }
  }

  String get firestoreValue {
    switch (this) {
      case JobStatus.inProgress:
        return 'in_progress';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case JobStatus.draft:
        return 'Draft';
      case JobStatus.scheduled:
        return 'Scheduled';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case JobStatus.draft:
        return AppColors.statusDraft;
      case JobStatus.scheduled:
        return AppColors.statusScheduled;
      case JobStatus.inProgress:
        return AppColors.statusInProgress;
      case JobStatus.completed:
        return AppColors.statusCompleted;
      case JobStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }
}

enum JobPriority {
  low,
  normal,
  high,
  emergency;

  static JobPriority fromString(String? value) {
    switch (value) {
      case 'low':
        return JobPriority.low;
      case 'high':
        return JobPriority.high;
      case 'emergency':
        return JobPriority.emergency;
      default:
        return JobPriority.normal;
    }
  }

  String get firestoreValue => name;

  String get label {
    switch (this) {
      case JobPriority.low:
        return 'Low';
      case JobPriority.normal:
        return 'Normal';
      case JobPriority.high:
        return 'High';
      case JobPriority.emergency:
        return 'Emergency';
    }
  }
}

class Job {
  const Job({
    required this.jobId,
    required this.businessId,
    required this.customerId,
    required this.jobNumber,
    required this.title,
    required this.description,
    required this.address,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.scheduledDate,
    this.completedAt,
    this.customerName = '',
  });

  final String jobId;
  final String businessId;
  final String customerId;
  final String jobNumber;
  final String title;
  final String description;
  final String address;
  final DateTime? scheduledDate;
  final JobStatus status;
  final JobPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  /// Denormalized for list display (optional).
  final String customerName;

  bool get isCompleted => status == JobStatus.completed;
  bool get isCancelled => status == JobStatus.cancelled;
  bool get isTerminal => isCompleted || isCancelled;
  bool get canGenerateInvoice => isCompleted;

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      jobId: map['jobId'] as String? ?? '',
      businessId: map['businessId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      jobNumber: map['jobNumber'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      address: map['address'] as String? ?? '',
      scheduledDate: _readDate(map['scheduledDate']),
      status: JobStatus.fromString(map['status'] as String?),
      priority: JobPriority.fromString(map['priority'] as String?),
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _readDate(map['updatedAt']) ?? DateTime.now(),
      completedAt: _readDate(map['completedAt']),
      customerName: map['customerName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'businessId': businessId,
      'customerId': customerId,
      'jobNumber': jobNumber,
      'title': title,
      'description': description,
      'address': address,
      'scheduledDate':
          scheduledDate == null ? null : Timestamp.fromDate(scheduledDate!),
      'status': status.firestoreValue,
      'priority': priority.firestoreValue,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt':
          completedAt == null ? null : Timestamp.fromDate(completedAt!),
      'customerName': customerName,
    };
  }

  Job copyWith({
    String? title,
    String? description,
    String? address,
    DateTime? scheduledDate,
    bool clearScheduledDate = false,
    JobStatus? status,
    JobPriority? priority,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    String? customerName,
  }) {
    return Job(
      jobId: jobId,
      businessId: businessId,
      customerId: customerId,
      jobNumber: jobNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      address: address ?? this.address,
      scheduledDate:
          clearScheduledDate ? null : (scheduledDate ?? this.scheduledDate),
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      customerName: customerName ?? this.customerName,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
