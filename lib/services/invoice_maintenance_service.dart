import '../models/invoice.dart';
import '../repositories/invoice_repository.dart';
import 'notification_service.dart';

/// Marks past-due unpaid finalized invoices as overdue (Phase 10 sweep).
class InvoiceMaintenanceService {
  InvoiceMaintenanceService({
    required InvoiceRepository invoiceRepository,
    required NotificationService notificationService,
  })  : _invoiceRepository = invoiceRepository,
        _notificationService = notificationService;

  final InvoiceRepository _invoiceRepository;
  final NotificationService _notificationService;

  Future<int> markOverdueInvoices({
    required String businessId,
    required List<Invoice> invoices,
    DateTime? now,
  }) async {
    final moment = now ?? DateTime.now();
    final today = DateTime(moment.year, moment.month, moment.day);
    var count = 0;

    for (final invoice in invoices) {
      if (invoice.status != InvoiceStatus.final_ &&
          invoice.status != InvoiceStatus.partial) {
        continue;
      }
      if (invoice.balanceRemainingCents <= 0) continue;
      final due = invoice.dueDate;
      if (due == null) continue;
      final dueDay = DateTime(due.year, due.month, due.day);
      if (!dueDay.isBefore(today)) continue;
      if (invoice.status == InvoiceStatus.overdue) continue;

      await _invoiceRepository.updateFields(
        invoiceId: invoice.invoiceId,
        data: {'status': InvoiceStatus.overdue.firestoreValue},
      );
      await _notificationService.notifyInvoiceOverdue(
        invoice.copyWith(status: InvoiceStatus.overdue),
      );
      count++;
    }

    return count;
  }
}
