import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../providers/customer_providers.dart';
import '../../../services/customer_service.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/customer_card.dart';

class CustomersListScreen extends ConsumerStatefulWidget {
  const CustomersListScreen({super.key});

  @override
  ConsumerState<CustomersListScreen> createState() =>
      _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(customerSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(filteredCustomersProvider);
    final filter = ref.watch(customerListFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/customers/new'),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('New Customer'),
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
                ref.read(customerSearchQueryProvider.notifier).state = value;
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search name, phone, company...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(customerSearchQueryProvider.notifier).state =
                              '';
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: SegmentedButton<CustomerListFilter>(
              segments: const [
                ButtonSegment(
                  value: CustomerListFilter.active,
                  label: Text('Active'),
                ),
                ButtonSegment(
                  value: CustomerListFilter.archived,
                  label: Text('Archived'),
                ),
                ButtonSegment(
                  value: CustomerListFilter.all,
                  label: Text('All'),
                ),
              ],
              selected: {filter},
              onSelectionChanged: (selection) {
                ref.read(customerListFilterProvider.notifier).state =
                    selection.first;
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: customersAsync.when(
              loading: () => const AppLoading(message: 'Loading customers...'),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (customers) {
                if (customers.isEmpty) {
                  final searching =
                      ref.watch(customerSearchQueryProvider).trim().isNotEmpty;
                  if (searching) {
                    return const EmptyState(
                      title: 'No matches',
                      message: 'Try a different name or phone number.',
                      icon: Icons.search_off,
                    );
                  }
                  if (filter == CustomerListFilter.archived) {
                    return const EmptyState(
                      title: 'No archived customers',
                      message: 'Archived customers will appear here.',
                      icon: Icons.archive_outlined,
                    );
                  }
                  return EmptyState(
                    title: 'No customers yet',
                    message:
                        'Create your first customer to get started tracking jobs and invoices.',
                    actionLabel: 'Create Customer',
                    onAction: () => context.push('/customers/new'),
                    icon: Icons.people_outline,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.sm,
                    AppSpacing.screen,
                    88,
                  ),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return CustomerCard(
                      customer: customer,
                      onTap: () =>
                          context.push('/customers/${customer.customerId}'),
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
}
