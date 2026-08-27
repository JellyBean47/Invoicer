# Business Buddy

A lightweight business companion for small South African service businesses — customers, jobs, quotes, invoices, PDF share, payments, expenses, and reports.

Planning docs: [`docs/BusinessBuddy/`](docs/BusinessBuddy/)  
Handover: [`docs/HANDOVER.md`](docs/HANDOVER.md)  
Release / beta: [`docs/release/`](docs/release/)

## Status

**Phases 1–11 implemented in code** (foundation → release readiness).

**Firebase:** live project `business-buddy-cdc8f` (FlutterFire configured). See [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md) and [`docs/HANDOVER.md`](docs/HANDOVER.md).

**Next human step:** finish dogfood, then signed Play App Bundle + closed beta with ~5 owners ([`docs/release/CLOSED_BETA.md`](docs/release/CLOSED_BETA.md)).

## Run locally

```bash
flutter pub get
flutter run
```

## Verify

```bash
flutter analyze lib test
flutter test
```

## Release build

See [`docs/release/BUILD_RELEASE.md`](docs/release/BUILD_RELEASE.md).

## Project layout

```
lib/
  core/           # theme, constants, utils
  models/
  repositories/   # Firestore / Auth IO only
  services/       # business rules + telemetry
  providers/      # Riverpod
  navigation/
  features/       # auth, customers, jobs, invoices, …
  pdf/            # invoice PDF template
  shared/widgets/
docs/BusinessBuddy/   # product specifications
docs/release/         # checklist, listing, beta guide
firebase/             # Firestore rules + indexes
```
