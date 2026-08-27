# Business Buddy — Handover Document

**Date:** 2 August 2026 (updated after live Firebase + dogfood fixes)  
**Product working name:** Business Buddy  
**Repo:** `/Users/ebenoelofse/Desktop/Invoicer`  
**Stack:** Flutter (Android-first) + Firebase Auth + Cloud Firestore + Riverpod + go_router  
**Firebase project:** `business-buddy-cdc8f`

---

## 1. Executive summary

Business Buddy is a mobile **business companion** for small South African service businesses (plumbers, salons, mechanics, etc.). It is **not** an accounting package.

Current state:

1. Full product specification under `docs/BusinessBuddy/`
2. **Phases 1–11 implemented in code** (foundation through release readiness)
3. **Firebase is connected** — `flutterfire configure` done for Android + iOS; Firestore rules + indexes deployed
4. App runs on iOS simulator; early dogfood has created customers/jobs; invoice create bug was fixed
5. **Remaining work is mostly go-to-market / release ops**, not a new feature phase (there is no Phase 12 in the roadmap)

**Last known verification:** `flutter analyze lib test` clean; **68** unit tests passing.

---

## 2. What was done

### 2.1 Product documentation (complete)

| Location | Purpose |
|----------|---------|
| `docs/BusinessBuddy/` | Full V1 spec package (vision, features, DB, rules, PDF, reports, notifications, roadmap) |
| `docs/FIREBASE_SETUP.md` | How to connect Firebase |
| `docs/release/` | Checklist, release notes, Play listing, closed beta, build guide |
| `docs/HANDOVER.md` | This document |

### 2.2 Phases 1–8 — Core product (done)

- Auth: register, login, forgot password, email verification, business setup wizard
- Customers: CRUD, unique phone, archive/restore, timeline, smart actions
- Jobs: numbers, status lifecycle, filters, generate-invoice path
- Quotes: line items + tax, convert accepted → job (quotes ≠ revenue)
- Invoices: draft/final, immutable finals, duplicate for correction
- Payments: record against outstanding, partial/paid status
- Expenses: soft archive, estimated profit (revenue − expenses)
- Dashboard + Reports: derived totals, period selector, charts/insights

Architecture preserved throughout:

- UI → providers → **services** → repositories → Firebase  
- Money = **integer cents** (`Money.calculate` / `Money.formatZar`)  
- Soft archive; no hard-delete of financial history  

### 2.3 Phase 9 — PDF invoices (done)

- Structured A4 PDF (`lib/pdf/invoice_pdf_template.dart`)
- `InvoicePdfService` validate + generate + share
- Finalized invoices only; filename `Invoice_[Number].pdf`
- Packages: `pdf`, `printing`

### 2.4 Phase 10 — Notifications & offline (done)

- Settings (`/settings`): business, tax, prefix, payment terms, notification prefs, quiet hours, offline/backup
- Notification history (`/notifications`), unread badge
- Daily briefing engine + local notification schedule
- FCM wrapper (needs live project — now available)
- Offline banner, sync queue, Firestore persistence
- Overdue invoice sweep on dashboard load

### 2.5 Phase 11 — Release readiness (done in repo)

- Crashlytics + anonymous Analytics (PII/amount keys stripped)
- Events: app open, invoice create/finalize, job completed, quote converted, payment, report viewed, PDF shared
- Android signing template (`android/key.properties.example`), app label **Business Buddy**
- Settings → About (version + privacy note)
- Docs: `docs/release/*`

### 2.6 Live Firebase + platform fixes (done this session)

| Fix | Detail |
|-----|--------|
| FlutterFire configure | Project `business-buddy-cdc8f`; Android + iOS apps registered |
| Rules/indexes deploy | `firebase deploy --only firestore:rules,firestore:indexes` |
| iOS minimum version | Raised to **15.0** (Firebase SPM requirement) |
| Crashlytics build script | Fixed SPM path lookup so `flutter run` on iOS no longer fails |
| Invoice create | Parent invoice written **before** line items (batch was failing security rules) |

### 2.7 Codebase snapshot

- Feature folders: `auth`, `customers`, `dashboard`, `expenses`, `invoices`, `jobs`, `payments`, `quotes`, `reports`, `notifications`, `settings`, `setup`, `shell`
- Key packages: Firebase Auth/Firestore/Messaging/Crashlytics/Analytics, Riverpod, go_router, pdf/printing, local notifications, connectivity
- Tests: **68** passing under `test/`

---

## 3. What still has to be done

### 3.1 Immediate product dogfood (manual)

Confirm the full path on a running build (hot **restart** after invoice fix):

- [ ] Sign up → verify email → business setup → dashboard  
- [ ] Customer → job → complete → invoice → **finalize** → **Share PDF**  
- [ ] Record partial then full payment  
- [ ] Add expense → check dashboard/reports profit  
- [ ] Settings / notifications / daily briefing  
- [ ] Airplane mode create → reconnect → sync  

