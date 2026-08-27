# Business Buddy
Document: 00_PROJECT_OVERVIEW.md
Version: 1.0
Status: Planning
Depends On: None
---

# Project Overview

## Product Name
Business Buddy (working name)

## Mission
Every business owner should be able to manage their business from their phone without needing Excel, a calculator, or paper.

## Tagline Positioning
Do not market it as an accounting app. Market it as a **business companion** that happens to keep accurate records.

The word "accounting" makes people expect payroll, VAT submissions, bank reconciliation, balance sheets, SARS compliance, etc. Instead, aim for:

> Everything a small business owner needs to track customers, jobs, invoices, and payments.

---

# Target Users

Small business owners who:
* Use WhatsApp daily
* Do not have expensive accounting software
* Do not employ an office administrator
* Perform administrative work themselves
* Need something affordable, simple, and reliable

## First Target Market
Do not market to everyone. Choose **one** profession first.

Examples:
* Hair salons
* Mechanics
* Tutors
* Electricians
* Plumbers
* Photographers
* Cleaning services
* Garden services
* Guesthouses

Once one group loves it, expand.

---

# Problems Solved

WhatsApp stores conversations, not business information.
* A plumber remembers customers by chat history
* A mechanic remembers invoices by scrolling
* A tutor remembers appointments by reading old messages
* A cleaner keeps payment information in notebooks

Business Buddy transforms scattered information into structured business records.

---

# Core Product Modules

* Customers
* Bookings / Jobs
* Quotes
* Invoices
* Dashboard
* Payments
* Expenses (simple)
* Notes / Timeline
* PDF exports
* Reports

Nothing fancy. Just incredibly fast.

---

# Product Philosophy

Don't build something people think is "cool." Build something that makes them say:

> "Wait... this saves me 20 minutes every day."

## Secret Feature
Every screen should answer:

> "What's the next thing I need to do?"

## Wow Feature
Owner gets a WhatsApp message about work needed.
They open the app → **New Job** → customer saved → appointment created → invoice ready later.

No notebooks. No Excel. No sticky notes.

## Calculator Philosophy
> The owner should never need a calculator.

The software does 100% of the math.

---

# Revenue Model

* Free trial: 14 days
* Basic: **R99/month**
* Pro: **R199/month**
* Premium: **R299/month**

Example:
* 50 customers paying R199/month ≈ **R9,950/month** recurring revenue before expenses

---

# Supported Devices

* Primary: Android phones
* Later: iOS
* Future: Tablets / Desktop

---

# Tech Stack

* Frontend: Flutter (Android first)
* Backend: Firebase
* Authentication: Firebase Authentication
* Database: Cloud Firestore
* File storage: Firebase Storage
* Notifications: Firebase Cloud Messaging
* Analytics: Firebase Analytics
* Crash reporting: Firebase Crashlytics
* Server logic: Cloud Functions

---

# Prioritized Ideas (Strongest → Weakest)

1. WhatsApp Business Assistant — organize customers, bookings, deposits, invoices around WhatsApp
2. Quote & Invoice Generator — select customer, add items, generate PDF, send on WhatsApp
3. Small Business Dashboard — money today, jobs remaining, outstanding payments, profit
4. Customer Reminder System — appointment reminders prepared for WhatsApp

These combine into one product: **Business Buddy**.

---

# Development Approach

Treat Cursor like a junior developer on a team.
Give it a Software Requirements Specification and implement in phases.
AI performs much better with clear specifications than open-ended ideas.

## Development Package Structure

```
BusinessBuddy/
├── 00_PROJECT_OVERVIEW.md
├── 00A_DOMAIN_GLOSSARY.md
├── 01_PRODUCT_VISION.md
├── 02_FEATURE_SPECIFICATION.md
├── 03_USER_FLOWS.md
├── 04_DATABASE_DESIGN.md
├── 05_FIREBASE_ARCHITECTURE.md
├── 06_SECURITY_RULES.md
├── 07_UI_UX_GUIDELINES.md
├── 08_DESIGN_SYSTEM.md
├── 09_BUSINESS_RULES.md
├── 10_PDF_INVOICE_SPEC.md
├── 11_REPORTING_ENGINE.md
├── 12_NOTIFICATION_SYSTEM.md
├── 13_DEVELOPMENT_STANDARDS.md
├── 14_IMPLEMENTATION_ROADMAP.md
└── ROADMAP.md
```

---

# MVP Advice

Don't spend two months building before showing anyone.
Build the smallest version in about a week, then ask five real business owners to try it.

If three say "Could you add this one thing?", you're on the right track.
If nobody seems interested, change direction quickly.

AI makes building fast — the real advantage comes from testing ideas just as fast.

---

# Guiding Principle

Record information once. Reuse it forever.
The software performs the calculations. The user performs the business.
