# Firebase Setup (Phase 1)

Business Buddy needs a Firebase project before auth and Firestore work.

## 1. Create project

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Create a project (suggested id: `business-buddy-sa`)
3. Keep **Google Analytics enabled** for Phase 11 release builds (Crashlytics + product analytics)

## 2. Enable Authentication

1. **Build → Authentication → Get started**
2. Enable **Email/Password**

## 3. Create Firestore

1. **Build → Firestore Database → Create database**
2. Start in **test mode** temporarily, or production mode and deploy rules next
3. Choose a region close to your users (e.g. `europe-west1`)

## 4. Configure Flutter

From the project root:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_PROJECT_ID --platforms=android,ios
```

This overwrites `lib/firebase_options.dart` and adds platform config files.

## 5. Deploy rules

```bash
firebase use YOUR_PROJECT_ID
firebase deploy --only firestore:rules
```

## 6. Run

```bash
flutter run
```

## Deploy indexes (Phase 2+)

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

## Crashlytics, Analytics & Messaging (Phase 10–11)

After `flutterfire configure`:

1. Confirm `android/app/google-services.json` exists (enables Crashlytics Gradle plugins)
2. Firebase Console → **Crashlytics** → enable / complete setup
3. Firebase Console → **Analytics** → confirm the property is linked
4. Firebase Console → **Cloud Messaging** (for FCM)
5. Build a release or profile app once so Crashlytics can register the app

Anonymous analytics only — see `lib/services/analytics_service.dart`.

## Phase 1 acceptance checklist

- [ ] Create account with email/password
- [ ] Receive verification email
- [ ] Verify email, then continue
- [ ] Complete business setup wizard
- [ ] Land on empty dashboard with bottom navigation

## Phase 2 acceptance checklist

- [ ] Create a customer
- [ ] Search customers by name/phone
- [ ] Edit customer details
- [ ] Archive and restore a customer
- [ ] See timeline events on the customer profile
- [ ] Confirm archived customers cannot start new work (message shown)

## Phase 3 acceptance checklist

- [ ] Create a job for an active customer
- [ ] Schedule a job (auto status → Scheduled)
- [ ] Move Draft → Scheduled → In Progress → Completed
- [ ] Confirm completed job cannot return to Draft
- [ ] See smart actions after completion (Generate Invoice placeholder)
- [ ] Filter Today / Upcoming / Completed / Cancelled
- [ ] Job events appear on customer timeline

## Phase 4 acceptance checklist

- [ ] Create a quote with items + tax
- [ ] Confirm totals cannot be typed (auto-calculated)
- [ ] Mark quote Sent → Accepted
- [ ] Convert accepted quote to a job
- [ ] Confirm job description includes quote line items
- [ ] Confirm quotes do not appear as revenue
