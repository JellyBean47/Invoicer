import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../providers/invoice_providers.dart';
import '../../../services/invoice_service.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/invoice_card.dart';

class InvoicesListScreen extends ConsumerStatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  ConsumerState<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends ConsumerState<InvoicesListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(invoiceSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(filteredInvoicesProvider);
    final filter = ref.watch(invoiceListFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/invoices/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
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
                ref.read(invoiceSearchQueryProvider.notifier).state = value;
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search invoices...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(invoiceSearchQueryProvider.notifier).state =
                              '';
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
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              children: InvoiceListFilter.values.map((value) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(_label(value)),
                    selected: filter == value,
                    onSelected: (_) {
                      ref.read(invoiceListFilterProvider.notifier).state =
                          value;
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: invoicesAsync.when(
              loading: () => const AppLoading(message: 'Loading invoices...'),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (invoices) {
                if (invoices.isEmpty) {
                  return EmptyState(
                    title: 'No invoices yet',
                    message:
                        'Create your first invoice to start tracking revenue.',
                    actionLabel: 'Create Invoice',
                    onAction: () => context.push('/invoices/new'),
                    icon: Icons.receipt_long_outlined,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.sm,
                    AppSpacing.screen,
                    88,
                  ),
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    return InvoiceCard(
                      invoice: invoice,
                      onTap: () =>
                          context.push('/invoices/${invoice.invoiceId}'),
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

  String _label(InvoiceListFilter filter) {
    switch (filter) {
      case InvoiceListFilter.draft:
        return 'Draft';
      case InvoiceListFilter.final_:
        return 'Final';
      case InvoiceListFilter.unpaid:
        return 'Unpaid';
      case InvoiceListFilter.paid:
        return 'Paid';
      case InvoiceListFilter.overdue:
        return 'Overdue';
      case InvoiceListFilter.cancelled:
        return 'Cancelled';
      case InvoiceListFilter.all:
        return 'All';
    }
  }
}
