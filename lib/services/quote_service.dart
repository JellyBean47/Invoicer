import '../core/utils/app_exception.dart';
import '../core/utils/money.dart';
import '../models/job.dart';
import '../models/quote.dart';
import '../models/quote_item.dart';
import '../models/timeline_entry.dart';
import '../repositories/customer_repository.dart';
import '../repositories/quote_repository.dart';
import '../repositories/timeline_repository.dart';
import 'analytics_service.dart';
import 'customer_service.dart';
import 'job_service.dart';

class QuoteInput {
  const QuoteInput({
    required this.customerId,
    required this.lines,
    required this.taxPercent,
    this.discountCents = 0,
    this.notes = '',
    this.expiryDate,
  });

  final String customerId;
  final List<QuoteLineInput> lines;
  final int taxPercent;
  final int discountCents;
  final String notes;
  final DateTime? expiryDate;
}

class QuoteService {
  QuoteService({
    required QuoteRepository quoteRepository,
    required CustomerRepository customerRepository,
    required TimelineRepository timelineRepository,
    required JobService jobService,
    AnalyticsService? analyticsService,
  })  : _quoteRepository = quoteRepository,
        _customerRepository = customerRepository,
        _timelineRepository = timelineRepository,
        _jobService = jobService,
        _analyticsService = analyticsService;

  final QuoteRepository _quoteRepository;
  final CustomerRepository _customerRepository;
  final TimelineRepository _timelineRepository;
  final JobService _jobService;
  final AnalyticsService? _analyticsService;

  Stream<List<Quote>> watchQuotes(String businessId) {
    return _quoteRepository.watchByBusiness(businessId);
  }

  Stream<List<Quote>> watchQuotesForCustomer({
    required String businessId,
    required String customerId,
  }) {
    return _quoteRepository.watchByCustomer(
      businessId: businessId,
      customerId: customerId,
    );
  }

  Stream<Quote?> watchQuote(String quoteId) {
    return _quoteRepository.watchById(quoteId);
  }

  Future<Quote> createQuote({
    required String businessId,
    required String userId,
    required QuoteInput input,
  }) async {
    final prepared = await _prepare(businessId: businessId, input: input);
    final quoteNumber = await _quoteRepository.nextQuoteNumber(businessId);
    final now = DateTime.now();

    final quote = await _quoteRepository.create(
      quote: Quote(
        quoteId: '',
        businessId: businessId,
        customerId: prepared.customerId,
        quoteNumber: quoteNumber,
        status: QuoteStatus.draft,
        subtotalCents: prepared.breakdown.subtotalCents,
        discountCents: prepared.breakdown.discountCents,
        taxPercent: prepared.breakdown.taxPercent,
        taxAmountCents: prepared.breakdown.taxAmountCents,
        totalCents: prepared.breakdown.totalCents,
        notes: input.notes.trim(),
        expiryDate: input.expiryDate,
        createdAt: now,
        updatedAt: now,
        customerName: prepared.customerName,
      ),
      items: prepared.items,
    );

    await _timeline(
      businessId: businessId,
      userId: userId,
      customerId: prepared.customerId,
      action: 'quote_created',
      detail: '${quote.quoteNumber} — ${Money.formatZar(quote.totalCents)}',
    );

    return quote;
  }

  Future<Quote> updateQuote({
    required String userId,
    required Quote existing,
    required QuoteInput input,
  }) async {
    if (!existing.status.isEditable) {
      throw const AppException(
        'Only draft or sent quotes can be edited.',
      );
    }

    final prepared = await _prepare(
      businessId: existing.businessId,
      input: input,
    );

    final updated = existing.copyWith(
      subtotalCents: prepared.breakdown.subtotalCents,
      discountCents: prepared.breakdown.discountCents,
      taxPercent: prepared.breakdown.taxPercent,
      taxAmountCents: prepared.breakdown.taxAmountCents,
      totalCents: prepared.breakdown.totalCents,
      notes: input.notes.trim(),
      expiryDate: input.expiryDate,
      clearExpiryDate: input.expiryDate == null,
      customerName: prepared.customerName,
      updatedAt: DateTime.now(),
      items: prepared.items,
    );

    // Customer is fixed after create.
    await _quoteRepository.replace(
      quote: Quote(
        quoteId: existing.quoteId,
        businessId: existing.businessId,
        customerId: existing.customerId,
        quoteNumber: existing.quoteNumber,
        status: existing.status,
        subtotalCents: updated.subtotalCents,
        discountCents: updated.discountCents,
        taxPercent: updated.taxPercent,
        taxAmountCents: updated.taxAmountCents,
        totalCents: updated.totalCents,
        notes: updated.notes,
        expiryDate: updated.expiryDate,
        createdAt: existing.createdAt,
        updatedAt: updated.updatedAt,
        customerName: updated.customerName,
        convertedJobId: existing.convertedJobId,
        items: prepared.items,
      ),
      items: prepared.items,
    );

    await _timeline(
      businessId: existing.businessId,
      userId: userId,
      customerId: existing.customerId,
      action: 'quote_updated',
      detail: existing.quoteNumber,
    );

    return (await _quoteRepository.getById(existing.quoteId)) ?? updated;
  }

