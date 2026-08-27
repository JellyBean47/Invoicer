# Business Buddy
Document: 14_IMPLEMENTATION_ROADMAP.md
Version: 1.0
Status: Planning
Depends On
00_PROJECT_OVERVIEW.md
01_PRODUCT_VISION.md
02_FEATURE_SPECIFICATION.md
03_USER_FLOWS.md
04_DATABASE_DESIGN.md
05_FIREBASE_ARCHITECTURE.md
06_SECURITY_RULES.md
07_UI_UX_GUIDELINES.md
08_DESIGN_SYSTEM.md
09_BUSINESS_RULES.md
10_PDF_INVOICE_SPEC.md
11_REPORTING_ENGINE.md
12_NOTIFICATION_SYSTEM.md
13_DEVELOPMENT_STANDARDS.md
---

# Purpose

This document defines the exact order of implementation.

The AI must not jump ahead.
Each phase must meet acceptance criteria before the next begins.

---

# Version 1 Scope

Version 1 includes only:

* Customers
* Jobs
* Invoice creation
* Automatic tax calculation
* PDF invoices
* Payment tracking
* Simple expenses
* Dashboard
* Monthly reports
* Quotes (after invoices foundation)
* Offline basics
* Settings
* Notifications basics

Do not build advanced inventory, multi-branch, AI forecasting, or full accounting first.

---

# Phase 1 — Foundation

* Flutter project setup
* Firebase project connection
* Authentication (email/password)
* Theme / design system tokens
* Navigation shell
* Business setup wizard

Acceptance:
* User can sign up, verify email, log in, and reach an empty dashboard
* No business logic yet beyond auth and profile setup

---

# Phase 2 — Customers

* Customer CRUD
* Validation (unique phone per business)
* Search
* Archive / restore
* Customer profile shell
* Timeline foundation (customer created events)

Acceptance:
* Create, edit, search, archive customers
* Archived customers cannot receive new jobs/quotes/invoices

---

# Phase 3 — Jobs

* Create / schedule jobs
* Status transitions
* Priority
* Job list filters
* Timeline updates
* Attachments placeholder

Acceptance:
* Full job lifecycle works
* Completed jobs cannot return to Draft
* Smart Action after completion suggests Generate Invoice

---

# Phase 4 — Quotes

* Quote create/edit
* Items + tax calculations
* Status flow
* Convert quote → job

Acceptance:
* Accepted quote converts without retyping customer/items essentials
* Quotes do not affect revenue reports

---

# Phase 5 — Invoices

* Invoice draft/final
* Items + labour as line items
* Discount + tax
* Automatic totals (integer cents)
* Invoice numbering via Cloud Function
* Invoice immutability after finalization
* Duplicate-for-correction flow

Acceptance:
* Totals never manually editable
* Final invoices locked
* Invoice numbers unique and sequential

---

# Phase 6 — Payments

* Record payment
* Methods (cash/eft/card/other)
* Outstanding balance recalculation
* Auto status Paid / Partially Paid
* Timeline + dashboard updates

Acceptance:
* Payment cannot exceed outstanding balance
* Payments cannot be edited/deleted

---

# Phase 7 — Expenses

* Simple expense CRUD
* Categories
* Estimated profit on dashboard/reports

Acceptance:
* Revenue − Expenses = Estimated Profit
* Expenses never alter invoices/payments

---

# Phase 8 — Dashboard & Reports

* Dashboard cards
* Monthly / yearly summaries
* Outstanding report
* Tax collected
* Business insights cards
* Charts

Acceptance:
* Reports generated only from source records
* Users cannot edit report totals
* Load times meet performance goals

---

# Phase 9 — PDF Generation

* Structured PDF template
* Share via WhatsApp / email / download
* Permanent PDF after finalization

Acceptance:
* Matches 10_PDF_INVOICE_SPEC.md
* Generation under performance targets

---

# Phase 10 — Notifications & Offline Polish

* FCM + local reminders
* Daily briefing
* Offline cache + sync queue
* Settings completeness
* Performance / accessibility polish

Acceptance:
* App usable offline for core writes
* Notifications actionable and preference-controlled

---

# Phase 11 — Release

* Testing checklist pass
* Crashlytics / analytics
* Play Store assets
* Release notes
* Closed beta with 5 real business owners

**Code status (Aug 2026):** Crashlytics/Analytics wired, release signing template, Play listing copy, checklists, and beta guide live under `docs/release/`. Human ops remaining: Firebase live + signed AAB + invite ~5 owners.

Acceptance:
* Crash-free critical path
* At least 5 owners can complete: customer → job → invoice → payment

---

# Milestone Summary

**Milestone 1:** Foundation
**Milestone 2:** Customers
**Milestone 3:** Jobs
**Milestone 4:** Quotes
**Milestone 5:** Invoices
**Milestone 6:** Payments
**Milestone 7:** Expenses
**Milestone 8:** Dashboard & Reports
**Milestone 9:** Notifications / Offline / Settings
**Milestone 10:** Polish & Play Store readiness

---

# Working Rules During Implementation

1. Read related docs before coding a phase.
2. Do not invent flows, fields, or business rules.
3. Update documentation if a rule must change.
4. Finish and verify one phase before starting the next.
5. Show a thin vertical slice to real users early (after invoices + payments minimum).

---

# Guiding Principle

Specifications first. Implementation second.
The AI implements a blueprint — it does not design the product during coding.
