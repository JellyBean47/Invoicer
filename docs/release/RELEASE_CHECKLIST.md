# Phase 11 — Release Checklist

Use this before every Play Store / closed-beta upload.

## Engineering

- [ ] `flutter analyze lib test` — no issues
- [ ] `flutter test` — all green
- [ ] Firebase configured (`lib/firebase_options.dart` has no `REPLACE_ME`)
- [ ] `firebase deploy --only firestore:rules,firestore:indexes`
- [ ] Crashlytics visible in Firebase console after a test non-fatal (debug builds may be disabled)
- [ ] Analytics events appearing (DebugView): `app_open`, `invoice_created`, `payment_recorded`, etc.
- [ ] Release signing: `android/key.properties` present (from `key.properties.example`)
- [ ] `flutter build appbundle --release` succeeds
- [ ] Install release build on a physical Android phone
- [ ] App label shows **Business Buddy**

## Critical path (crash-free)

- [ ] Register / login / email verify / business setup
- [ ] Customer → job → invoice → PDF share → payment
- [ ] Expense → dashboard profit / reports totals look right
- [ ] Airplane mode: create customer or job, then reconnect and confirm sync
- [ ] Daily briefing / notification prefs toggle without errors
- [ ] Finalized invoice cannot be edited; duplicate works

## Store package

- [ ] Version in `pubspec.yaml` bumped (`versionName+versionCode`)
- [ ] Release notes updated (`docs/release/RELEASE_NOTES.md`)
- [ ] Play listing copy ready (`docs/release/PLAY_STORE_LISTING.md`)
- [ ] Screenshots captured (phone + 7" if required)
- [ ] Feature graphic 1024×500
- [ ] Privacy policy URL live
- [ ] Closed testing track created with 5+ testers invited

## Security / product

- [ ] Firestore rules reviewed for invoices/payments/expenses
- [ ] No secrets committed (`key.properties`, keystore)
- [ ] Settings About text matches privacy stance
- [ ] Support contact for beta owners agreed

## After upload

- [ ] Testers can install from Play Closed Testing
- [ ] Collect feedback for 1–2 weeks
- [ ] Triage Crashlytics + top beta issues before open beta / production
