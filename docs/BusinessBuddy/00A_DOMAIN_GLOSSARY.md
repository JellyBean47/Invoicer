# Business Buddy
Document: 00A_DOMAIN_GLOSSARY.md
Version: 1.0
Status: Planning
Depends On: 00_PROJECT_OVERVIEW.md
---

# Domain Glossary

This document defines every business term used in Business Buddy.
The AI must never invent alternate meanings for these terms.

---

# Core Terms

## Customer
A person or business receiving services from the owner.
Must have a name and phone number.
May optionally have email, company, address, and notes.

## Job
Work performed (or scheduled to be performed) for a customer.
Always belongs to exactly one customer and one business.

## Quote
A non-binding estimate before work begins.
Quotes do not affect revenue or reports until converted and invoiced.

## Invoice
A request for payment.
Once finalized, it becomes an immutable financial document.

## Payment
Money received against an invoice.
Cannot exceed the outstanding balance.
Cannot be edited or deleted after recording (corrections use a future correction workflow).

## Outstanding Balance
Invoice Grand Total − Amount Paid.

## Archived
Hidden from active views but never permanently deleted.
Archived records remain searchable and linked to history.

## Soft Delete
Archive instead of permanent deletion for business records that must remain for history and reporting.

## Timeline
A chronological history of events for a customer (jobs, quotes, invoices, payments, notes).

## Smart Actions
Suggested next steps shown after a task completes (e.g. after job completed → Generate Invoice).

## Business Companion
Product positioning: not an accounting package, CRM, or bookkeeping system — a simple daily operating companion for small businesses.

## Estimated Profit
Revenue − Expenses.
Not full accounting profit; a simple operational estimate.

## Service Catalog
Saved commonly used services and products (e.g. PVC Pipe 20mm — R120) for fast quote/invoice creation.

## Daily Briefing
Optional morning/evening summary notification covering jobs, invoices due, payments, and key activity.

---

# Status Terms

## Customer Status
* Active
* Archived

## Job Status
* Draft
* Scheduled
* In Progress
* Completed
* Cancelled

## Quote Status
* Draft
* Sent
* Accepted
* Rejected
* Expired

## Invoice Status
* Draft
* Final
* Paid
* Partially Paid / Partial
* Overdue
* Cancelled

## Payment Methods
* Cash
* EFT
* Card
* Other

---

# Money Terms

## Cents
Smallest currency unit used for storage.
Example: R150.00 is stored as `15000`.

## Subtotal
Sum of all line totals before discount and tax.

## Discount
Optional reduction applied after subtotal and before tax.
Cannot exceed subtotal.

## Tax Amount
Automatically calculated tax.
Never manually typed.

## Grand Total
Final invoice amount after discount and tax.

---

# Role Terms (Future-Ready)

## Owner
Full access. Only role enabled in Version 1.

## Manager
Almost full access (future).

## Employee
Can create jobs and customers; cannot see financial reports or business settings (future).

## Accountant / Viewer
Future read-focused roles.
