import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_exception.dart';
import '../../../models/app_settings.dart';
import '../../../models/business.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/sync_providers.dart';
import '../../../shared/widgets/app_loading.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _businessName = TextEditingController();
  final _ownerName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _registration = TextEditingController();
  final _vat = TextEditingController();
  final _tax = TextEditingController();
  final _prefix = TextEditingController();
  final _terms = TextEditingController();

  bool _hydrated = false;
  bool _saving = false;

  @override
  void dispose() {
    _businessName.dispose();
    _ownerName.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _registration.dispose();
    _vat.dispose();
    _tax.dispose();
    _prefix.dispose();
    _terms.dispose();
    super.dispose();
  }

  void _hydrate(Business business, AppSettings settings) {
    if (_hydrated) return;
    _businessName.text = business.businessName;
    _ownerName.text = business.ownerName;
    _phone.text = business.phone;
    _email.text = business.email;
    _address.text = business.address;
    _registration.text = business.registrationNumber;
    _vat.text = business.vatNumber;
    _tax.text = settings.defaultTaxPercent.toString();
    _prefix.text = settings.invoicePrefix;
    _terms.text = settings.paymentTermsDays.toString();
    _hydrated = true;
  }

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(businessProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final pending = ref.watch(pendingSyncProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: businessAsync.when(
        loading: () => const AppLoading(message: 'Loading settings...'),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (business) {
          if (business == null) {
            return const Center(child: Text('Business not found.'));
          }
          return settingsAsync.when(
            loading: () => const AppLoading(message: 'Loading settings...'),
            error: (error, _) => Center(child: Text(error.toString())),
            data: (settings) {
              final effective =
                  settings ?? AppSettings.defaults(business.businessId);
              _hydrate(business, effective);

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
                  Text(
                    'Business information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _businessName,
                    decoration: const InputDecoration(labelText: 'Business name'),
                  ),
                  TextField(
                    controller: _ownerName,
                    decoration: const InputDecoration(labelText: 'Owner name'),
                  ),
                  TextField(
                    controller: _phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  TextField(
                    controller: _address,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 2,
                  ),
                  TextField(
                    controller: _registration,
                    decoration: const InputDecoration(
                      labelText: 'Registration number (optional)',
                    ),
                  ),
                  TextField(
                    controller: _vat,
                    decoration:
                        const InputDecoration(labelText: 'VAT number (optional)'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Invoice settings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _tax,
                    decoration: const InputDecoration(
                      labelText: 'Default tax percent',
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _prefix,
                    decoration:
                        const InputDecoration(labelText: 'Invoice prefix'),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  TextField(
                    controller: _terms,
                    decoration: const InputDecoration(
                      labelText: 'Default payment terms (days)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  Text(
                    'Currency: ${effective.currency}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: _saving
                        ? null
                        : () => _saveBusinessAndInvoice(effective),
                    child: Text(_saving ? 'Saving...' : 'Save business & invoice'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable notifications'),
                    value: effective.notificationsEnabled,
                    onChanged: (value) => _patchSettings(
                      effective.copyWith(notificationsEnabled: value),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Daily briefing'),
                    subtitle: const Text('One morning summary instead of spam'),
                    value: effective.dailyBriefingEnabled,
                    onChanged: effective.notificationsEnabled
                        ? (value) => _patchSettings(
                              effective.copyWith(dailyBriefingEnabled: value),
                            )
                        : null,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Job notifications'),
                    value: effective.jobNotifications,
                    onChanged: effective.notificationsEnabled
                        ? (value) => _patchSettings(
                              effective.copyWith(jobNotifications: value),
                            )
                        : null,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Invoice notifications'),
                    value: effective.invoiceNotifications,
                    onChanged: effective.notificationsEnabled
                        ? (value) => _patchSettings(
                              effective.copyWith(invoiceNotifications: value),
                            )
                        : null,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Payment notifications'),
                    value: effective.paymentNotifications,
                    onChanged: effective.notificationsEnabled
                        ? (value) => _patchSettings(
                              effective.copyWith(paymentNotifications: value),
                            )
                        : null,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reminders'),
                    value: effective.reminderNotifications,
                    onChanged: effective.notificationsEnabled
                        ? (value) => _patchSettings(
                              effective.copyWith(reminderNotifications: value),
                            )
                        : null,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Business insights'),
                    value: effective.businessInsights,
                    onChanged: effective.notificationsEnabled
                        ? (value) => _patchSettings(
                              effective.copyWith(businessInsights: value),
                            )
                        : null,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Detailed lock-screen previews'),
                    subtitle: const Text('Off by default for privacy'),
                    value: effective.detailedNotificationPreviews,
                    onChanged: effective.notificationsEnabled
                        ? (value) => _patchSettings(
                              effective.copyWith(
                                detailedNotificationPreviews: value,
                              ),
                            )
                        : null,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Quiet hours'),
                    subtitle: Text(
                      '${AppSettings.formatMinuteOfDay(effective.quietHoursStartMinute)}'
                      ' – ${AppSettings.formatMinuteOfDay(effective.quietHoursEndMinute)}',
                    ),
                    trailing: const Icon(Icons.schedule),
                    onTap: () => _editQuietHours(effective),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Notification history'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/notifications'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Offline & backup',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Offline mode'),
                    subtitle: const Text(
                      'Keep working without internet; Firestore syncs later',
                    ),
                    value: effective.offlineEnabled,
                    onChanged: (value) => _patchSettings(
                      effective.copyWith(offlineEnabled: value),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Auto backup'),
                    value: effective.autoBackup,
                    onChanged: (value) => _patchSettings(
                      effective.copyWith(autoBackup: value),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Connection'),
                    subtitle: Text(
                      online
                          ? (pending > 0
                              ? 'Online · syncing $pending item${pending == 1 ? '' : 's'}'
                              : 'Online · all changes synced')
                          : 'Offline · changes will sync automatically',
                    ),
                    trailing: Icon(
                      online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                    ),
                    onTap: online
                        ? () => _flushSync(business.businessId)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final info = snapshot.data;
                      final version = info == null
                          ? '…'
                          : '${info.version} (${info.buildNumber})';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(AppConstants.appName),
                        subtitle: Text(
                          'Version $version\n'
                          'Anonymous crash reports and usage analytics help improve the app. '
                          'Customer names, phones, and invoice amounts are never sent to analytics.',
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _saveBusinessAndInvoice(AppSettings settings) async {
    setState(() => _saving = true);
    try {
      final tax = int.tryParse(_tax.text.trim());
      final terms = int.tryParse(_terms.text.trim());
      if (tax == null || terms == null) {
        throw const AppException('Tax and payment terms must be whole numbers.');
      }

      await ref.read(settingsServiceProvider).updateBusinessProfile(
            businessId: settings.businessId,
            businessName: _businessName.text,
            ownerName: _ownerName.text,
            phone: _phone.text,
            email: _email.text,
            address: _address.text,
            registrationNumber: _registration.text,
            vatNumber: _vat.text,
          );

      final updated = await ref.read(settingsServiceProvider).updateSettings(
            settings.copyWith(
              defaultTaxPercent: tax,
              invoicePrefix: _prefix.text,
              paymentTermsDays: terms,
            ),
          );
      await ref
          .read(localNotificationServiceProvider)
          .syncDailyBriefingSchedule(updated);
      ref.invalidate(businessProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _patchSettings(AppSettings settings) async {
    try {
      final updated =
          await ref.read(settingsServiceProvider).updateSettings(settings);
      await ref
          .read(localNotificationServiceProvider)
          .syncDailyBriefingSchedule(updated);
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _editQuietHours(AppSettings settings) async {
    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.quietHoursStartMinute ~/ 60,
        minute: settings.quietHoursStartMinute % 60,
      ),
      helpText: 'Quiet hours start',
    );
    if (start == null || !mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.quietHoursEndMinute ~/ 60,
        minute: settings.quietHoursEndMinute % 60,
      ),
      helpText: 'Quiet hours end',
    );
    if (end == null || !mounted) return;
    await _patchSettings(
      settings.copyWith(
        quietHoursStartMinute: start.hour * 60 + start.minute,
        quietHoursEndMinute: end.hour * 60 + end.minute,
      ),
    );
  }

  Future<void> _flushSync(String businessId) async {
    final ok = await ref.read(syncServiceProvider).flush(
          businessId: businessId,
          notify: true,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Sync complete' : 'Sync could not finish'),
      ),
    );
  }
}
