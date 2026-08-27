import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../models/customer.dart';
import '../../../models/job.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/customer_providers.dart';
import '../../../providers/job_providers.dart';
import '../../../services/job_service.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/primary_button.dart';

class JobFormScreen extends ConsumerStatefulWidget {
  const JobFormScreen({
    super.key,
    this.jobId,
    this.initialCustomerId,
  });

  final String? jobId;
  final String? initialCustomerId;

  bool get isEditing => jobId != null;

  @override
  ConsumerState<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends ConsumerState<JobFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  String? _customerId;
  JobPriority _priority = JobPriority.normal;
  DateTime? _scheduledDate;
  bool _isLoading = false;
  bool _hydrated = false;
  Job? _existing;

  @override
  void initState() {
    super.initState();
    _customerId = widget.initialCustomerId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _hydrate(Job job) {
    if (_hydrated) return;
    _existing = job;
    _customerId = job.customerId;
    _titleController.text = job.title;
    _descriptionController.text = job.description;
    _addressController.text = job.address;
    _priority = job.priority;
    _scheduledDate = job.scheduledDate;
    _hydrated = true;
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledDate ?? now),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_customerId == null || _customerId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a customer.')),
      );
      return;
    }

    final profile = ref.read(userProfileProvider).valueOrNull;
    final user = ref.read(authStateProvider).valueOrNull;
    if (profile == null || user == null || !profile.hasBusiness) return;

    setState(() => _isLoading = true);
    try {
      final input = JobInput(
        customerId: _customerId!,
        title: _titleController.text,
        description: _descriptionController.text,
        address: _addressController.text,
        priority: _priority,
        scheduledDate: _scheduledDate,
      );

      if (widget.isEditing) {
        final existing = _existing;
        if (existing == null) return;
        await ref.read(jobServiceProvider).updateJob(
              userId: user.uid,
              existing: existing,
              input: input,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job saved')),
        );
        context.pop();
      } else {
        final created = await ref.read(jobServiceProvider).createJob(
              businessId: profile.businessId,
              userId: user.uid,
              input: input,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job ${created.jobNumber} created')),
        );
        context.go('/jobs/${created.jobId}');
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
      final jobAsync = ref.watch(jobProvider(widget.jobId!));
      return jobAsync.when(
        loading: () => const Scaffold(
          body: AppLoading(message: 'Loading job...'),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Job')),
          body: Center(child: Text(error.toString())),
        ),
        data: (job) {
          if (job == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Job')),
              body: const Center(child: Text('Job not found.')),
            );
          }
          _hydrate(job);
          return _buildForm(context);
        },
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final activeCustomers = customersAsync.maybeWhen(
      data: (customers) => customers
          .where((customer) => customer.status == CustomerStatus.active)
          .toList(),
      orElse: () => <Customer>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Job' : 'New Job'),
      ),
      body: SafeArea(
        child: customersAsync.isLoading
            ? const AppLoading(message: 'Loading customers...')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (activeCustomers.isEmpty && !widget.isEditing)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'You need an active customer before creating a job.',
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                OutlinedButton(
                                  onPressed: () =>
                                      context.push('/customers/new'),
                                  child: const Text('Create Customer'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: _customerId != null &&
                                  activeCustomers.any(
                                    (c) => c.customerId == _customerId,
                                  )
                              ? _customerId
                              : (_existing?.customerId),
                          decoration: const InputDecoration(
                            labelText: 'Customer',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: [
                            if (widget.isEditing && _existing != null)
                              DropdownMenuItem(
                                value: _existing!.customerId,
                                child: Text(_existing!.customerName),
                              ),
                            ...activeCustomers.map(
                              (customer) => DropdownMenuItem(
                                value: customer.customerId,
                                child: Text(customer.name),
                              ),
                            ),
                          ],
                          onChanged: widget.isEditing
                              ? null
                              : (value) {
                                  setState(() {
                                    _customerId = value;
                                    final matches = activeCustomers
                                        .where((c) => c.customerId == value);
                                    if (matches.isNotEmpty &&
                                        _addressController.text.isEmpty) {
                                      _addressController.text =
                                          matches.first.address;
                                    }
                                  });
                                },
                          validator: (value) => value == null || value.isEmpty
                              ? 'Customer is required'
                              : null,
                        ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Job title',
                          prefixIcon: Icon(Icons.handyman_outlined),
                        ),
                        validator: (value) =>
                            Validators.required(value, fieldName: 'Title'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _descriptionController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.notes_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _addressController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<JobPriority>(
                        // ignore: deprecated_member_use
                        value: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        items: JobPriority.values
                            .map(
                              (priority) => DropdownMenuItem(
                                value: priority,
                                child: Text(priority.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _priority = value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule),
                        title: Text(
                          _scheduledDate == null
                              ? 'Schedule (optional)'
                              : DateFormat('EEE d MMM yyyy • HH:mm')
                                  .format(_scheduledDate!),
                        ),
                        subtitle: const Text(
                          'If set, the job starts as Scheduled',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_scheduledDate != null)
                              IconButton(
                                onPressed: () =>
                                    setState(() => _scheduledDate = null),
                                icon: const Icon(Icons.clear),
                              ),
                            IconButton(
                              onPressed: _pickSchedule,
                              icon: const Icon(Icons.edit_calendar_outlined),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryButton(
                        label: widget.isEditing ? 'Save Changes' : 'Create Job',
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
