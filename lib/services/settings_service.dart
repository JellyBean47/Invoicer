import '../core/utils/app_exception.dart';
import '../models/app_settings.dart';
import '../models/business.dart';
import '../repositories/business_repository.dart';
import '../repositories/settings_repository.dart';

class SettingsService {
  SettingsService({
    required SettingsRepository settingsRepository,
    required BusinessRepository businessRepository,
  })  : _settingsRepository = settingsRepository,
        _businessRepository = businessRepository;

  final SettingsRepository _settingsRepository;
  final BusinessRepository _businessRepository;

  Stream<AppSettings?> watchSettings(String businessId) {
    return _settingsRepository.watch(businessId);
  }

  Future<AppSettings> loadOrCreate(String businessId) {
    return _settingsRepository.ensureDefaults(businessId);
  }

  Future<AppSettings> updateSettings(AppSettings settings) async {
    if (settings.defaultTaxPercent < 0 || settings.defaultTaxPercent > 100) {
      throw const AppException('Tax percent must be between 0 and 100.');
    }
    if (settings.paymentTermsDays < 0 || settings.paymentTermsDays > 365) {
      throw const AppException('Payment terms must be between 0 and 365 days.');
    }
    final prefix = settings.invoicePrefix.trim().toUpperCase();
    if (prefix.isEmpty || prefix.length > 10) {
      throw const AppException('Invoice prefix must be 1–10 characters.');
    }

    final sanitized = settings.copyWith(
      invoicePrefix: prefix,
      updatedAt: DateTime.now(),
    );
    await _settingsRepository.save(sanitized);

    final business = await _businessRepository.getById(settings.businessId);
    if (business != null) {
      await _businessRepository.updateFields(
        businessId: business.businessId,
        data: {
          'defaultTaxPercent': sanitized.defaultTaxPercent,
          'invoicePrefix': sanitized.invoicePrefix,
          'currency': sanitized.currency,
        },
      );
    }

    return sanitized;
  }

  Future<Business?> updateBusinessProfile({
    required String businessId,
    required String businessName,
    required String ownerName,
    required String phone,
    required String email,
    required String address,
    String registrationNumber = '',
    String vatNumber = '',
  }) async {
    final business = await _businessRepository.getById(businessId);
    if (business == null) {
      throw const AppException('Business not found.');
    }
    if (businessName.trim().isEmpty) {
      throw const AppException('Business name is required.');
    }
    if (ownerName.trim().isEmpty) {
      throw const AppException('Owner name is required.');
    }
    if (phone.trim().isEmpty) {
      throw const AppException('Phone is required.');
    }

    await _businessRepository.updateFields(
      businessId: businessId,
      data: {
        'businessName': businessName.trim(),
        'ownerName': ownerName.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'address': address.trim(),
        'registrationNumber': registrationNumber.trim(),
        'vatNumber': vatNumber.trim(),
      },
    );
    return _businessRepository.getById(businessId);
  }
}
