import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/utils/app_exception.dart';
import '../models/job.dart';

class JobRepository {
  JobRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(FirestoreCollections.jobs);
  }

  DocumentReference<Map<String, dynamic>> _doc(String jobId) {
    return _collection.doc(jobId);
  }

  Stream<List<Job>> watchByBusiness(String businessId) {
    return _collection
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Job.fromMap(doc.data())).toList(),
        );
  }

  Stream<List<Job>> watchByCustomer({
    required String businessId,
    required String customerId,
  }) {
    return _collection
        .where('businessId', isEqualTo: businessId)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Job.fromMap(doc.data())).toList(),
        );
  }

  Stream<Job?> watchById(String jobId) {
    return _doc(jobId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return Job.fromMap(snapshot.data()!);
    });
  }

  Future<Job?> getById(String jobId) async {
    try {
      final snapshot = await _doc(jobId).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return Job.fromMap(snapshot.data()!);
    } on FirebaseException catch (_) {
      throw const AppException('Unable to load job.');
    }
  }

  /// Atomically increments business jobCounter and returns JOB-YYYY-000001.
  Future<String> nextJobNumber(String businessId) async {
    try {
      final businessRef =
          _firestore.collection(FirestoreCollections.businesses).doc(businessId);
      return _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(businessRef);
        if (!snapshot.exists) {
          throw const AppException('Business not found.');
        }
        final current = (snapshot.data()?['jobCounter'] as int?) ?? 0;
        final next = current + 1;
        transaction.update(businessRef, {
          'jobCounter': next,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final year = DateTime.now().year;
        return 'JOB-$year-${next.toString().padLeft(6, '0')}';
      });
    } on AppException {
      rethrow;
    } on FirebaseException catch (_) {
      throw const AppException('Unable to generate job number.');
    }
  }

  Future<Job> create(Job job) async {
    try {
      final ref = _collection.doc();
      final created = Job(
        jobId: ref.id,
        businessId: job.businessId,
        customerId: job.customerId,
        jobNumber: job.jobNumber,
        title: job.title,
        description: job.description,
        address: job.address,
        scheduledDate: job.scheduledDate,
        status: job.status,
        priority: job.priority,
        createdAt: job.createdAt,
        updatedAt: job.updatedAt,
        completedAt: job.completedAt,
        customerName: job.customerName,
      );
      await ref.set(created.toMap());
      return created;
    } on FirebaseException catch (_) {
      throw const AppException('Unable to create job.');
    }
  }

  Future<void> update(Job job) async {
    try {
      await _doc(job.jobId).set({
        ...job.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (_) {
      throw const AppException('Unable to update job.');
    }
  }

  Future<void> updateStatus({
    required String jobId,
    required JobStatus status,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) async {
    try {
      final data = <String, dynamic>{
        'status': status.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (clearCompletedAt) {
        data['completedAt'] = null;
      } else if (completedAt != null) {
        data['completedAt'] = Timestamp.fromDate(completedAt);
      }
      await _doc(jobId).update(data);
    } on FirebaseException catch (_) {
      throw const AppException('Unable to update job status.');
    }
  }
}
