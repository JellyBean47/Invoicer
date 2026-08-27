import '../core/utils/app_exception.dart';
import '../core/utils/phone_utils.dart';
import '../models/customer.dart';
import '../models/timeline_entry.dart';
import '../repositories/customer_repository.dart';
import '../repositories/timeline_repository.dart';

class CustomerInput {
  const CustomerInput({
    required this.name,
    required this.phone,
    this.email = '',
    this.company = '',
    this.address = '',
    this.notes = '',
    this.tags = const [],
  });

  final String name;
  final String phone;
  final String email;
  final String company;
  final String address;
  final String notes;
  final List<String> tags;
}

class CustomerService {
  CustomerService({
    required CustomerRepository customerRepository,
    required TimelineRepository timelineRepository,
  })  : _customerRepository = customerRepository,
        _timelineRepository = timelineRepository;

  final CustomerRepository _customerRepository;
  final TimelineRepository _timelineRepository;

  Stream<List<Customer>> watchCustomers(String businessId) {
    return _customerRepository.watchByBusiness(businessId);
  }

  Stream<Customer?> watchCustomer(String customerId) {
    return _customerRepository.watchById(customerId);
  }

  Stream<List<TimelineEntry>> watchTimeline({
    required String businessId,
    required String customerId,
  }) {
    return _timelineRepository.watchForEntity(
      businessId: businessId,
      entityType: 'customer',
      entityId: customerId,
    );
  }

  Future<Customer> createCustomer({
    required String businessId,
    required String userId,
    required CustomerInput input,
  }) async {
    final name = input.name.trim();
    final phone = PhoneUtils.normalize(input.phone);
    _validateRequired(name: name, phone: phone);
    await _ensureUniquePhone(businessId: businessId, phone: phone);

    final customer = await _customerRepository.create(
      businessId: businessId,
      name: name,
      phone: phone,
      email: input.email.trim(),
      company: input.company.trim(),
      address: input.address.trim(),
      notes: input.notes.trim(),
      tags: input.tags,
    );

    await _timelineRepository.add(
      TimelineEntry(
        logId: '',
        businessId: businessId,
        userId: userId,
        entityType: 'customer',
        entityId: customer.customerId,
        action: 'customer_created',
        newValue: name,
        timestamp: DateTime.now(),
      ),
    );

    return customer;
  }

  Future<Customer> updateCustomer({
    required String userId,
    required Customer existing,
    required CustomerInput input,
  }) async {
    final name = input.name.trim();
    final phone = PhoneUtils.normalize(input.phone);
    _validateRequired(name: name, phone: phone);
    await _ensureUniquePhone(
      businessId: existing.businessId,
      phone: phone,
      excludingCustomerId: existing.customerId,
    );

    final updated = existing.copyWith(
      name: name,
      phone: phone,
      email: input.email.trim(),
      company: input.company.trim(),
      address: input.address.trim(),
      notes: input.notes.trim(),
      tags: input.tags,
      updatedAt: DateTime.now(),
    );
    await _customerRepository.update(updated);

    await _timelineRepository.add(
      TimelineEntry(
        logId: '',
        businessId: existing.businessId,
        userId: userId,
        entityType: 'customer',
        entityId: existing.customerId,
        action: 'customer_updated',
        newValue: name,
        timestamp: DateTime.now(),
      ),
    );

    return updated;
  }

  Future<void> archiveCustomer({
    required String userId,
    required Customer customer,
  }) async {
    if (customer.isArchived) return;
    await _customerRepository.archive(customer.customerId);
    await _timelineRepository.add(
      TimelineEntry(
        logId: '',
        businessId: customer.businessId,
        userId: userId,
        entityType: 'customer',
        entityId: customer.customerId,
        action: 'customer_archived',
        newValue: customer.name,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> restoreCustomer({
    required String userId,
    required Customer customer,
  }) async {
    if (customer.isActive) return;
    await _customerRepository.restore(customer.customerId);
    await _timelineRepository.add(
      TimelineEntry(
        logId: '',
        businessId: customer.businessId,
        userId: userId,
        entityType: 'customer',
        entityId: customer.customerId,
        action: 'customer_restored',
        newValue: customer.name,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> addNote({
    required String businessId,
    required String userId,
    required String customerId,
    required String note,
  }) async {
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      throw const AppException('Note cannot be empty.');
    }
    await _timelineRepository.add(
      TimelineEntry(
        logId: '',
        businessId: businessId,
        userId: userId,
        entityType: 'customer',
        entityId: customerId,
        action: 'note',
        newValue: trimmed,
        timestamp: DateTime.now(),
        isManualNote: true,
      ),
    );
  }

  /// Blocks new work for archived customers (jobs/quotes/invoices).
  void ensureCanReceiveWork(Customer customer) {
    CustomerQuery.ensureCanReceiveWork(customer);
  }

  List<Customer> filterCustomers({
    required List<Customer> customers,
    required String query,
    required CustomerListFilter filter,
  }) {
    return CustomerQuery.filter(
      customers: customers,
      query: query,
      filter: filter,
    );
  }

  void _validateRequired({required String name, required String phone}) {
    if (name.isEmpty) {
      throw const AppException('Name is required.');
    }
    if (PhoneUtils.digitsOnly(phone).length < 9) {
      throw const AppException('Enter a valid phone number.');
    }
  }

  Future<void> _ensureUniquePhone({
    required String businessId,
    required String phone,
    String? excludingCustomerId,
  }) async {
    final existing = await _customerRepository.findByPhone(
      businessId: businessId,
      phone: phone,
    );
    if (existing == null) return;
    if (excludingCustomerId != null &&
        existing.customerId == excludingCustomerId) {
      return;
    }
    throw const AppException(
      'A customer with this phone number already exists.',
    );
  }
}

enum CustomerListFilter {
  active,
  archived,
  all,
}

/// Pure query helpers (safe to unit test without Firebase).
class CustomerQuery {
  CustomerQuery._();

  static List<Customer> filter({
    required List<Customer> customers,
    required String query,
    required CustomerListFilter filter,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final phoneQuery = PhoneUtils.digitsOnly(query);

    return customers.where((customer) {
      switch (filter) {
        case CustomerListFilter.active:
          if (!customer.isActive) return false;
        case CustomerListFilter.archived:
          if (!customer.isArchived) return false;
        case CustomerListFilter.all:
          break;
      }

      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        customer.name,
        customer.phone,
        customer.email,
        customer.company,
        customer.address,
      ].join(' ').toLowerCase();

      final phoneMatch = phoneQuery.isNotEmpty &&
          PhoneUtils.digitsOnly(customer.phone).contains(phoneQuery);

      return haystack.contains(normalizedQuery) || phoneMatch;
    }).toList();
  }

  static void ensureCanReceiveWork(Customer customer) {
    if (customer.isArchived) {
      throw const AppException(
        'This customer is archived. Restore them before creating jobs, quotes, or invoices.',
      );
    }
  }
}
