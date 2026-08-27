# Business Buddy
Document: 07_UI_UX_GUIDELINES.md
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
---

# Purpose

This document defines the user interface and user experience principles for Business Buddy.

The application must remain simple, predictable, fast and approachable for users with little or no technical experience.

Every screen, component and interaction must follow these guidelines.

---

# Screen Question Rule

Every screen must answer one question.

* Dashboard → "What needs my attention?"
* Customers → "Who am I working with?"
* Jobs → "What work do I have?"
* Invoices → "Who owes me money?"

If a screen tries to answer five questions, it is too complicated.

---

# Core UX Principles

1. Simplicity
Show only what the user needs right now.
Do not overload the screen.

---

2. Speed
Frequently used actions should require as few taps as possible.
Target:
Three taps or fewer whenever practical.

---

3. Clarity
Every button must clearly describe its purpose.
Avoid technical language.

Use:
"Create Invoice"

Instead of:
"Generate Financial Document"

---

4. Consistency
Buttons behave the same everywhere.
Save buttons always appear in the same location.
Back buttons always behave the same.
Confirmation dialogs always follow the same style.

---

5. Trust
Financial information must always be easy to verify.
Totals should stand out.
Statuses should be immediately recognizable.

---

# Navigation Structure

Bottom Navigation

Dashboard
Customers
Jobs
Invoices
Reports

Settings is accessed from Dashboard.
Search is globally available.

---

# Quick Actions / Command Palette

From any screen, a floating **"+"** button (or long-press) opens:

* New Customer
* New Job
* New Quote
* New Invoice
* Record Payment
* Search Everything

This reinforces speed and convenience.

---

# Dashboard

Purpose
Show today's business at a glance.

Contains

Today's Jobs
Outstanding Invoices
Revenue Today
Revenue This Month
Recent Activity
Quick Actions
Business Insights (simple calculated observations)

The dashboard should never scroll more than one screen on most devices.

---

# Customers Screen

Purpose
Manage customer records.

Layout

Search Bar
Filter Button
Customer List
Floating Action Button
Create Customer

Customer Card Displays

Name
Phone Number
Outstanding Balance
Last Activity Date
Status Badge

---

# Customer Profile

Sections

Customer Information
Timeline
Jobs
Quotes
Invoices
Payments
Notes

Floating Action Button
New Job

---

# Jobs Screen

Purpose
Display all work.

Filters

Today
Upcoming
Completed
Cancelled
Search

Job Card

Customer Name
Job Title
Date
Status
Priority

Tap opens full job.

---

# Job Details

Displays

Customer
Description
Address
Schedule
Timeline
Status

Buttons

Edit
Complete
Cancel
Generate Invoice

---

# Quotes Screen

List View

Customer
Quote Number
Expiry Date
Status
Amount

Color Indicators

Draft
Grey

Sent
Blue

Accepted
Green

Rejected
Red

Expired
Orange

---

# Invoices Screen

List

Invoice Number
Customer
Amount
Balance Remaining
Status
Issue Date

Search always visible.

---

# Invoice Details

Display

Invoice Header
Items
Labour
Subtotal
Discount
Tax
Grand Total
Payments
Notes

Actions

Share PDF
Record Payment
Duplicate
View Timeline

---

# Reports Screen

Cards

Today's Revenue
Weekly Revenue
Monthly Revenue
Outstanding
Tax Collected
Estimated Profit

Charts

Monthly Revenue
Invoices Created
Payment Trend

Buttons

Export PDF
Future

Export Excel
Future

---

# Settings Screen

Business Information
Invoice Settings
Tax
Notifications
Appearance
Backup
About
Help

---

# Search

Global search available from every major screen.

Results grouped

Customers
Jobs
Quotes
Invoices

Search updates while typing.

---

# Empty States

Every empty screen contains

Friendly Illustration
Simple explanation
Primary Action Button

Example

No customers yet.
Create your first customer to get started.

Button
Create Customer

---

# Loading States

Never show blank screens.

Use

Skeleton loaders
Progress indicators
Loading messages

Examples

Loading Customers...
Generating Invoice...
Syncing Changes...

---

# Error States

Explain the problem clearly.

Good
Unable to connect.
Your information is safely stored and will sync when you're back online.

Bad
Network Error 503.

---

# Success Messages

Keep short.

Examples

Customer Saved
Invoice Generated
Payment Recorded
Job Completed

Do not interrupt workflow.
Auto-dismiss after a few seconds.

---

# Confirmation Dialogs

Required for

Archive Customer
Cancel Job
Finalize Invoice
Delete Draft
Restore Backup

Dialog format

Title
Description
Primary Action
Cancel Button

---

# Colors

Green
Success

Blue
Information

Orange
Warning

Red
Error

Grey
Inactive

Never rely on color alone.
Always include text or icons.

---

# Typography

Large
Page Titles

Medium
Section Titles

Normal
Body Text

Small
Supporting Text

Numbers should be highly readable.
Currency values should use larger font sizes.

---

# Icons

Icons must always have labels.

Example
Invoice (with icon)

Not icon alone.

Icons assist understanding.
They never replace text.

---

# Forms

Required fields marked clearly.
Validation occurs immediately.
Show helpful messages.
Never erase entered data after validation failure.

---

# Buttons

Primary
Filled

Secondary
Outlined

Danger
Red

Disabled
Grey

Loading buttons display spinner.
Prevent duplicate taps.

---

# Accessibility

Large touch targets.
Readable font sizes.
High contrast.
Screen reader support.
Do not depend on color alone.
Support landscape and portrait.

---

# Responsive Design

Phones
Primary platform.

Tablets
Expanded layouts.

Desktop
Future.

No horizontal scrolling.

---

# Offline Experience

Show Offline Banner.
Continue normal operation.
Queue changes.
Notify when sync completes.

User should never fear losing work.

---

# Animation

Animations should be subtle.

Purpose
Guide attention.
Provide feedback.
Never delay work.

Target duration
200–300ms.

---

# Smart Actions

After completing a task,
suggest the next logical action.

Examples

Customer Created
↓
Create Job

Job Completed
↓
Generate Invoice

Invoice Paid
↓
Send Receipt

Dashboard
↓
Outstanding Invoice
↓
Record Payment

The app should guide rather than instruct.

---

# Three-Tap Rule

Common actions should require no more than three taps.

If a workflow exceeds three taps,
it should be redesigned where practical.

---

# Design Philosophy

Business Buddy should feel calm.
It should never overwhelm users.

The owner should always know:

Where they are.
What they are looking at.
What they can do next.

Every screen should reduce stress,
not create it.

The interface is successful when users stop thinking about the software and focus entirely on running their business.
