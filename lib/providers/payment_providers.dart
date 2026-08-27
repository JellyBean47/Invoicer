import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment.dart';
import '../repositories/payment_repository.dart';
import '../services/payment_service.dart';
import 'app_providers.dart';
import 'customer_providers.dart';
import 'invoice_providers.dart';
import 'notification_providers.dart';
import 'settings_providers.dart';
import 'telemetry_providers.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(
    paymentRepository: ref.watch(paymentRepositoryProvider),
    invoiceRepository: ref.watch(invoiceRepositoryProvider),
    timelineRepository: ref.watch(timelineRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
    analyticsService: ref.watch(analyticsServiceProvider),
  );
});

final paymentsProvider = StreamProvider<List<Payment>>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final businessId = profile?.businessId;
  if (businessId == null || businessId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(paymentServiceProvider).watchPayments(businessId);
});

final invoicePaymentsProvider =
    StreamProvider.family<List<Payment>, String>((ref, invoiceId) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final businessId = profile?.businessId;
  if (businessId == null || businessId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(paymentServiceProvider).watchPaymentsForInvoice(
        businessId: businessId,
        invoiceId: invoiceId,
      );
});

final customerPaymentsProvider =
    StreamProvider.family<List<Payment>, String>((ref, customerId) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final businessId = profile?.businessId;
  if (businessId == null || businessId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(paymentServiceProvider).watchPaymentsForCustomer(
        businessId: businessId,
        customerId: customerId,
      );
});

final dashboardMoneyProvider = Provider<AsyncValue<({int receivedToday, int outstanding})>>((ref) {
  final paymentsAsync = ref.watch(paymentsProvider);
  final invoicesAsync = ref.watch(invoicesProvider);
  final service = ref.watch(paymentServiceProvider);

  if (paymentsAsync.isLoading || invoicesAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (paymentsAsync.hasError) {
    return AsyncValue.error(paymentsAsync.error!, paymentsAsync.stackTrace!);
  }
  if (invoicesAsync.hasError) {
    return AsyncValue.error(invoicesAsync.error!, invoicesAsync.stackTrace!);
  }

  final payments = paymentsAsync.valueOrNull ?? const [];
  final invoices = invoicesAsync.valueOrNull ?? const [];
  return AsyncValue.data((
    receivedToday: service.moneyReceivedTodayCents(payments),
    outstanding: service.outstandingCents(invoices),
  ));
});
