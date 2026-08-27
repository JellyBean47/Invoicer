import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_spacing.dart';

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key});

  static const _commands = '''
# 1. Create a Firebase project in console.firebase.google.com
#    (or: firebase projects:create business-buddy-sa)

# 2. Enable Email/Password authentication
#    Authentication → Sign-in method → Email/Password

# 3. Create a Firestore database (test mode first, then deploy rules)

# 4. From this project folder:
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_PROJECT_ID --platforms=android,ios

# 5. Deploy security rules:
firebase deploy --only firestore:rules

# 6. Run the app:
flutter run
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Firebase setup required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Phase 1 is ready, but Firebase is not configured yet. '
                'Run these commands once, then restart the app.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _commands,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(const ClipboardData(text: _commands));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Commands copied')),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy setup commands'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
