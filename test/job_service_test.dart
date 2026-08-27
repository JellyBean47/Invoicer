import 'package:business_buddy/core/utils/app_exception.dart';
import 'package:business_buddy/models/job.dart';
import 'package:business_buddy/services/job_service.dart';
import 'package:flutter_test/flutter_test.dart';

Job _job({
  required JobStatus status,
  DateTime? scheduledDate,
  String title = 'Fix geyser',
}) {
  return Job(
    jobId: 'j1',
    businessId: 'b1',
    customerId: 'c1',
    jobNumber: 'JOB-2026-000001',
    title: title,
    description: 'Leaking',
    address: '1 Main Rd',
    status: status,
    priority: JobPriority.normal,
    scheduledDate: scheduledDate,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    customerName: 'John Smith',
  );
}

void main() {
  group('JobTransitions', () {
    test('allows draft to scheduled', () {
      expect(
        () => JobTransitions.assertAllowed(
          from: JobStatus.draft,
          to: JobStatus.scheduled,
        ),
        returnsNormally,
      );
    });

    test('blocks completed returning to draft', () {
      expect(
        () => JobTransitions.assertAllowed(
          from: JobStatus.completed,
          to: JobStatus.draft,
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('blocks invalid jump from draft to completed', () {
      expect(
        () => JobTransitions.assertAllowed(
          from: JobStatus.draft,
          to: JobStatus.completed,
        ),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('JobQuery', () {
    final now = DateTime(2026, 8, 2, 10);
    final jobs = [
      _job(
        status: JobStatus.scheduled,
        scheduledDate: DateTime(2026, 8, 2, 14),
        title: 'Today job',
      ),
      _job(
        status: JobStatus.scheduled,
        scheduledDate: DateTime(2026, 8, 5, 9),
        title: 'Future job',
      ),
      _job(
        status: JobStatus.completed,
        scheduledDate: DateTime(2026, 8, 1, 9),
        title: 'Done job',
      ),
      _job(
        status: JobStatus.cancelled,
        scheduledDate: DateTime(2026, 8, 3, 9),
        title: 'Cancelled job',
      ),
    ];

    test('filters today jobs', () {
      final result = JobQuery.filter(
        jobs: jobs,
        query: '',
        filter: JobListFilter.today,
        now: now,
      );
      expect(result.length, 1);
      expect(result.first.title, 'Today job');
    });

    test('filters upcoming including today', () {
      final result = JobQuery.filter(
        jobs: jobs,
        query: '',
        filter: JobListFilter.upcoming,
        now: now,
      );
      expect(result.map((j) => j.title), containsAll(['Today job', 'Future job']));
      expect(result.any((j) => j.isCompleted), isFalse);
    });

    test('searches by title', () {
      final result = JobQuery.filter(
        jobs: jobs,
        query: 'future',
        filter: JobListFilter.all,
        now: now,
      );
      expect(result.length, 1);
      expect(result.first.title, 'Future job');
    });
  });
}
