import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_exception.dart';
import '../../../models/job.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/job_providers.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/status_badge.dart';
import '../widgets/job_smart_actions_sheet.dart';

class JobDetailsScreen extends ConsumerWidget {
  const JobDetailsScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobProvider(jobId));

    return jobAsync.when(
      loading: () => const Scaffold(
        body: AppLoading(message: 'Loading job...'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Job')),
        body: Center(child: Text(error.toString())),
      ),
      data: (job) {
        if (job == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Job')),
            body: const Center(child: Text('Job not found.')),
          );
        }

        final transitions =
            ref.watch(jobServiceProvider).availableTransitions(job.status);

        return Scaffold(
          appBar: AppBar(
            title: Text(job.jobNumber),
            actions: [
              if (!job.isTerminal)
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => context.push('/jobs/${job.jobId}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              job.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          StatusBadge(
                            label: job.status.label,
                            color: job.status.color,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Priority: ${job.priority.label}'),
                      TextButton(
                        onPressed: () =>
                            context.push('/customers/${job.customerId}'),
                        child: Text(
                          job.customerName.isEmpty
                              ? 'View customer'
                              : job.customerName,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoCard(job: job),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.attach_file_outlined),
                  title: const Text('Attachments'),
                  subtitle: const Text('Photo attachments coming later'),
                  trailing: const Icon(Icons.lock_outline),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Attachments arrive in a later phase.'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Update status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (transitions.isEmpty)
                const Text('No further status changes are available.')
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: transitions.map((status) {
                    return FilledButton.tonal(
                      onPressed: () => _transition(context, ref, job, status),
                      child: Text(status.label),
                    );
                  }).toList(),
                ),
              if (job.isCompleted) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () => showJobCompletedSmartActions(
                    context,
                    job: job,
                  ),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Next steps'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _transition(
    BuildContext context,
    WidgetRef ref,
    Job job,
    JobStatus nextStatus,
  ) async {
    if (nextStatus == JobStatus.cancelled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel job?'),
          content: Text('Cancel ${job.jobNumber}? It will remain searchable.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep job'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel job'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    try {
      final updated = await ref.read(jobServiceProvider).transitionStatus(
            userId: user.uid,
            job: job,
            nextStatus: nextStatus,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${nextStatus.label}')),
      );
      if (updated.isCompleted) {
        await showJobCompletedSmartActions(context, job: updated);
      }
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final schedule = job.scheduledDate == null
        ? '—'
        : DateFormat('EEE d MMM yyyy • HH:mm').format(job.scheduledDate!);
    final completed = job.completedAt == null
        ? '—'
        : DateFormat('EEE d MMM yyyy • HH:mm').format(job.completedAt!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _row(context, 'Description', job.description),
            _row(context, 'Address', job.address),
            _row(context, 'Scheduled', schedule),
            _row(context, 'Completed', completed),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final display = value.trim().isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(child: Text(display)),
        ],
      ),
    );
  }
}
