import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../providers/job_providers.dart';
import '../../../services/job_service.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/job_card.dart';

class JobsListScreen extends ConsumerStatefulWidget {
  const JobsListScreen({super.key});

  @override
  ConsumerState<JobsListScreen> createState() => _JobsListScreenState();
}

class _JobsListScreenState extends ConsumerState<JobsListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(jobSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(filteredJobsProvider);
    final filter = ref.watch(jobListFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Jobs')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/jobs/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Job'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(jobSearchQueryProvider.notifier).state = value;
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search jobs, customers, numbers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(jobSearchQueryProvider.notifier).state = '';
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              children: JobListFilter.values.map((value) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(_filterLabel(value)),
                    selected: filter == value,
                    onSelected: (_) {
                      ref.read(jobListFilterProvider.notifier).state = value;
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: jobsAsync.when(
              loading: () => const AppLoading(message: 'Loading jobs...'),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(error.toString(), textAlign: TextAlign.center),
                ),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  final searching =
                      ref.watch(jobSearchQueryProvider).trim().isNotEmpty;
                  if (searching) {
                    return const EmptyState(
                      title: 'No matches',
                      message: 'Try a different search.',
                      icon: Icons.search_off,
                    );
                  }
                  return EmptyState(
                    title: 'No jobs yet',
                    message: 'Create your first job to track work.',
                    actionLabel: 'Create Job',
                    onAction: () => context.push('/jobs/new'),
                    icon: Icons.handyman_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.sm,
                    AppSpacing.screen,
                    88,
                  ),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return JobCard(
                      job: job,
                      onTap: () => context.push('/jobs/${job.jobId}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _filterLabel(JobListFilter filter) {
    switch (filter) {
      case JobListFilter.today:
        return 'Today';
      case JobListFilter.upcoming:
        return 'Upcoming';
      case JobListFilter.inProgress:
        return 'In Progress';
      case JobListFilter.completed:
        return 'Completed';
      case JobListFilter.cancelled:
        return 'Cancelled';
      case JobListFilter.draft:
        return 'Draft';
      case JobListFilter.all:
        return 'All';
    }
  }
}
