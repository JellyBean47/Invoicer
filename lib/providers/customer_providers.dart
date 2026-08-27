import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import '../models/timeline_entry.dart';
import '../repositories/customer_repository.dart';
import '../repositories/timeline_repository.dart';
import '../services/customer_service.dart';
import 'app_providers.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  return TimelineRepository();
});

final customerServiceProvider = Provider<CustomerService>((ref) {
  return CustomerService(
    customerRepository: ref.watch(customerRepositoryProvider),
    timelineRepository: ref.watch(timelineRepositoryProvider),
  );
});

final customerSearchQueryProvider = StateProvider<String>((ref) => '');

final customerListFilterProvider =
    StateProvider<CustomerListFilter>((ref) => CustomerListFilter.active);

final customersProvider = StreamProvider<List<Customer>>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final businessId = profile?.businessId;
  if (businessId == null || businessId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(customerServiceProvider).watchCustomers(businessId);
});

final filteredCustomersProvider = Provider<AsyncValue<List<Customer>>>((ref) {
  final customersAsync = ref.watch(customersProvider);
  final query = ref.watch(customerSearchQueryProvider);
  final filter = ref.watch(customerListFilterProvider);
  final service = ref.watch(customerServiceProvider);

  return customersAsync.whenData((customers) {
    return service.filterCustomers(
      customers: customers,
      query: query,
      filter: filter,
    );
  });
});

final customerProvider =
    StreamProvider.family<Customer?, String>((ref, customerId) {
  return ref.watch(customerServiceProvider).watchCustomer(customerId);
});

final customerTimelineProvider =
    StreamProvider.family<List<TimelineEntry>, String>((ref, customerId) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final businessId = profile?.businessId;
  if (businessId == null || businessId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(customerServiceProvider).watchTimeline(
        businessId: businessId,
        customerId: customerId,
      );
});
