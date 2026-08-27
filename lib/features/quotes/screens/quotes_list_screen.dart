import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../providers/quote_providers.dart';
import '../../../services/quote_service.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/quote_card.dart';

class QuotesListScreen extends ConsumerStatefulWidget {
  const QuotesListScreen({super.key});

  @override
  ConsumerState<QuotesListScreen> createState() => _QuotesListScreenState();
}

class _QuotesListScreenState extends ConsumerState<QuotesListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(quoteSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quotesAsync = ref.watch(filteredQuotesProvider);
    final filter = ref.watch(quoteListFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quotes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/quotes/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Quote'),
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
                ref.read(quoteSearchQueryProvider.notifier).state = value;
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search quotes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(quoteSearchQueryProvider.notifier).state =
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
              children: QuoteListFilter.values.map((value) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(_label(value)),
                    selected: filter == value,
                    onSelected: (_) {
                      ref.read(quoteListFilterProvider.notifier).state = value;
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: quotesAsync.when(
              loading: () => const AppLoading(message: 'Loading quotes...'),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (quotes) {
                if (quotes.isEmpty) {
                  return EmptyState(
                    title: 'No quotes yet',
                    message:
                        'Create an estimate before starting work. Quotes never affect revenue.',
                    actionLabel: 'Create Quote',
                    onAction: () => context.push('/quotes/new'),
                    icon: Icons.request_quote_outlined,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.sm,
                    AppSpacing.screen,
                    88,
                  ),
                  itemCount: quotes.length,
                  itemBuilder: (context, index) {
                    final quote = quotes[index];
                    return QuoteCard(
                      quote: quote,
                      onTap: () => context.push('/quotes/${quote.quoteId}'),
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

  String _label(QuoteListFilter filter) {
    switch (filter) {
      case QuoteListFilter.draft:
        return 'Draft';
      case QuoteListFilter.sent:
        return 'Sent';
      case QuoteListFilter.accepted:
        return 'Accepted';
      case QuoteListFilter.rejected:
        return 'Rejected';
      case QuoteListFilter.expired:
        return 'Expired';
      case QuoteListFilter.all:
        return 'All';
    }
  }
}
