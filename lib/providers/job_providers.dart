import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/job.dart';
import '../repositories/job_repository.dart';
import '../services/job_service.dart';
import 'app_providers.dart';
import 'customer_providers.dart';
import 'telemetry_providers.dart';

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository();
});

final jobServiceProvider = Provider<JobService>((ref) {
  return JobService(
    jobRepository: ref.watch(jobRepositoryProvider),
    customerRepository: ref.watch(customerRepositoryProvider),
    timelineRepository: ref.watch(timelineRepositoryProvider),
    analyticsService: ref.watch(analyticsServiceProvider),
  );
});

final jobSearchQueryProvider = StateProvider<String>((ref) => '');

final jobListFilterProvider =
    StateProvider<JobListFilter>((ref) => JobListFilter.upcoming);

final jobsProvider = StreamProvider<List<Job>>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final businessId = profile?.businessId;
  if (businessId == null || businessId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(jobServiceProvider).watchJobs(businessId);
});

final filteredJobsProvider = Provider<AsyncValue<List<Job>>>((ref) {
  final jobsAsync = ref.watch(jobsProvider);
  final query = ref.watch(jobSearchQueryProvider);
  final filter = ref.watch(jobListFilterProvider);
  final service = ref.watch(jobServiceProvider);

  return jobsAsync.whenData((jobs) {
    return service.filterJobs(
      jobs: jobs,
      query: query,
      filter: filter,
    );
  });
});

final jobProvider = StreamProvider.family<Job?, String>((ref, jobId) {
  return ref.watch(jobServiceProvider).watchJob(jobId);
});

final customerJobsProvider =
    StreamProvider.family<List<Job>, String>((ref, customerId) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final businessId = profile?.businessId;
  if (businessId == null || businessId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(jobServiceProvider).watchJobsForCustomer(
        businessId: businessId,
        customerId: customerId,
      );
});
