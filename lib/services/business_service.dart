import '../core/constants/app_constants.dart';
import '../core/utils/app_exception.dart';
import '../models/business.dart';
import '../repositories/business_repository.dart';
import '../repositories/user_repository.dart';

class BusinessSetupInput {
  const BusinessSetupInput({
    required this.businessName,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.defaultTaxPercent,
    required this.currency,
    required this.invoicePrefix,
  });

  final String businessName;
  final String ownerName;
  final String phone;
  final String email;
  final String address;
  final int defaultTaxPercent;
  final String currency;
  final String invoicePrefix;
}

class BusinessService {
  BusinessService({
    required BusinessRepository businessRepository,
    required UserRepository userRepository,
  })  : _businessRepository = businessRepository,
        _userRepository = userRepository;

  final BusinessRepository _businessRepository;
  final UserRepository _userRepository;

  Future<Business?> getById(String businessId) {
    return _businessRepository.getById(businessId);
  }

  Future<Business> completeSetup({
    required String uid,
    required BusinessSetupInput input,
  }) async {
    final profile = await _userRepository.getById(uid);
    if (profile == null) {
      throw const AppException('Your profile could not be found.');
    }
    if (profile.hasBusiness) {
      throw const AppException('A business is already linked to this account.');
    }

    final now = DateTime.now();
    final business = await _businessRepository.create(
      Business(
        businessId: '',
        businessName: input.businessName.trim(),
        ownerName: input.ownerName.trim(),
        phone: _normalizePhone(input.phone),
        email: input.email.trim(),
        address: input.address.trim(),
        currency: input.currency.trim().isEmpty
            ? AppConstants.defaultCurrency
            : input.currency.trim().toUpperCase(),
        defaultTaxPercent: input.defaultTaxPercent,
        invoicePrefix: input.invoicePrefix.trim().isEmpty
            ? AppConstants.defaultInvoicePrefix
            : input.invoicePrefix.trim().toUpperCase(),
        invoiceCounter: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Link user first so security rules recognize the business ownership.
    await _userRepository.setBusinessId(
      uid: uid,
      businessId: business.businessId,
    );
    await _businessRepository.createDefaultSettings(business);

    return business;
  }

  String _normalizePhone(String phone) {
    return phone.trim().replaceAll(RegExp(r'\s+'), '');
  }
}
