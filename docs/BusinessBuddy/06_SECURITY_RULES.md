# Business Buddy
Document: 06_SECURITY_RULES.md
Version: 1.0
Status: Planning
Depends On
00_PROJECT_OVERVIEW.md
01_PRODUCT_VISION.md
02_FEATURE_SPECIFICATION.md
03_USER_FLOWS.md
04_DATABASE_DESIGN.md
05_FIREBASE_ARCHITECTURE.md
---

# Purpose

This document defines the security model for Business Buddy.

Every piece of business data must remain private.

No business may ever access another business's information.

Security takes priority over convenience.

---

# Security Principles

1. Deny by Default
Everything is denied unless explicitly allowed.

---

2. Least Privilege
Users receive only the permissions they require.

---

3. Business Isolation
Every document belongs to exactly one business.
Users may only access documents belonging to their business.

---

4. Never Trust the Client
All client input is considered untrusted.
Every request is validated before being accepted.

---

5. Immutable Financial Records
Finalized invoices and recorded payments cannot be silently altered.
Corrections must create new records or follow documented correction workflows.

---

# Defense in Depth

Security exists in multiple layers:
* UI — hide actions the user cannot perform
* Service Layer — validate every action
* Firebase Security Rules — enforce access
* Cloud Functions — perform trusted operations

Never rely only on Firebase Security Rules.

---

# Authentication Rules

Only authenticated users may access Business Buddy.
Anonymous users are not permitted.
Email verification is required before business data becomes available.
Sessions expire according to Firebase Authentication.

---

# User Roles

Version 1
Owner

Future
Manager
Employee
Accountant
Viewer

Only the Owner role is enabled in Version 1.
The system architecture must support future roles.

---

# Business Isolation

Every document contains
businessId

Before any read

Verify

Authenticated User
↓
Retrieve User Profile
↓
Read businessId
↓
Compare
Requested Document.businessId
↓
If Match
Allow
Else
Deny

This rule applies to every collection.

---

# Collection Access Matrix

Users
Read: Own Profile
Write: Own Profile
Delete: Never

---

Businesses
Read: Own Business
Update: Owner Only
Delete: Never

---

Customers
Create: Owner
Read: Owner
Update: Owner
Archive: Owner
Delete: Never

---

Jobs
Create: Owner
Read: Owner
Update: Owner
Archive: Owner
Delete: Never

---

Quotes
Create: Owner
Read: Owner
Update: Owner
Archive: Owner
Delete: Never

---

Invoices

Draft
Create
Read
Update
Finalize

Final
Read
Duplicate
Record Payment
No Editing
No Deletion

---

Payments
Create
Read
Never Edit
Never Delete

Refunds handled through future workflow.

---

Reports
Read
Generate
Never manually edit.

---

Settings
Read
Update
Owner Only

---

Activity Logs
Read
Owner
Write
System Only
Delete
Never

---

# Invoice Protection

Draft invoices
Editable.

Final invoices
Locked.

Locked Fields

Items
Subtotal
Tax
Grand Total
Invoice Number
Customer
Issue Date

Financial data cannot change after finalization.

---

# Payment Protection

Payments cannot be edited.
Payments cannot be deleted.

Incorrect payments require
Correction Transaction
Future Feature.

Audit history remains complete.

---

# Input Validation Rules

Strings
Trim whitespace.
Reject empty required fields.
Maximum length defined per field.

---

Phone Numbers
Normalize before saving.
Remove spaces.
Validate country format.
Unique per business.

---

Money
Integer only.
No negatives unless specifically allowed.
No floating point.
No decimal storage.

---

Tax
0%
to
100%
Only integer percentages allowed.

---

Invoice Totals
Recalculated before save.
Client totals ignored.
Server totals become source of truth.

---

# Rate Limiting

Prevent abuse.

Login attempts limited.
Password reset limited.
Bulk writes monitored.
Repeated failed operations temporarily blocked.

---

# File Security

Business Logo
Private

Invoice PDFs
Private

Attachments
Private

Temporary share links expire automatically.
Files cannot be accessed by other businesses.

---

# Audit Logging

Automatically log

Customer Created
Customer Updated
Customer Archived
Job Created
Job Completed
Quote Sent
Quote Accepted
Invoice Created
Invoice Finalized
Payment Recorded
Settings Updated
Login
Logout
Backup
Restore

Every log contains

Timestamp
User ID
Business ID
Entity
Action
Device
App Version

---

# Offline Security

Offline data encrypted.
Sensitive information never stored in plain text.
Sync queue validated before upload.
Failed sync never bypasses validation.

---

# Cloud Function Security

Only Cloud Functions may

Generate invoice numbers.
Generate quote numbers.
Generate job numbers.
Update invoice counters.
Generate cached reports.
Execute scheduled maintenance.

Clients never perform trusted operations.

---

# Error Messages

Do not reveal internal implementation.

Good
"You do not have permission to perform this action."

Bad
"Firestore permission denied on collection invoices."

Never expose backend details.

---

# Logging & Monitoring

Monitor

Authentication failures
Permission denials
Sync failures
Cloud Function failures
Unexpected exceptions
Repeated suspicious activity

Critical events trigger alerts.

---

# Disaster Recovery

Automatic encrypted backups.
Restore process documented.
Audit logs preserved.
Financial records recoverable.
Business data protected against accidental deletion.

---

# Security Review Checklist

Every new feature must answer:

Does it expose another business's data?
Can totals be manipulated?
Can records be deleted?
Can users bypass permissions?
Can invoice numbers be duplicated?
Can financial history be lost?

If any answer is "Yes", the feature must be redesigned.

---

# Guiding Principle

Trust is Business Buddy's most valuable feature.

Business owners must be confident that:

Their data is private.
Their financial records are accurate.
Their reports cannot be corrupted.
Their history cannot disappear.

Security is never optional.
It is part of every feature.
