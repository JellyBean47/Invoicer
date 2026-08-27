# Business Buddy
Document: 03_USER_FLOWS.md
Version: 1.0
Status: Planning
Depends On
00_PROJECT_OVERVIEW.md
01_PRODUCT_VISION.md
02_FEATURE_SPECIFICATION.md
---

# Purpose

This document defines every user journey inside Business Buddy.

Every screen transition, navigation path and workflow must follow these documented flows.

No undocumented navigation paths may be introduced without updating this document.

> The AI is never allowed to invent a user flow.
> Every navigation path must exist in this document first.

---

# Application Launch

User opens app
↓
Splash Screen
↓
Check Authentication
↓
Authenticated?
YES
↓
Load Business Data
↓
Dashboard
NO
↓
Login Screen

---

# Login Flow

Open App
↓
Login
↓
Enter Email
↓
Enter Password
↓
Press Login
↓
Firebase Authentication
↓
Success
↓
Dashboard
Failure
↓
Display Error
↓
Remain on Login Screen

---

# First Time User

Open App
↓
Create Account
↓
Verify Email
↓
Login
↓
Business Setup Wizard
↓
Business Name
↓
Owner Name
↓
Phone Number
↓
Business Address
↓
Default Tax %
↓
Currency
↓
Invoice Prefix
↓
Finish Setup
↓
Dashboard

---

# Dashboard Flow

Dashboard
↓
Quick Actions
New Customer
New Job
New Quote
New Invoice
Reports
Search
Settings
Customers

Each button opens its respective module.

---

# Customer Flow

Dashboard
↓
Customers
↓
Customer List
↓
Press +
↓
Create Customer
↓
Enter Details
↓
Save
↓
Customer Profile
↓
Customer Timeline
↓
Create Job
or
Create Quote
or
Create Invoice

---

# Existing Customer Flow

Dashboard
↓
Customers
↓
Search Customer
↓
Open Customer
↓
View Timeline
↓
Choose Action
New Job
New Quote
New Invoice
Record Payment
Edit Customer
Archive Customer

---

# Job Creation Flow

Customer Profile
↓
New Job
↓
Enter Description
↓
Enter Address
↓
Select Date
↓
Select Time
↓
Priority
↓
Save
↓
Job Created
↓
Timeline Updated
↓
Dashboard Updated

---

# Job Status Flow

Draft
↓
Schedule
↓
In Progress
↓
Completed
↓
Generate Invoice
or
Cancelled

Cancelled Jobs remain searchable.
Completed Jobs cannot return to Draft.

---

# Quote Flow

Customer
↓
New Quote
↓
Add Items
↓
Add Labour
↓
Apply Tax
↓
Preview
↓
Save Draft
↓
Send
↓
Customer Response
Accepted
↓
Convert To Job
Rejected
↓
Archive
Expired
↓
Archive

---

# Invoice Flow

Customer
↓
New Invoice
↓
Add Products
↓
Add Labour
↓
Discount (Optional)
↓
Tax
↓
Preview
↓
Generate Invoice
↓
PDF Created
↓
Invoice Saved
↓
Timeline Updated
↓
Share
WhatsApp
Email
Download

---

# Payment Flow

Open Invoice
↓
Record Payment
↓
Choose Method
Cash
Card
EFT
Other
↓
Enter Amount
↓
Save
↓
Outstanding Updated
↓
Invoice Status
Paid
or
Partially Paid
↓
Reports Updated
↓
Dashboard Updated
↓
Timeline Updated

---

# Report Flow

Dashboard
↓
Reports
↓
Select Period
Today
Week
Month
Year
Custom
↓
Generate
↓
Charts
↓
Totals
↓
Export PDF (Future)
↓
Export Excel (Future)

---

# Search Flow

Search
↓
Type
↓
Live Search
↓
Results
Customers
Jobs
Quotes
Invoices
↓
Tap Result
↓
Open Record

---

# Archive Flow

Customer
↓
Archive
↓
Confirmation
↓
Archive Complete
↓
Hidden from Active Lists
↓
Available in Archived Section

---

# Settings Flow

Dashboard
↓
Settings
↓
Business Information
↓
Tax
↓
Notifications
↓
Invoice Settings
↓
Appearance
↓
Save
↓
Changes Applied

---

# Invoice Correction Flow

Invoice
↓
Duplicate
↓
Draft Created
↓
Edit Draft
↓
Finalize
↓
New Invoice Number
↓
Old Invoice Preserved

---

# Smart Action Flow

Whenever a task finishes,
Business Buddy should immediately suggest the next logical action.

Examples

Customer Created
↓
Suggest
Create Job
Create Quote
Create Invoice

---

Job Completed
↓
Suggest
Generate Invoice
Record Payment
Schedule Follow-up

---

Invoice Paid
↓
Suggest
Send Receipt
Add Customer Note
Schedule Future Job

---

# No Dead Ends Rule

Business Buddy should never have dead ends.

Most apps:
> Create Customer → Done.

Business Buddy:
> Create Customer → "What would you like to do next?"
* Create Job
* Create Quote
* Create Invoice
* Return to Dashboard

---

# Error Recovery Flow

Internet Lost
↓
Offline Mode Activated
↓
Continue Working
↓
Local Save
↓
Internet Returns
↓
Automatic Synchronization
↓
Success
or
Conflict Resolution

---

# Empty State Flow

No Customers
↓
Show Illustration
↓
Message
"No customers yet."
↓
Button
Create First Customer

---

No Jobs
↓
Create First Job

---

No Invoices
↓
Generate First Invoice

---

No Reports
↓
Create invoices to begin tracking income.

---

# Navigation Rules

Dashboard is always reachable.
Back button never loses unsaved work.
Every save operation provides confirmation.
Every delete requires confirmation.
Every archive requires confirmation.
Long-running operations display loading indicators.

---

# Three-Tap Rule

Frequently used actions should never require more than three taps.

Example

Dashboard
↓
New Invoice
↓
Customer
↓
Done

If more than three taps are required,
the workflow should be redesigned.

---

# Guiding UX Principle

The user should never stop and ask,
"What do I do next?"

Business Buddy should always make the next action obvious.

Every completed action should naturally lead to the next business task.
