import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/app_exception.dart';
import '../core/utils/money.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/job.dart';
import '../models/timeline_entry.dart';
import '../repositories/customer_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/job_repository.dart';
import '../repositories/timeline_repository.dart';
import 'analytics_service.dart';
import 'customer_service.dart';
import 'notification_service.dart';

class InvoiceInput {
  const InvoiceInput({
    required this.customerId,
    required this.lines,
    required this.taxPercent,
    required this.issueDate,
    this.jobId = '',
    this.discountCents = 0,
    this.notes = '',
    this.dueDate,
  });

  final String customerId;
  final String jobId;
  final List<InvoiceLineInput> lines;
  final int taxPercent;
  final int discountCents;
  final String notes;
  final DateTime issueDate;
  final DateTime? dueDate;
}

class InvoiceService {
  InvoiceService({
    required InvoiceRepository invoiceRepository,
    required CustomerRepository customerRepository,
    required TimelineRepository timelineRepository,
    required JobRepository jobRepository,
    NotificationService? notificationService,
    AnalyticsService? analyticsService,
  })  : _invoiceRepository = invoiceRepository,
        _customerRepository = customerRepository,
        _timelineRepository = timelineRepository,
        _jobRepository = jobRepository,
        _notificationService = notificationService,
        _analyticsService = analyticsService;

  final InvoiceRepository _invoiceRepository;
  final CustomerRepository _customerRepository;
  final TimelineRepository _timelineRepository;
  final JobRepository _jobRepository;
  final NotificationService? _notificationService;
  final AnalyticsService? _analyticsService;

  Stream<List<Invoice>> watchInvoices(String businessId) {
    return _invoiceRepository.watchByBusiness(businessId);
  }

  Stream<List<Invoice>> watchInvoicesForCustomer({
    required String businessId,
    required String customerId,
  }) {
    return _invoiceRepository.watchByCustomer(
      businessId: businessId,
      customerId: customerId,
    );
  }

  Stream<Invoice?> watchInvoice(String invoiceId) {
    return _invoiceRepository.watchById(invoiceId);
  }

