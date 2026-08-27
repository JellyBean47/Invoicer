# Business Buddy
Document: 04_DATABASE_DESIGN.md
Version: 1.0
Status: Planning
Depends On
00_PROJECT_OVERVIEW.md
01_PRODUCT_VISION.md
02_FEATURE_SPECIFICATION.md
03_USER_FLOWS.md
---

# Purpose

This document defines the complete Firestore database architecture.

Every collection, document, field, datatype, relationship and naming convention is defined here.

No field may be added or removed without updating this document.

---

# Database Philosophy

Business Buddy follows these principles:

Single Source of Truth
Every piece of information exists only once.

Derived Data
Reports are calculated from invoices and payments.

Immutable Financial Records
Final invoices are never modified.

Soft Deletes
Business data is archived rather than permanently removed.

Audit Logging
Every important business action is recorded.

Money Safety
Money is always stored as integer cents.
Never use floating point numbers.

---

# Naming Convention

Collections
lowercase_plural

Example
customers
jobs
payments

---

Document IDs
Firestore Auto IDs

Exception
Invoice Number
Quote Number
Job Number

These are generated separately and stored as fields.

---

Timestamps
Use Firebase Timestamp.
Never store formatted date strings.

---

Money
All monetary values stored as integer cents.

Example
R25.99
Stored as
2599

---

# Architecture Note

Use top-level collections with a `businessId` field on each document (not a single nested `businesses/{businessId}` tree). This improves indexing, querying, reporting, and scale.

---

# Top Level Collections

users
businesses
customers
jobs
quotes
invoices
payments
reports
activity_logs
settings
notifications
sync_queue
service_catalog
expenses

---

# USERS

Purpose
Authentication profile.

Fields

uid
string

email
string

businessId
string

displayName
string

photoUrl
string

emailVerified
boolean

role
string
(owner | manager | employee | accountant | viewer)
Version 1 uses owner only.

createdAt
timestamp

lastLogin
timestamp

status
active
disabled

---

# BUSINESSES

Fields

businessId
string

businessName
string

ownerName
string

phone
string

email
string

address
string

registrationNumber
string

vatNumber
string

currency
string

defaultTaxPercent
integer

invoicePrefix
string

invoiceCounter
integer

logoUrl
string

createdAt
timestamp

updatedAt
timestamp

---

# CUSTOMERS

Fields

customerId
string

businessId
string

name
string

phone
string

email
string

company
string

address
string

notes
string

tags
array of string
(optional: VIP, Late payer, Commercial, Residential)

status
active
archived

createdAt
timestamp

updatedAt
timestamp

archivedAt
timestamp

---

Rules
Phone number unique per business.
Archived customers remain searchable.

---

# JOBS

Fields

jobId
string

businessId
string

customerId
string

jobNumber
string

title
string

description
string

address
string

scheduledDate
timestamp

status
draft
scheduled
in_progress
completed
cancelled

priority
low
normal
high
emergency

createdAt
timestamp

updatedAt
timestamp

completedAt
timestamp

---

# QUOTES

Fields

quoteId
string

businessId
string

customerId
string

quoteNumber
string

status
draft
sent
accepted
rejected
expired

subtotal
int

discount
int

taxPercent
int

taxAmount
int

total
int

notes
string

expiryDate
timestamp

createdAt
timestamp

updatedAt
timestamp

---

# QUOTE ITEMS

Subcollection
quotes/{quoteId}/items

Fields

description
string

quantity
integer

unitPrice
integer

lineTotal
integer

displayOrder
integer

---

# INVOICES

Fields

invoiceId
string

businessId
string

customerId
string

jobId
string

invoiceNumber
string

status
draft
final
paid
partial
overdue
cancelled

subtotal
int

discount
int

taxPercent
int

taxAmount
int

grandTotal
int

amountPaid
int

balanceRemaining
int

notes
string

issueDate
timestamp