  Future<Quote> transitionStatus({
    required String userId,
    required Quote quote,
    required QuoteStatus nextStatus,
  }) async {
    QuoteTransitions.assertAllowed(from: quote.status, to: nextStatus);

    // Auto-expire check when sending/accepting past expiry.
    if (nextStatus == QuoteStatus.accepted || nextStatus == QuoteStatus.sent) {
      if (quote.expiryDate != null &&
          quote.expiryDate!.isBefore(DateTime.now()) &&
          nextStatus == QuoteStatus.accepted) {
        throw const AppException(
          'This quote has expired. Mark it as Expired instead.',
        );
      }
    }

    await _quoteRepository.updateFields(
      quoteId: quote.quoteId,
      data: {'status': nextStatus.firestoreValue},
    );

    final action = switch (nextStatus) {
      QuoteStatus.sent => 'quote_sent',
      QuoteStatus.accepted => 'quote_accepted',
      QuoteStatus.rejected => 'quote_rejected',
      QuoteStatus.expired => 'quote_expired',
      QuoteStatus.draft => 'quote_updated',
    };

    await _timeline(
      businessId: quote.businessId,
      userId: userId,
      customerId: quote.customerId,
      action: action,
      detail: quote.quoteNumber,
    );

    return (await _quoteRepository.getById(quote.quoteId)) ??
        quote.copyWith(status: nextStatus);
  }

  /// Converts an accepted quote into a job without retyping essentials.
  Future<Job> convertToJob({
    required String userId,
    required Quote quote,
  }) async {
    var current = quote;
    if (current.status != QuoteStatus.accepted) {
      if (current.status == QuoteStatus.draft ||
          current.status == QuoteStatus.sent) {
        current = await transitionStatus(
          userId: userId,
          quote: current,
          nextStatus: QuoteStatus.accepted,
        );
      } else {
        throw const AppException('Only accepted quotes can convert to a job.');
      }
    }
    if (current.hasConvertedJob) {
      throw const AppException('This quote was already converted to a job.');
    }

    final full = await _quoteRepository.getById(current.quoteId);
    if (full == null) {
      throw const AppException('Quote not found.');
    }

    final description = full.items
        .map(
          (item) =>
              '${item.description} × ${item.quantity} @ ${Money.formatZar(item.unitPriceCents)}',
        )
        .join('\n');

    final title = full.items.isNotEmpty
        ? full.items.first.description
        : 'Work from ${full.quoteNumber}';

    final job = await _jobService.createJob(
      businessId: full.businessId,
      userId: userId,
      input: JobInput(
        customerId: full.customerId,
        title: title.length > 80 ? '${title.substring(0, 77)}...' : title,
        description:
            'Converted from ${full.quoteNumber}\n\n$description\n\nQuote total: ${Money.formatZar(full.totalCents)}',
        address: '',
        priority: JobPriority.normal,
        status: JobStatus.draft,
      ),
    );

    await _quoteRepository.updateFields(
      quoteId: full.quoteId,
      data: {
        'convertedJobId': job.jobId,
        'status': QuoteStatus.accepted.firestoreValue,
      },
    );

    await _timeline(
      businessId: full.businessId,
      userId: userId,
      customerId: full.customerId,
      action: 'quote_converted',
      detail: '${full.quoteNumber} → ${job.jobNumber}',
    );

    await _analyticsService?.logQuoteConverted();
    return job;
  }

  List<Quote> filterQuotes({
    required List<Quote> quotes,
    required String query,
    required QuoteListFilter filter,
  }) {
    return QuoteQuery.filter(
      quotes: quotes,
      query: query,
      filter: filter,
    );
  }

