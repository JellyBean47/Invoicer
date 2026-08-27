import '../core/utils/app_exception.dart';
import '../core/utils/money.dart';
import '../models/invoice.dart';
import '../models/payment.dart';
import '../models/timeline_entry.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/timeline_repository.dart';
import 'analytics_service.dart';
import 'notification_service.dart';

class PaymentInput {
  const PaymentInput({
    required this.amountCents,
    required this.paymentMethod,
    required this.receivedAt,
    this.reference = '',
    this.notes = '',
  });

  final int amountCents;
  final PaymentMethod paymentMethod;
  final DateTime receivedAt;
  final String reference;
  final String notes;
}

class PaymentService {
  PaymentService({
    required PaymentRepository paymentRepository,
    required InvoiceRepository invoiceRepository,
    required TimelineRepository timelineRepository,
    NotificationService? notificationService,
    SettingsRepository? settingsRepository,
    AnalyticsService? analyticsService,
  })  : _paymentRepository = paymentRepository,
        _invoiceRepository = invoiceRepository,
        _timelineRepository = timelineRepository,
        _notificationService = notificationService,
        _settingsRepository = settingsRepository,
        _analyticsService = analyticsService;

  final PaymentRepository _paymentRepository;
  final InvoiceRepository _invoiceRepository;
  final TimelineRepository _timelineRepository;
  final NotificationService? _notificationService;
  final SettingsRepository? _settingsRepository;
  final AnalyticsService? _analyticsService;

  Stream<List<Payment>> watchPayments(String businessId) {
    return _paymentRepository.watchByBusiness(businessId);
  }

  Stream<List<Payment>> watchPaymentsForInvoice({
    required String businessId,
    required String invoiceId,
  }) {
    return _paymentRepository.watchByInvoice(
      businessId: businessId,
      invoiceId: invoiceId,
    );
  }

  Stream<List<Payment>> watchPaymentsForCustomer({
    required String businessId,
    required String customerId,
  }) {
    return _paymentRepository.watchByCustomer(
      businessId: businessId,
      customerId: customerId,
    );
  }

  Future<Payment> recordPayment({
    required String userId,
    required Invoice invoice,
    required PaymentInput input,
  }) async {
    if (!invoice.canRecordPayment) {
      throw const AppException(
        'Payments can only be recorded on unpaid finalized invoices.',
      );
    }
    if (input.amountCents <= 0) {
      throw const AppException('Payment amount must be greater than zero.');
    }
    if (input.amountCents > invoice.balanceRemainingCents) {
      throw AppException(
        'Payment cannot exceed the outstanding balance of '
        '${Money.formatZar(invoice.balanceRemainingCents)}.',
      );
    }

    final current = await _invoiceRepository.getById(invoice.invoiceId);
    if (current == null) {
      throw const AppException('Invoice not found.');
    }
    if (current.businessId != invoice.businessId) {
      throw const AppException('Invoice not found.');
    }

    final payment = await _paymentRepository.createAndUpdateInvoice(
      invoiceId: current.invoiceId,
      amountCents: input.amountCents,
      paymentMethod: input.paymentMethod,
      receivedAt: input.receivedAt,
      reference: input.reference.trim(),
      notes: input.notes.trim(),
    );

    await _timelineRepository.add(
      TimelineEntry(
        logId: '',
        businessId: current.businessId,
        userId: userId,
        entityType: 'customer',
        entityId: current.customerId,
        action: 'payment_recorded',
        newValue:
            '${Money.formatZar(payment.amountCents)} on ${current.invoiceNumber} '
            '(${payment.paymentMethod.label})',
        timestamp: DateTime.now(),
      ),
    );

    final notifications = _notificationService;
    final settingsRepo = _settingsRepository;
    if (notifications != null) {
      final settings = settingsRepo == null
          ? null
          : await settingsRepo.getByBusinessId(current.businessId);
      final updated =
          await _invoiceRepository.getById(current.invoiceId) ?? current;
      await notifications.notifyPaymentReceived(
        invoice: updated,
        payment: payment,
        settings: settings,
      );
    }

    await _analyticsService?.logPaymentRecorded();
    return payment;
  }

  List<Payment> filterPayments({
    required List<Payment> payments,
    required String query,
  }) {
    return PaymentQuery.filter(payments: payments, query: query);
  }

  /// Sum of payments received on a calendar day (local time).
  int moneyReceivedTodayCents(List<Payment> payments, {DateTime? now}) {
    return PaymentTotals.moneyReceivedTodayCents(payments, now: now);
  }

  /// Outstanding across unpaid finalized invoices.
  int outstandingCents(List<Invoice> invoices) {
    return PaymentTotals.outstandingCents(invoices);
  }
}

class PaymentTotals {
  PaymentTotals._();

  static int moneyReceivedTodayCents(List<Payment> payments, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    return payments
        .where(
          (payment) =>
              !payment.receivedAt.isBefore(start) &&
              payment.receivedAt.isBefore(end),
        )
        .fold<int>(0, (sum, payment) => sum + payment.amountCents);
  }

  static int outstandingCents(List<Invoice> invoices) {
    return invoices
        .where((invoice) => invoice.hasOutstanding)
        .fold<int>(0, (sum, invoice) => sum + invoice.balanceRemainingCents);
  }
}

class PaymentQuery {
  PaymentQuery._();

  static List<Payment> filter({
    required List<Payment> payments,
    required String query,
  }) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return payments;
    return payments.where((payment) {
      final haystack = [
        payment.invoiceNumber,
        payment.customerName,
        payment.paymentMethod.label,
        payment.reference,
        payment.notes,
        Money.formatZar(payment.amountCents),
      ].join(' ').toLowerCase();
      return haystack.contains(normalized);
    }).toList();
  }
}
