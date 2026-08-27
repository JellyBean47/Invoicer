import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../models/job.dart';

Future<void> showJobCompletedSmartActions(
  BuildContext context, {
  required Job job,
}) {
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusSheet),
      ),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Job completed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('${job.jobNumber} — ${job.title}'),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Generate Invoice'),
              onTap: () {
                Navigator.pop(context);
                context.push(
                  '/invoices/new?customerId=${job.customerId}&jobId=${job.jobId}',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Record Payment'),
              subtitle: const Text('Open the invoice to record a payment'),
              onTap: () {
                Navigator.pop(context);
                context.push(
                  '/invoices/new?customerId=${job.customerId}&jobId=${job.jobId}',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_repeat_outlined),
              title: const Text('Schedule Follow-up'),
              onTap: () {
                Navigator.pop(context);
                context.push(
                  '/jobs/new?customerId=${job.customerId}',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('View customer'),
              onTap: () {
                Navigator.pop(context);
                context.push('/customers/${job.customerId}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Return to Dashboard'),
              onTap: () {
                Navigator.pop(context);
                context.go('/dashboard');
              },
            ),
          ],
        ),
      );
    },
  );
}
