import '../core/utils/app_exception.dart';
import '../models/job.dart';
import '../models/timeline_entry.dart';
import '../repositories/customer_repository.dart';
import '../repositories/job_repository.dart';
import '../repositories/timeline_repository.dart';
import 'analytics_service.dart';
import 'customer_service.dart';

class JobInput {
  const JobInput({
    required this.customerId,
    required this.title,
    required this.description,
    required this.address,
    required this.priority,
    this.scheduledDate,
    this.status = JobStatus.draft,
  });

  final String customerId;
  final String title;
  final String description;
  final String address;
  final JobPriority priority;
  final DateTime? scheduledDate;
  final JobStatus status;
}

class JobService {
  JobService({
    required JobRepository jobRepository,
    required CustomerRepository customerRepository,
    required TimelineRepository timelineRepository,
    AnalyticsService? analyticsService,
  })  : _jobRepository = jobRepository,
        _customerRepository = customerRepository,
        _timelineRepository = timelineRepository,
        _analyticsService = analyticsService;

  final JobRepository _jobRepository;
  final CustomerRepository _customerRepository;
  final TimelineRepository _timelineRepository;
  final AnalyticsService? _analyticsService;

  Stream<List<Job>> watchJobs(String businessId) {
    return _jobRepository.watchByBusiness(businessId);
  }

  Stream<List<Job>> watchJobsForCustomer({
    required String businessId,
    required String customerId,
  }) {
    return _jobRepository.watchByCustomer(
      businessId: businessId,
      customerId: customerId,
    );
  }

  Stream<Job?> watchJob(String jobId) => _jobRepository.watchById(jobId);

  Future<Job> createJob({
    required String businessId,
    required String userId,
    required JobInput input,
  }) async {
    final title = input.title.trim();
    if (title.isEmpty) {
      throw const AppException('Job title is required.');
    }
    if (input.customerId.isEmpty) {
      throw const AppException('Customer is required.');
    }

    final customer = await _customerRepository.getById(input.customerId);
    if (customer == null || customer.businessId != businessId) {
      throw const AppException('Customer not found.');
    }
    CustomerQuery.ensureCanReceiveWork(customer);

    var status = input.status;
    if (input.scheduledDate != null && status == JobStatus.draft) {
      status = JobStatus.scheduled;
    }
    if (status == JobStatus.scheduled && input.scheduledDate == null) {
      throw const AppException('Scheduled jobs need a date and time.');
    }
    JobTransitions.assertCreatable(status);

    final jobNumber = await _jobRepository.nextJobNumber(businessId);
    final now = DateTime.now();
    final job = await _jobRepository.create(
      Job(
        jobId: '',
        businessId: businessId,
        customerId: customer.customerId,
        jobNumber: jobNumber,
        title: title,
        description: input.description.trim(),
        address: input.address.trim().isEmpty
            ? customer.address
            : input.address.trim(),
        scheduledDate: input.scheduledDate,
        status: status,
        priority: input.priority,
        createdAt: now,
        updatedAt: now,
        customerName: customer.name,
      ),
    );

    await _addTimeline(
      businessId: businessId,
      userId: userId,
      customerId: customer.customerId,
      action: 'job_created',
      detail: '${job.jobNumber} — ${job.title}',
    );
    if (job.status == JobStatus.scheduled) {
      await _addTimeline(
        businessId: businessId,
        userId: userId,
        customerId: customer.customerId,
        action: 'job_scheduled',
        detail: job.jobNumber,
      );
    }

    return job;
  }

  Future<Job> updateJob({
    required String userId,
    required Job existing,
    required JobInput input,
  }) async {
    if (existing.isTerminal) {
      throw const AppException(
        'Completed or cancelled jobs cannot be edited. Create a new job instead.',
      );
    }

    final title = input.title.trim();
    if (title.isEmpty) {
      throw const AppException('Job title is required.');
    }

    final customer = await _customerRepository.getById(existing.customerId);
    final updated = existing.copyWith(
      title: title,
      description: input.description.trim(),
      address: input.address.trim(),
      scheduledDate: input.scheduledDate,
      clearScheduledDate: input.scheduledDate == null,
      priority: input.priority,
      customerName: customer?.name ?? existing.customerName,
      updatedAt: DateTime.now(),
    );
    await _jobRepository.update(updated);

    await _addTimeline(
      businessId: existing.businessId,
      userId: userId,
      customerId: existing.customerId,
      action: 'job_updated',
      detail: '${updated.jobNumber} — ${updated.title}',
    );

    return updated;
  }

