import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../models/customer.dart';

Future<void> showCustomerSmartActions(
  BuildContext context, {
  required Customer customer,
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
              'What would you like to do next?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              customer.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.handyman_outlined),
              title: const Text('Create Job'),
              onTap: () {
                Navigator.pop(context);
                context.push('/jobs/new?customerId=${customer.customerId}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.request_quote_outlined),
              title: const Text('Create Quote'),
              onTap: () {
                Navigator.pop(context);
                context.push('/quotes/new?customerId=${customer.customerId}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Create Invoice'),
              onTap: () {
                Navigator.pop(context);
                context.push(
                  '/invoices/new?customerId=${customer.customerId}',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('View customer'),
              onTap: () {
                Navigator.pop(context);
                context.push('/customers/${customer.customerId}');
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