dueDate
timestamp

finalizedAt
timestamp

createdAt
timestamp

updatedAt
timestamp

---

# INVOICE ITEMS

Subcollection
invoices/{invoiceId}/items

Fields

description
quantity
unitPrice
lineTotal
displayOrder

---

# PAYMENTS

Fields

paymentId
string

businessId
string

invoiceId
string

customerId
string

amount
int

paymentMethod
cash
eft
card
other

reference
string

notes
string

receivedAt
timestamp

createdAt
timestamp

---

# EXPENSES

Fields

expenseId
string

businessId
string

category
string
(fuel | materials | equipment | office_supplies | rent | other)

description
string

amount
int

expenseDate
timestamp

notes
string

createdAt
timestamp

updatedAt
timestamp

---

# SERVICE CATALOG

Purpose
Saved commonly used services and products for fast quote/invoice creation.

Fields

serviceId
string

businessId
string

name
string

description
string

unitPrice
int

unitLabel
string
(optional: each, hour, day)

active
boolean

createdAt
timestamp

updatedAt
timestamp

Examples
* PVC Pipe 20mm — R120
* Labour (per hour) — R350
* Call-out Fee — R450

---

# ACTIVITY LOGS

Purpose
Audit Trail

Fields

logId
businessId
userId
entityType
entityId
action
oldValue
newValue
timestamp
device

---

Example Actions

Customer Created
Invoice Finalized
Payment Recorded
Customer Archived
Business Updated
Quote Converted

---

# REPORTS

Purpose
Cached report summaries.

Fields

businessId
period
year
month
revenue
taxCollected
outstanding
invoiceCount
paymentCount
expenseTotal
estimatedProfit
generatedAt

Reports are cache only.
Invoices and payments remain source of truth.
Monthly totals are calculated/derived — not the primary source of truth.

---

# SETTINGS

Fields

businessId
theme
currency
defaultTaxPercent
invoicePrefix
invoiceCounter
notificationsEnabled
offlineEnabled
autoBackup
language
updatedAt

---

# NOTIFICATIONS

Fields

notificationId
businessId
title
message
type
read
createdAt

---

# SYNC QUEUE

Purpose
Offline Synchronisation.

Fields

operationId
entityType
entityId
operation
create
update
archive
delete
payload
createdAt
retryCount
status
pending
processing
failed
completed

---

# Relationships

Business
↓
Customers
↓
Jobs
↓
Invoices
↓
Payments

Customer
↓
Quotes
↓
Jobs
↓
Invoices
↓
Payments

Invoice
↓
Invoice Items
↓
Payments

---

# Required Indexes

businessId + phone
businessId + status
businessId + createdAt
businessId + invoiceNumber
businessId + customerId
businessId + scheduledDate
businessId + paymentDate
businessId + month
businessId + year

---

# Soft Delete Rules

Customers
Archive

Jobs
Archive

Quotes
Archive

Invoices
Never delete

Payments
Never delete

Activity Logs
Never delete

Reports
Regenerated

---

# Money Rules

Never use decimals.
Never use doubles.
Never use floats.
Always use integers.
Every calculation performed by business logic.
Never trust user-entered totals.
Always recalculate before saving.

---

# Data Integrity Rules

Invoice totals must equal:

Sum(Line Totals)
↓
Minus Discount
↓
Plus Tax
↓
Grand Total

Balance Remaining
=
Grand Total
-
Amount Paid

Validation occurs before every save.
Invalid financial records are rejected.

---

# Database Constraints

No duplicate invoice numbers.
No duplicate quote numbers.
No duplicate job numbers.
No customer may belong to another business.
No invoice may reference a missing customer.
No payment may exceed invoice balance.
No report may overwrite invoice data.

---

# Guiding Principle

The database is the foundation of Business Buddy.

If the database remains correct,
the reports remain correct,
the invoices remain correct,
and the business owner can trust the application.