  Future<Job> transitionStatus({
    required String userId,
    required Job job,
    required JobStatus nextStatus,
  }) async {
    JobTransitions.assertAllowed(from: job.status, to: nextStatus);

    if (nextStatus == JobStatus.scheduled && job.scheduledDate == null) {
      throw const AppException('Add a schedule date before marking as Scheduled.');
    }

    final completedAt =
        nextStatus == JobStatus.completed ? DateTime.now() : null;
    await _jobRepository.updateStatus(
      jobId: job.jobId,
      status: nextStatus,
      completedAt: completedAt,
      clearCompletedAt: nextStatus != JobStatus.completed,
    );

    final action = switch (nextStatus) {
      JobStatus.scheduled => 'job_scheduled',
      JobStatus.inProgress => 'job_started',
      JobStatus.completed => 'job_completed',
      JobStatus.cancelled => 'job_cancelled',
      JobStatus.draft => 'job_updated',
    };

    await _addTimeline(
      businessId: job.businessId,
      userId: userId,
      customerId: job.customerId,
      action: action,
      detail: job.jobNumber,
    );

    final refreshed = await _jobRepository.getById(job.jobId);
    if (nextStatus == JobStatus.completed) {
      await _analyticsService?.logJobCompleted();
    }
    return refreshed ?? job.copyWith(status: nextStatus, completedAt: completedAt);
  }

  List<Job> filterJobs({
    required List<Job> jobs,
    required String query,
    required JobListFilter filter,
    DateTime? now,
  }) {
    return JobQuery.filter(
      jobs: jobs,
      query: query,
      filter: filter,
      now: now ?? DateTime.now(),
    );
  }

  List<JobStatus> availableTransitions(JobStatus current) {
    return JobTransitions.allowedFrom(current);
  }

  Future<void> _addTimeline({
    required String businessId,
    required String userId,
    required String customerId,
    required String action,
    required String detail,
  }) {
    return _timelineRepository.add(
      TimelineEntry(
        logId: '',
        businessId: businessId,
        userId: userId,
        entityType: 'customer',
        entityId: customerId,
        action: action,
        newValue: detail,
        timestamp: DateTime.now(),
      ),
    );
  }
}

enum JobListFilter {
  today,
  upcoming,
  inProgress,
  completed,
  cancelled,
  draft,
  all,
}

class JobTransitions {
  JobTransitions._();

  static const Map<JobStatus, Set<JobStatus>> _allowed = {
    JobStatus.draft: {JobStatus.scheduled, JobStatus.cancelled},
    JobStatus.scheduled: {
      JobStatus.inProgress,
      JobStatus.cancelled,
      JobStatus.draft,
    },
    JobStatus.inProgress: {JobStatus.completed, JobStatus.cancelled},
    JobStatus.completed: {},
    JobStatus.cancelled: {},
  };

  static List<JobStatus> allowedFrom(JobStatus from) {
    return _allowed[from]?.toList() ?? const [];
  }

  static void assertAllowed({required JobStatus from, required JobStatus to}) {
    if (from == JobStatus.completed && to == JobStatus.draft) {
      throw const AppException('Completed jobs cannot return to Draft.');
    }
    final allowed = _allowed[from] ?? {};
    if (!allowed.contains(to)) {
      throw AppException(
        'Cannot change status from ${from.label} to ${to.label}.',
      );
    }
  }

  static void assertCreatable(JobStatus status) {
    if (status == JobStatus.completed || status == JobStatus.cancelled) {
      throw const AppException('New jobs cannot start as completed or cancelled.');
    }
  }
}

class JobQuery {
  JobQuery._();

  static List<Job> filter({
    required List<Job> jobs,
    required String query,
    required JobListFilter filter,
    required DateTime now,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));

    return jobs.where((job) {
      if (!_matchesFilter(job, filter, startOfToday, endOfToday)) {
        return false;
      }
      return _matchesQuery(job, normalizedQuery);
    }).toList();
  }

  static bool _matchesFilter(
    Job job,
    JobListFilter filter,
    DateTime startOfToday,
    DateTime endOfToday,
  ) {
    switch (filter) {
      case JobListFilter.today:
        if (job.scheduledDate == null || job.isTerminal) return false;
        final date = job.scheduledDate!;
        return !date.isBefore(startOfToday) && date.isBefore(endOfToday);
      case JobListFilter.upcoming:
        if (job.scheduledDate == null || job.isTerminal) return false;
        return !job.scheduledDate!.isBefore(startOfToday);
      case JobListFilter.inProgress:
        return job.status == JobStatus.inProgress;
      case JobListFilter.completed:
        return job.isCompleted;
      case JobListFilter.cancelled:
        return job.isCancelled;
      case JobListFilter.draft:
        return job.status == JobStatus.draft;
      case JobListFilter.all:
        return true;
    }
  }

  static bool _matchesQuery(Job job, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;
    final haystack = [
      job.title,
      job.description,
      job.jobNumber,
      job.customerName,
      job.address,
      job.status.label,
      job.priority.label,
    ].join(' ').toLowerCase();
    return haystack.contains(normalizedQuery);
  }
}
