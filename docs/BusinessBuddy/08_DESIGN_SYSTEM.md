# Business Buddy
Document: 08_DESIGN_SYSTEM.md
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
---

# Purpose

This document defines the visual design language used throughout Business Buddy.

Every screen, component and interaction must use this design system.

The objective is consistency.

Users should immediately recognise every screen as part of the same application.

Define a lightweight design system on top of Flutter's Material 3 — recognizable identity while using stable Flutter components.

---

# Design Philosophy

Business Buddy should feel:

Professional
Friendly
Modern
Clean
Reliable
Calm

The interface should never feel crowded.
Whitespace is intentional.
Simple beats flashy.

---

# Design Principles

Consistency over creativity.
Readability over decoration.
Function over aesthetics.
Fast interaction over unnecessary animation.
Business data always has visual priority.

---

# Grid System

Base spacing unit:
8dp

Common spacing

4dp
8dp
16dp
24dp
32dp

No arbitrary spacing values.

---

# Screen Margins

Left
16dp

Right
16dp

Top
16dp

Bottom
16dp

---

# Corner Radius

Small Components
8dp

Cards
12dp

Dialogs
16dp

Bottom Sheets
20dp

Large Buttons
12dp

---

# Elevation

Level 0
Background

Level 1
Cards

Level 2
Floating Buttons

Level 3
Dialogs

Avoid excessive shadows.

---

# Typography

Display
Dashboard totals

Page Titles
Headings

Section Titles

Body
Standard text

Caption
Helper text

Currency values use bold weight.
Invoice totals receive increased font size.

---

# Color Palette

Primary
Blue
Represents trust.

Secondary
Green
Represents success.

Background
Light Grey / White

Surface
White

Success
Green

Warning
Orange

Error
Red

Information
Blue

Inactive
Grey

Dark Mode uses equivalent accessible colors.

---

# Status Colors

Draft
Grey

Scheduled
Blue

In Progress
Orange

Completed
Green

Cancelled
Red

Paid
Green

Partially Paid
Orange

Overdue
Red

Archived
Grey

Never communicate status using color alone.
Always include text.

---

# Buttons

Primary
Filled
Used for the main action.

Secondary
Outlined
Used for less important actions.

Text Button
Low priority.

Danger Button
Red.
Requires confirmation.

Disabled
Reduced opacity.
No interaction.

Loading
Spinner replaces button icon.

---

# Floating Action Button

Used only for high-frequency actions.

Examples

Create Customer
Create Invoice
Create Job

Never display more than one floating action button per screen.

---

# Cards

Cards display summary information.

Examples

Customer Card
Job Card
Invoice Card
Report Card

Cards contain

Title
Key Information
Status
Primary Action

Cards are tappable.

---

# Lists

Scrollable.
Virtualized.
Searchable where applicable.
Support pull-to-refresh.
Infinite scrolling if required.

---

# Forms

Label above input.
Helper text below input.
Validation message below helper text.
Required fields clearly indicated.
Fields grouped logically.

---

# Input Components

Text Field
Phone Field
Email Field
Number Field
Currency Field
Date Picker
Time Picker
Dropdown
Switch
Checkbox
Radio Button
Stepper

Only use the appropriate component.

---

# Currency Display

Always display

Currency Symbol
↓
Amount

Example
R 1,250.00

Thousands separator required.
Two decimal places displayed.
Internally stored as integer cents.

---

# Tables

Used only where necessary.
Prefer cards on mobile.
Desktop support planned later.

---

# Charts

Simple.
Easy to understand.
No unnecessary decoration.
Maximum of four chart colors.
Accessible labels required.

---

# Dialogs

Standard Layout

Title
Description
Primary Button
Secondary Button

Never stack multiple dialogs.

---

# Snackbars

Used for

Success
Warnings
Undo

Auto-dismiss.
Never cover critical actions.

---

# Bottom Sheets

Preferred over full-screen dialogs for quick actions.

Examples

Record Payment
Select Customer
Choose Invoice Status

---

# Icons

Use Material Icons.
Icons always accompanied by text.
Never use decorative icons without purpose.

---

# Images

Business Logo
Customer Attachments
Future Job Photos

Images must scale correctly.
Support light and dark themes.

---

# Empty States

Every empty state contains

Illustration
Title
Description
Primary Action

Never show an empty white screen.

---

# Loading Indicators

Skeleton loaders preferred.
Spinner acceptable for short operations.
Loading text should explain what is happening.

---

# Animations

Duration
200–300ms

Use only for

Navigation
State changes
Feedback

Do not animate large lists unnecessarily.

---

# Accessibility

Minimum touch target
48dp

Support screen readers.
Maintain sufficient contrast.
Scalable fonts.
Landscape support.
Keyboard navigation where applicable.

---

# Responsive Behaviour

Phone
Primary design.

Tablet
Two-column layouts where appropriate.

Desktop
Future support.

No horizontal scrolling.

---

# Component Library

Reusable Components

Primary Button
Secondary Button
Danger Button
Customer Card
Job Card
Invoice Card
Report Card
Search Bar
Status Badge
Currency Label
Section Header
Confirmation Dialog
Loading Overlay
Empty State Widget
Timeline Widget

These components must be reused throughout the application.
Duplicate UI components are not permitted.

---

# Smart Component Behaviour

Components should adapt automatically.

Example

Outstanding Balance

Zero
↓
Green
"Paid"

Positive
↓
Orange
"Outstanding"

Negative values should never occur.

---

# Business Buddy Insights

Dashboard may highlight simple calculated observations:

* "Revenue is up 18% compared to last month."
* "3 invoices are overdue."
* "John Smith is your highest-paying customer this month."
* "You have 5 jobs scheduled tomorrow."

These are not AI features — simple calculations that make the dashboard feel helpful.

---

# Design Consistency Rules

Every screen follows the same spacing.
Every dialog follows the same layout.
Every list follows the same card style.
Every button follows the same design.
Every page title appears in the same location.

Users should never need to relearn the interface.

---

# Guiding Principle

The design system exists to make the application predictable.

Users should instantly recognise:

What information is important.
What action they should take next.
How every part of the application behaves.

Consistency builds confidence.
Confidence builds trust.
Trust keeps users coming back.
