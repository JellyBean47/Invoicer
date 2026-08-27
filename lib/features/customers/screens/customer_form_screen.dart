import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../models/customer.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/customer_providers.dart';
import '../../../services/customer_service.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/primary_button.dart';
import '../widgets/smart_actions_sheet.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.customerId});

  final String? customerId;

  bool get isEditing => customerId != null;

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _hydrated = false;
  Customer? _existing;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _hydrate(Customer customer) {
    if (_hydrated) return;
    _existing = customer;
    _nameController.text = customer.name;
    _phoneController.text = customer.phone;
    _emailController.text = customer.email;
    _companyController.text = customer.company;
    _addressController.text = customer.address;
    _notesController.text = customer.notes;
    _hydrated = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ref.read(userProfileProvider).valueOrNull;
    final user = ref.read(authStateProvider).valueOrNull;
    if (profile == null || user == null || !profile.hasBusiness) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business profile not ready yet.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final input = CustomerInput(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        company: _companyController.text,
        address: _addressController.text,
        notes: _notesController.text,
      );

      if (widget.isEditing) {
        final existing = _existing;
        if (existing == null) return;
        await ref.read(customerServiceProvider).updateCustomer(
              userId: user.uid,
              existing: existing,
              input: input,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer saved')),
        );
        context.pop();
      } else {
        final created = await ref.read(customerServiceProvider).createCustomer(
              businessId: profile.businessId,
              userId: user.uid,
              input: input,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer created')),
        );
        await showCustomerSmartActions(context, customer: created);
        if (!mounted) return;
        context.go('/customers/${created.customerId}');
      }
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
    if (widget.isEditing) {
      final customerAsync = ref.watch(customerProvider(widget.customerId!));
      return customerAsync.when(
        loading: () => const Scaffold(
          body: AppLoading(message: 'Loading customer...'),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Customer')),
          body: Center(child: Text(error.toString())),
        ),
        data: (customer) {
          if (customer == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Customer')),
              body: const Center(child: Text('Customer not found.')),
            );
          }
          _hydrate(customer);
          return _buildForm(context);
        },
      );
    }

    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Customer' : 'New Customer'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      Validators.required(value, fieldName: 'Name'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    helperText: 'Must be unique for your business',
                  ),
                  validator: Validators.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: Validators.optionalEmail,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _companyController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Business / company (optional)',
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _addressController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address (optional)',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _notesController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: widget.isEditing ? 'Save Changes' : 'Create Customer',
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