### 3.2 Firebase console polish (if not already)

- [ ] Email/Password auth enabled  
- [ ] Crashlytics + Analytics + Cloud Messaging enabled in console  
- [ ] Confirm data appearing under Firestore (customers, jobs, invoices, …)  

### 3.3 Closed beta / Play Store (Phase 11 acceptance — human ops)

1. Upload keystore + `android/key.properties` — `docs/release/BUILD_RELEASE.md`  
2. `flutter build appbundle --release`  
3. Work through `docs/release/RELEASE_CHECKLIST.md`  
4. Play Console **Closed testing** + listing copy from `PLAY_STORE_LISTING.md`  
5. Capture screenshots + feature graphic  
6. Host a short **privacy policy** URL (required for production)  
7. Invite **~5 real owners** — `docs/release/CLOSED_BETA.md`  
8. Watch Crashlytics + feedback for 1–2 weeks before production  

### 3.4 No engineering “Phase 12”

Implementation roadmap ends at Phase 11. Post-beta product themes (from `docs/BusinessBuddy/ROADMAP.md`) only after owners validate V1:

- Attachments, richer branding  
- Multi-employee roles  
- Calendar / recurring jobs  
- Service catalog / light inventory  
- Payment QR codes  
- AI insights (later)  

### 3.5 Explicitly deferred (do not build yet)

- Full accounting / SARS / payroll / bank reconciliation  
- Multi-branch enterprises  
- Subscription billing go-live  
- iOS App Store as primary release (Android first)  
- Report PDF / Excel / CSV export  

---

## 4. Architecture decisions to preserve

1. **UI never talks to Firestore directly** — Repository → Service → UI/providers  
2. **Business rules live in services**, not widgets  
3. **Money = integer cents**  
4. **Soft delete / archive** for financial history  
5. **Top-level collections** with `businessId` on documents  
6. **Do not invent flows** — update specs first  
7. **Quotes ≠ revenue**; only finalized invoices (+ payments/expenses) feed reports  
8. **Final invoices and payments are immutable**; corrections = duplicate draft / new records  
9. **Reports are derived**, never manually editable totals  
10. **Analytics never include customer PII or money amounts**  
11. **Invoice line items:** create/update parent invoice **before** writing `items` subcollection (security rules `get()` parent)

---

## 5. Important routes

| Route | Screen |
|-------|--------|
| `/login`, `/register`, `/forgot-password`, `/verify-email` | Auth |
| `/setup` | Business setup wizard |
| `/dashboard` | Live dashboard |
| `/customers…`, `/jobs…`, `/quotes…`, `/invoices…`, `/expenses…` | Core CRUD + payments (`…/pay`) |
| `/reports` | Period reports |
| `/settings` | Settings + About |
| `/notifications` | Notification history |

---

## 6. How to continue (next session)

1. Read this handover + `docs/release/RELEASE_CHECKLIST.md`  
2. Finish manual critical-path dogfood on simulator/device  
3. Build signed Android AAB and start closed testing  
4. Only then pick post-beta features from the product roadmap  

Suggested prompt:

> Continue Business Buddy from `docs/HANDOVER.md`. Firebase project `business-buddy-cdc8f` is live. Help complete the closed-beta checklist (signed AAB + Play closed testing) and fix any Crashlytics / dogfood bugs.

---

## 7. Known gaps / risks

| Item | Risk | Action |
|------|------|--------|
| Local invoice/job/quote counters | Spec prefers Cloud Functions | OK for beta; migrate before scale |
| Play assets missing | Cannot submit polished listing | Screenshots + feature graphic |
| Privacy policy URL | Blocks production | Host short policy page |
| Security rules MVP-grade | Fine for closed beta | Tighten before public launch |
| FlutterFire Crashlytics script | Broke iOS builds under SPM | Patched in `ios/Runner.xcodeproj`; watch future `flutterfire configure` overwrites |
| Overdue status | Mostly derived / sweep on dashboard | Optional scheduled job later |
| Roles (Manager/Employee) | Not enabled in UI | Keep Owner-only for V1 |

---

## 8. Verification

```bash
cd /Users/ebenoelofse/Desktop/Invoicer
flutter analyze lib test
flutter test
flutter run
```

Expected: no analyzer issues; **68** tests green; app opens past Firebase setup into auth/dashboard.

Firebase CLI (when needed):

```bash
firebase use business-buddy-cdc8f
firebase deploy --only firestore:rules,firestore:indexes
```

---

## 9. Bottom line

**Done:** Spec package + Phases 1–11 + live Firebase (`business-buddy-cdc8f`) + iOS 15 / Crashlytics build fixes + invoice create fix.

**Still to do:** Finish critical-path dogfood → signed Play AAB → closed beta with ~5 owners → learn what they need next. That—not a new Phase 12—is the path to a product someone will use every day.