  Future<Invoice> createInvoice({
    required String businessId,
    required String userId,
    required InvoiceInput input,
  }) async {
    final prepared = await _prepare(businessId: businessId, input: input);
    final invoiceNumber =
        await _invoiceRepository.nextInvoiceNumber(businessId);
    final now = DateTime.now();
    final grandTotal = prepared.breakdown.totalCents;

    final invoice = await _invoiceRepository.create(
      invoice: Invoice(
        invoiceId: '',
        businessId: businessId,
        customerId: prepared.customerId,
        jobId: prepared.jobId,
        invoiceNumber: invoiceNumber,
        status: InvoiceStatus.draft,
        subtotalCents: prepared.breakdown.subtotalCents,
        discountCents: prepared.breakdown.discountCents,
        taxPercent: prepared.breakdown.taxPercent,
        taxAmountCents: prepared.breakdown.taxAmountCents,
        grandTotalCents: grandTotal,
        amountPaidCents: 0,
        balanceRemainingCents: grandTotal,
        notes: input.notes.trim(),
        issueDate: input.issueDate,
        dueDate: input.dueDate,
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
      action: 'invoice_created',
      detail: '${invoice.invoiceNumber} — ${Money.formatZar(grandTotal)}',
    );

    await _analyticsService?.logInvoiceCreated();
    return invoice;
  }

  Future<Invoice> updateInvoice({
    required String userId,
    required Invoice existing,
    required InvoiceInput input,
  }) async {
    if (!existing.status.isEditable) {
      throw const AppException(
        'Final invoices cannot be edited. Duplicate to create a correction.',
      );
    }

    final prepared = await _prepare(
      businessId: existing.businessId,
      input: InvoiceInput(
        customerId: existing.customerId,
        jobId: existing.jobId.isNotEmpty ? existing.jobId : input.jobId,
        lines: input.lines,
        taxPercent: input.taxPercent,
        discountCents: input.discountCents,
        notes: input.notes,
        issueDate: input.issueDate,
        dueDate: input.dueDate,
      ),
    );
    final grandTotal = prepared.breakdown.totalCents;

    final updated = Invoice(
      invoiceId: existing.invoiceId,
      businessId: existing.businessId,
      customerId: existing.customerId,
      jobId: existing.jobId,
      invoiceNumber: existing.invoiceNumber,
      status: existing.status,
      subtotalCents: prepared.breakdown.subtotalCents,
      discountCents: prepared.breakdown.discountCents,
      taxPercent: prepared.breakdown.taxPercent,
      taxAmountCents: prepared.breakdown.taxAmountCents,
      grandTotalCents: grandTotal,
      amountPaidCents: 0,
      balanceRemainingCents: grandTotal,
      notes: input.notes.trim(),
      issueDate: input.issueDate,
      dueDate: input.dueDate,
      finalizedAt: null,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      customerName: prepared.customerName,
      duplicatedFromInvoiceId: existing.duplicatedFromInvoiceId,
      items: prepared.items,
    );

    await _invoiceRepository.replace(invoice: updated, items: prepared.items);

    await _timeline(
      businessId: existing.businessId,
      userId: userId,
      customerId: existing.customerId,
      action: 'invoice_updated',
      detail: existing.invoiceNumber,
    );

    return (await _invoiceRepository.getById(existing.invoiceId)) ?? updated;
  }

  Future<Invoice> finalizeInvoice({
    required String userId,
    required Invoice invoice,
  }) async {
    if (!invoice.status.canFinalize) {
      throw const AppException('Only draft invoices can be finalized.');
    }

    final full = await _invoiceRepository.getById(invoice.invoiceId);
    if (full == null) {
      throw const AppException('Invoice not found.');
    }
    if (full.items.isEmpty) {
      throw const AppException('Add at least one item before finalizing.');
    }

    final now = DateTime.now();
    await _invoiceRepository.updateFields(
      invoiceId: invoice.invoiceId,
      data: {
        'status': InvoiceStatus.final_.firestoreValue,
        'finalizedAt': Timestamp.fromDate(now),
        'amountPaid': 0,
        'balanceRemaining': full.grandTotalCents,
      },
    );

    await _timeline(
      businessId: full.businessId,
      userId: userId,
      customerId: full.customerId,
      action: 'invoice_finalized',
      detail: full.invoiceNumber,
    );

    final finalized = (await _invoiceRepository.getById(invoice.invoiceId)) ??
        full.copyWith(
          status: InvoiceStatus.final_,
          finalizedAt: now,
          amountPaidCents: 0,
          balanceRemainingCents: full.grandTotalCents,
        );
    await _notificationService?.notifyInvoiceFinalized(finalized);
    await _analyticsService?.logInvoiceFinalized();
    return finalized;
  }

  Future<Invoice> cancelInvoice({
    required String userId,
    required Invoice invoice,
  }) async {
    if (!invoice.status.canCancel) {
      throw const AppException(
        'Cancelled is only allowed before an invoice is finalized.',
      );
    }

    await _invoiceRepository.updateFields(
      invoiceId: invoice.invoiceId,
      data: {'status': InvoiceStatus.cancelled.firestoreValue},
    );

    await _timeline(
      businessId: invoice.businessId,
      userId: userId,
      customerId: invoice.customerId,
      action: 'invoice_cancelled',
      detail: invoice.invoiceNumber,
    );

    return (await _invoiceRepository.getById(invoice.invoiceId)) ??
        invoice.copyWith(status: InvoiceStatus.cancelled);
  }

  /// Duplicate into a new draft for correction. Original stays unchanged.
  Future<Invoice> duplicateInvoice({
    required String userId,
    required Invoice source,
  }) async {
    final full = await _invoiceRepository.getById(source.invoiceId);
    if (full == null) {
      throw const AppException('Invoice not found.');
    }
    if (full.status == InvoiceStatus.draft) {
      throw const AppException(
        'Draft invoices can be edited directly. Duplicate is for corrections.',
      );
    }
    if (full.items.isEmpty) {
      throw const AppException('Cannot duplicate an invoice with no items.');
    }

    final invoiceNumber =
        await _invoiceRepository.nextInvoiceNumber(full.businessId);
    final now = DateTime.now();
    final lines = full.items
        .map(
          (item) => InvoiceLineInput(
            description: item.description,
            quantity: item.quantity,
            unitPriceCents: item.unitPriceCents,
          ),
        )
        .toList();

    final prepared = await _prepare(
      businessId: full.businessId,
      input: InvoiceInput(
        customerId: full.customerId,
        jobId: full.jobId,
        lines: lines,
        taxPercent: full.taxPercent,
        discountCents: full.discountCents,
        notes: full.notes,
        issueDate: DateTime(now.year, now.month, now.day),
        dueDate: full.dueDate,
      ),
    );
    final grandTotal = prepared.breakdown.totalCents;

    final created = await _invoiceRepository.create(
      invoice: Invoice(
        invoiceId: '',
        businessId: full.businessId,
        customerId: full.customerId,
        jobId: full.jobId,
        invoiceNumber: invoiceNumber,
        status: InvoiceStatus.draft,
        subtotalCents: prepared.breakdown.subtotalCents,
        discountCents: prepared.breakdown.discountCents,
        taxPercent: prepared.breakdown.taxPercent,
        taxAmountCents: prepared.breakdown.taxAmountCents,
        grandTotalCents: grandTotal,
        amountPaidCents: 0,
        balanceRemainingCents: grandTotal,
        notes: full.notes,
        issueDate: DateTime(now.year, now.month, now.day),
        dueDate: full.dueDate,
        createdAt: now,
        updatedAt: now,
        customerName: prepared.customerName,
        duplicatedFromInvoiceId: full.invoiceId,
      ),
      items: prepared.items,
    );

    await _timeline(
      businessId: full.businessId,
      userId: userId,
      customerId: full.customerId,
      action: 'invoice_duplicated',
      detail: '${full.invoiceNumber} → ${created.invoiceNumber}',
    );

    return created;
  }

  List<Invoice> filterInvoices({
    required List<Invoice> invoices,
    required String query,
    required InvoiceListFilter filter,
  }) {
    return InvoiceQuery.filter(
      invoices: invoices,
      query: query,
      filter: filter,
    );
  }

  Future<_PreparedInvoice> _prepare({
    required String businessId,
    required InvoiceInput input,
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

    final jobId = input.jobId.trim();
    if (jobId.isNotEmpty) {
      final job = await _jobRepository.getById(jobId);
      if (job == null || job.businessId != businessId) {
        throw const AppException('Job not found.');
      }
      if (job.customerId != customer.customerId) {
        throw const AppException('Job does not belong to this customer.');
      }
      if (job.status == JobStatus.cancelled) {
        throw const AppException('Cancelled jobs cannot generate invoices.');
      }
    }

    final items = <InvoiceItem>[];
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
          InvoiceItem(
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
      return _PreparedInvoice(
        customerId: customer.customerId,
        customerName: customer.name,
        jobId: jobId,
        items: items,
        breakdown: breakdown,
      );
    } on ArgumentError catch (error) {
      throw AppException(
        error.message?.toString() ?? 'Invalid invoice totals.',
      );
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

class _PreparedInvoice {
  const _PreparedInvoice({
    required this.customerId,
    required this.customerName,
    required this.jobId,
    required this.items,
    required this.breakdown,
  });

  final String customerId;
  final String customerName;
  final String jobId;
  final List<InvoiceItem> items;
  final MoneyBreakdown breakdown;
}

enum InvoiceListFilter {
  draft,
  final_,
  unpaid,
  paid,
  overdue,
  cancelled,
  all,
}

class InvoiceQuery {
  InvoiceQuery._();

  static List<Invoice> filter({
    required List<Invoice> invoices,
    required String query,
    required InvoiceListFilter filter,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return invoices.where((invoice) {
      switch (filter) {
        case InvoiceListFilter.draft:
          if (invoice.status != InvoiceStatus.draft) return false;
        case InvoiceListFilter.final_:
          if (invoice.status != InvoiceStatus.final_) return false;
        case InvoiceListFilter.unpaid:
          if (invoice.status != InvoiceStatus.final_ &&
              invoice.status != InvoiceStatus.partial &&
              invoice.status != InvoiceStatus.overdue) {
            return false;
          }
        case InvoiceListFilter.paid:
          if (invoice.status != InvoiceStatus.paid) return false;
        case InvoiceListFilter.overdue:
          if (invoice.status != InvoiceStatus.overdue) return false;
        case InvoiceListFilter.cancelled:
          if (invoice.status != InvoiceStatus.cancelled) return false;
        case InvoiceListFilter.all:
          break;
      }

      if (normalizedQuery.isEmpty) return true;
      final haystack = [
        invoice.invoiceNumber,
        invoice.customerName,
        invoice.notes,
        invoice.status.label,
        Money.formatZar(invoice.grandTotalCents),
      ].join(' ').toLowerCase();
      return haystack.contains(normalizedQuery);
    }).toList();
  }
}
