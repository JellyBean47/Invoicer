import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/app_providers.dart';
import '../../../services/business_service.dart';
import '../../../shared/widgets/primary_button.dart';

class BusinessSetupWizardScreen extends ConsumerStatefulWidget {
  const BusinessSetupWizardScreen({super.key});

  @override
  ConsumerState<BusinessSetupWizardScreen> createState() =>
      _BusinessSetupWizardScreenState();
}

class _BusinessSetupWizardScreenState
    extends ConsumerState<BusinessSetupWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxController = TextEditingController(
    text: '${AppConstants.defaultTaxPercent}',
  );
  final _currencyController = TextEditingController(
    text: AppConstants.defaultCurrency,
  );
  final _prefixController = TextEditingController(
    text: AppConstants.defaultInvoicePrefix,
  );
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).valueOrNull;
      final profile = ref.read(userProfileProvider).valueOrNull;
      final name = profile?.displayName.isNotEmpty == true
          ? profile!.displayName
          : (user?.displayName ?? '');
      if (name.isNotEmpty && _ownerNameController.text.isEmpty) {
        _ownerNameController.text = name;
      }
    });
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _taxController.dispose();
    _currencyController.dispose();
    _prefixController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(businessServiceProvider).completeSetup(
            uid: user.uid,
            input: BusinessSetupInput(
              businessName: _businessNameController.text,
              ownerName: _ownerNameController.text,
              phone: _phoneController.text,
              email: user.email ?? '',
              address: _addressController.text,
              defaultTaxPercent: int.parse(_taxController.text.trim()),
              currency: _currencyController.text,
              invoicePrefix: _prefixController.text,
            ),
          );
      ref.invalidate(userProfileProvider);
      ref.invalidate(businessProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business profile ready')),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Setup'),
        actions: [
          TextButton(
            onPressed: () => ref.read(authServiceProvider).signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tell us about your business',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'This information appears on invoices and reports. '
                  'You can change it later in Settings.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _businessNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Business name',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                  validator: (value) =>
                      Validators.required(value, fieldName: 'Business name'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _ownerNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Owner name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      Validators.required(value, fieldName: 'Owner name'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: Validators.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _addressController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Business address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) =>
                      Validators.required(value, fieldName: 'Address'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _taxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Default tax %',
                    prefixIcon: Icon(Icons.percent),
                    helperText: 'Usually 15 for South Africa',
                  ),
                  validator: Validators.taxPercent,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _currencyController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    prefixIcon: Icon(Icons.payments_outlined),
                    helperText: 'Example: ZAR',
                  ),
                  validator: (value) =>
                      Validators.required(value, fieldName: 'Currency'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _prefixController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Invoice prefix',
                    prefixIcon: Icon(Icons.tag),
                    helperText: 'Example: INV → INV-2026-000001',
                  ),
                  validator: (value) =>
                      Validators.required(value, fieldName: 'Invoice prefix'),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Finish Setup',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
