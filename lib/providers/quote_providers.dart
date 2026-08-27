import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quote.dart';
import '../repositories/quote_repository.dart';
import '../services/quote_service.dart';
import 'app_providers.dart';
import 'customer_providers.dart';
import 'job_providers.dart';
import 'telemetry_providers.dart';

final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  return QuoteRepository();
});

final quoteServiceProvider = Provider<QuoteService>((ref) {
  return QuoteService(
    quoteRepository: ref.watch(quoteRepositoryProvider),
    customerRepository: ref.watch(customerRepositoryProvider),
    timelineRepository: ref.watch(timelineRepositoryProvider),
    jobService: ref.watch(jobServiceProvider),
    analyticsService: ref.watch(analyticsServiceProvider),
  );
});

final quoteSearchQueryProvider = StateProvider<String>((ref) => '');

final quoteListFilterProvider =
    StateProvider<QuoteListFilter>((ref) => QuoteListFilter.all);

final quotesProvider = StreamProvider<List<Quote>>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final businessId = profile?.businessId;
  if (businessId == null || businessId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(quoteServiceProvider).watchQuotes(businessId);
});

final filteredQuotesProvider = Provider<AsyncValue<List<Quote>>>((ref) {
  final quotesAsync = ref.watch(quotesProvider);
  final query = ref.watch(quoteSearchQueryProvider);
  final filter = ref.watch(quoteListFilterProvider);
  final service = ref.watch(quoteServiceProvider);

  return quotesAsync.whenData((quotes) {
    return service.filterQuotes(
      quotes: quotes,
      query: query,
      filter: filter,
    );
  });
});

final quoteProvider = StreamProvider.family<Quote?, String>((ref, quoteId) {
  return ref.watch(quoteServiceProvider).watchQuote(quoteId);
});

final customerQuotesProvider =
    StreamProvider.family<List<Quote>, String>((ref, customerId) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final businessId = profile?.businessId;
  if (businessId == null || businessId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(quoteServiceProvider).watchQuotesForCustomer(
        businessId: businessId,
        customerId: customerId,
      );
});