  List<QuoteStatus> availableTransitions(QuoteStatus current) {
    return QuoteTransitions.allowedFrom(current);
  }

  Future<_PreparedQuote> _prepare({
    required String businessId,
    required QuoteInput input,
  }) async {
    if (input.customerId.isEmpty) {
      throw const AppException('Customer is required.');
    }
    if (input.lines.isEmpty) {
      throw const AppException('Add at least one item or labour line.');
    }

    final customer = await _customerRepository.getById(input.customerId);
    if (customer == null || customer.businessId != businessId) {
      throw const AppException('Customer not found.');
    }
    CustomerQuery.ensureCanReceiveWork(customer);

    final items = <QuoteItem>[];
    for (var i = 0; i < input.lines.length; i++) {
      final line = input.lines[i];
      final description = line.description.trim();
      if (description.isEmpty) {
        throw const AppException('Each line needs a description.');
      }
      try {
        final lineTotal = Money.lineTotal(
          quantity: line.quantity,
          unitPriceCents: line.unitPriceCents,
        );
        items.add(
          QuoteItem(
            itemId: '',
            description: description,
            quantity: line.quantity,
            unitPriceCents: line.unitPriceCents,
            lineTotalCents: lineTotal,
            displayOrder: i,
          ),
        );
      } on ArgumentError catch (error) {
        throw AppException(error.message?.toString() ?? 'Invalid line item.');
      }
    }

    try {
      final breakdown = Money.calculate(
        lineTotalsCents: items.map((item) => item.lineTotalCents).toList(),
        discountCents: input.discountCents,
        taxPercent: input.taxPercent,
      );
      return _PreparedQuote(
        customerId: customer.customerId,
        customerName: customer.name,
        items: items,
        breakdown: breakdown,
      );
    } on ArgumentError catch (error) {
      throw AppException(error.message?.toString() ?? 'Invalid quote totals.');
    }
  }

  Future<void> _timeline({
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

class _PreparedQuote {
  const _PreparedQuote({
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.breakdown,
  });

  final String customerId;
  final String customerName;
  final List<QuoteItem> items;
  final MoneyBreakdown breakdown;
}

enum QuoteListFilter {
  draft,
  sent,
  accepted,
  rejected,
  expired,
  all,
}

class QuoteTransitions {
  QuoteTransitions._();

  static const Map<QuoteStatus, Set<QuoteStatus>> _allowed = {
    QuoteStatus.draft: {
      QuoteStatus.sent,
      QuoteStatus.accepted,
      QuoteStatus.rejected,
    },
    QuoteStatus.sent: {
      QuoteStatus.accepted,
      QuoteStatus.rejected,
      QuoteStatus.expired,
      QuoteStatus.draft,
    },
    QuoteStatus.accepted: {},
    QuoteStatus.rejected: {},
    QuoteStatus.expired: {},
  };

  static List<QuoteStatus> allowedFrom(QuoteStatus from) {
    return _allowed[from]?.toList() ?? const [];
  }

  static void assertAllowed({
    required QuoteStatus from,
    required QuoteStatus to,
  }) {
    final allowed = _allowed[from] ?? {};
    if (!allowed.contains(to)) {
      throw AppException(
        'Cannot change quote from ${from.label} to ${to.label}.',
      );
    }
  }
}

class QuoteQuery {
  QuoteQuery._();

  static List<Quote> filter({
    required List<Quote> quotes,
    required String query,
    required QuoteListFilter filter,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return quotes.where((quote) {
      switch (filter) {
        case QuoteListFilter.draft:
          if (quote.status != QuoteStatus.draft) return false;
        case QuoteListFilter.sent:
          if (quote.status != QuoteStatus.sent) return false;
        case QuoteListFilter.accepted:
          if (quote.status != QuoteStatus.accepted) return false;
        case QuoteListFilter.rejected:
          if (quote.status != QuoteStatus.rejected) return false;
        case QuoteListFilter.expired:
          if (quote.status != QuoteStatus.expired) return false;
        case QuoteListFilter.all:
          break;
      }

      if (normalizedQuery.isEmpty) return true;
      final haystack = [
        quote.quoteNumber,
        quote.customerName,
        quote.notes,
        quote.status.label,
        Money.formatZar(quote.totalCents),
      ].join(' ').toLowerCase();
      return haystack.contains(normalizedQuery);
    }).toList();
  }
}
