# Business Buddy
Document: 02_FEATURE_SPECIFICATION.md
Version: 1.0
Status: Planning
Depends On:
- 00_PROJECT_OVERVIEW.md
- 01_PRODUCT_VISION.md
---

# Feature Specification

This document defines every feature included in Version 1.

Every feature must have:
- A clearly defined purpose.
- Expected user behaviour.
- Validation rules.
- Error handling.
- Security considerations.
- Performance expectations.

No feature may be implemented differently unless this document is updated.

---

# FEATURE 1 — Authentication

## Purpose
Allow business owners to securely access their own business information.

## Supported Methods
- Email & Password
- Google Sign-In (Future)
- Apple Sign-In (Future)

## Requirements
The user must verify their email address.
Forgot password functionality must be available.
Sessions remain active until logout.
The application should automatically restore previous sessions.

## Validation
Email must be valid.
Password minimum length:
8 characters
Passwords are never stored locally.

---

# FEATURE 2 — Business Profile

Each account owns exactly ONE business.

Business Profile contains:

Business Name
Owner Name
Phone Number
Email
Business Address
Business Logo
Tax Percentage
Currency
Invoice Prefix
Invoice Number Format
Default Payment Terms
Business Registration Number (Optional)
VAT Number (Optional)

The profile must be editable at any time.

Changing business information must never modify existing invoices.

Invoices preserve historical business information.

---

# FEATURE 3 — Dashboard

Purpose:
Provide immediate overview.

Dashboard displays:

Today's Jobs
Upcoming Jobs
Outstanding Invoices
Total Income Today
Total Income This Month
Invoices Created This Month
Payments Received Today
Outstanding Balance

Quick Actions

New Customer
New Job
New Quote
New Invoice

Dashboard cards must update automatically.

---

# FEATURE 4 — Customer Management

Purpose:
Maintain permanent customer records.

Customer Fields

Customer ID
Full Name
Phone Number
Email (Optional)
Business Name (Optional)
Physical Address (Optional)
Notes
Date Created
Date Updated
Status
Active
Archived

Validation

Phone number must be unique.
Name required.
Phone required.

Archive Rules

Archived customers remain searchable.
Archived customers preserve:

Jobs
Invoices
Payments
Quotes
Timeline

Deletion Rules

Customers cannot be permanently deleted if financial records exist.
Instead they are archived.

---

# FEATURE 5 — Customer Timeline

Every customer has a chronological timeline.

Timeline automatically records:

Customer Created
Quote Created
Quote Accepted
Job Scheduled
Job Started
Job Completed
Invoice Generated
Payment Received
Manual Notes

Timeline entries cannot be deleted.
Only manual notes may be edited.

---

# FEATURE 6 — Job Management

Purpose:
Track work.

Job Fields

Job Number
Customer
Description
Address
Scheduled Date
Scheduled Time
Status
Assigned Technician (Future)
Priority
Low
Normal
High
Emergency

Status Flow

Draft
↓
Scheduled
↓
In Progress
↓
Completed
or
Cancelled

Completed jobs cannot return to Draft.
Cancelled jobs remain visible.

---

# FEATURE 7 — Quote Management

Purpose
Create estimates before work begins.

Quote contains:

Customer
Items
Labour
Tax
Notes
Expiry Date
Status
Draft
Sent
Accepted
Rejected
Expired

Accepted Quotes
↓
Convert directly into Job.

No duplicate typing.

---

# FEATURE 8 — Invoice Management

Purpose
Generate professional invoices.

Invoice Number
Automatically generated.
Never duplicated.
Never reused.

Invoice Fields

Customer
Invoice Date
Due Date
Items
Labour
Tax
Discount (Optional)
Subtotal
Tax Amount
Grand Total
Notes
Payment Status
Draft
Final
Paid
Partially Paid
Overdue
Cancelled

Once Final:
Invoice cannot be edited.

If correction required:
Duplicate invoice into Draft.
Original remains unchanged.

---

# FEATURE 9 — Invoice Items

Each item contains:

Description
Quantity
Unit Price
Line Total

Rules

Quantity > 0
Price >= 0
Line Total calculated automatically.
Never editable.

---

# FEATURE 10 — Labour

Labour is treated as invoice items.

Example

Installation
2 Hours
R350/hour
Total
R700

Labour uses identical calculation rules.

---

# FEATURE 11 — Tax

Purpose
Automatically calculate tax.

User enables tax.
Select percentage.

Example
15%

Calculation

Subtotal
↓
Tax
↓
Grand Total

Tax Amount
Always calculated.
Never editable.

Business default tax percentage stored in Settings.
Individual invoices may override tax percentage if required.

---

# FEATURE 12 — Payments

Payment Methods

Cash
EFT
Card
Other

Fields

Payment Date
Amount
Reference
Notes

Validation

Cannot exceed outstanding balance.
Outstanding balance updates automatically.
Invoice becomes Paid automatically once balance reaches zero.

---

# FEATURE 13 — Reports

Available Reports

Today
This Week
This Month
This Year
Custom Range

Displays

Revenue
Tax Collected
Invoices
Payments
Outstanding
Average Invoice
Most Valuable Customers
Best Selling Services (Future)

Reports generated from invoice and payment records.
Users cannot edit report totals.

---

# FEATURE 14 — Search

Global Search

Searches:

Customer Name
Phone Number
Invoice Number
Quote Number
Job Number

Search results appear instantly.

---

# FEATURE 15 — PDF Generation

Generate professional PDF.

Includes

Business Logo
Business Details
Customer Details
Invoice Number
Items
Tax
Totals
Payment Terms
Footer

PDF layout identical across all devices.

---

# FEATURE 16 — Notifications

Notifications

Upcoming Jobs
Invoice Due
Payment Received
Overdue Invoice
Daily Reminder

Notifications configurable.

---

# FEATURE 17 — Settings

Business Settings

Tax
Currency
Theme
Invoice Prefix
Invoice Number Format
Payment Terms
Notification Preferences
Backup Preferences

---

# FEATURE 18 — Offline Support

Application functions without internet.

Offline Features

Create Customers
Create Jobs
Create Quotes
Create Invoices
Record Payments

Changes automatically synchronise.
Conflicts resolved using documented sync rules.
No data lost.

---

# FEATURE 19 — Smart Actions (Core Design Principle)

After completing a task, suggest the next logical step.

Examples:

Job finished →
* Generate Invoice
* Share via WhatsApp
* Record Payment
* Schedule Follow-up

Customer created →
* Create Job
* Create Quote
* Create Invoice

The app guides the user to the next logical step instead of making them navigate menus.

---

# FEATURE 20 — Simple Expenses (Version 1)

Track operational expenses without full accounting.

Categories examples:
* Fuel
* Materials
* Equipment
* Office Supplies
* Rent
* Other

Dashboard can show:
* Revenue
* Expenses
* Estimated Profit (Revenue − Expenses)

---

# Global Rules

Money stored in integer cents.
No floating-point calculations.
Every financial action logged.
Invoice totals never manually editable.
Invoice numbers never duplicated.
Totals always calculated.
Reports generated automatically.
Deleted financial records archived.
Business data isolated per account.
Security rules enforced in Firebase.
Every screen must load within 2 seconds under normal conditions.
Every frequent action should require no more than three taps whenever practical.
