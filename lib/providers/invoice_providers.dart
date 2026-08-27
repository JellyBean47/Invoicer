import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/invoice.dart';
import '../repositories/invoice_repository.dart';
import '../services/invoice_maintenance_service.dart';
import '../services/invoice_pdf_service.dart';
import '../services/invoice_service.dart';
import 'app_providers.dart';
import 'customer_providers.dart';
import 'job_providers.dart';
import 'notification_providers.dart';
import 'telemetry_providers.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository();
});

final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  return InvoiceService(
    invoiceRepository: ref.watch(invoiceRepositoryProvider),
    customerRepository: ref.watch(customerRepositoryProvider),
    timelineRepository: ref.watch(timelineRepositoryProvider),
    jobRepository: ref.watch(jobRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
    analyticsService: ref.watch(analyticsServiceProvider),
  );
});

final invoiceMaintenanceServiceProvider =
    Provider<InvoiceMaintenanceService>((ref) {
  return InvoiceMaintenanceService(
    invoiceRepository: ref.watch(invoiceRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});

final invoicePdfServiceProvider = Provider<InvoicePdfService>((ref) {
  return InvoicePdfService(
    invoiceRepository: ref.watch(invoiceRepositoryProvider),
    businessRepository: ref.watch(businessRepositoryProvider),
    customerRepository: ref.watch(customerRepositoryProvider),
    analyticsService: ref.watch(analyticsServiceProvider),
  );
});

final invoiceSearchQueryProvider = StateProvider<String>((ref) => '');

final invoiceListFilterProvider =
    StateProvider<InvoiceListFilter>((ref) => InvoiceListFilter.all);

final invoicesProvider = StreamProvider<List<Invoice>>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final businessId = profile?.businessId;
  if (businessId == null || businessId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(invoiceServiceProvider).watchInvoices(businessId);
});

final filteredInvoicesProvider = Provider<AsyncValue<List<Invoice>>>((ref) {
  final invoicesAsync = ref.watch(invoicesProvider);
  final query = ref.watch(invoiceSearchQueryProvider);
  final filter = ref.watch(invoiceListFilterProvider);
  final service = ref.watch(invoiceServiceProvider);

  return invoicesAsync.whenData((invoices) {
    return service.filterInvoices(
      invoices: invoices,
      query: query,
      filter: filter,
    );
  });
});

final invoiceProvider =
    StreamProvider.family<Invoice?, String>((ref, invoiceId) {
  return ref.watch(invoiceServiceProvider).watchInvoice(invoiceId);
});

final customerInvoicesProvider =
    StreamProvider.family<List<Invoice>, String>((ref, customerId) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final businessId = profile?.businessId;
  if (businessId == null || businessId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(invoiceServiceProvider).watchInvoicesForCustomer(
        businessId: businessId,
        customerId: customerId,
      );
});
