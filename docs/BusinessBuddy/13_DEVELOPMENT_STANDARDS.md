# Business Buddy
Document: 13_DEVELOPMENT_STANDARDS.md
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
---

# Purpose

This document defines the mandatory engineering standards for Business Buddy.

Every developer, whether human or AI, must follow these standards.

Consistency is more important than personal preference.

---

# Development Philosophy

Business Buddy prioritizes

Reliability
Maintainability
Readability
Security
Performance
Scalability

The application should remain easy to understand after years of development.

---

# Technology Stack

Frontend
Flutter

Language
Dart

Backend
Firebase

Authentication
Firebase Authentication

Database
Cloud Firestore

Storage
Firebase Storage

Notifications
Firebase Cloud Messaging

Server Logic
Cloud Functions

Analytics
Firebase Analytics

Crash Reporting
Firebase Crashlytics

---

# Project Structure

lib/
core/
config/
constants/
theme/
utils/
models/
repositories/
services/
controllers/
providers/
screens/
widgets/
components/
dialogs/
forms/
navigation/
features/
customers/
jobs/
quotes/
invoices/
payments/
expenses/
reports/
settings/
shared/
assets/
images/
icons/
fonts/
pdf/
functions/
firebase/
docs/
tests/

---

# Architecture Rules

Use Clean Architecture principles.

Presentation layer must not contain business logic.
Business logic belongs in Services.
Repositories manage data access only.
Models represent data only.
Widgets remain reusable.

---

# State Management

Single state management solution.
Do not mix multiple state management frameworks.
Business state isolated by feature.
UI reacts to state changes automatically.

---

# Naming Conventions

Files
snake_case.dart

Classes
PascalCase

Variables
camelCase

Constants
UPPER_SNAKE_CASE

Private members
_leadingUnderscore

Collection names
lowercase_plural

---

# Code Style

Small functions.
Single responsibility.
Meaningful names.
Avoid deep nesting.
Avoid duplicated logic.
Prefer composition over inheritance.

---

# Error Handling

Never ignore exceptions.
Catch expected failures.
Display user-friendly messages.
Log technical details.
Recover where possible.

---

# Logging

Log

Errors
Warnings
Important Events
Performance Metrics

Never log passwords.
Never log authentication tokens.
Avoid logging sensitive customer information.

---

# Validation

Validate

Before save
Before sync
Before report generation
Before PDF generation
Before payment recording

Client validation improves UX.
Server validation guarantees integrity.

---

# Dependency Rules

UI
↓
Controllers / Providers
↓
Services
↓
Repositories
↓
Firebase

Never reverse this direction.

---

# Offline Support

Every feature should consider offline mode.
Queue writes.
Retry automatically.
Display sync status.
Avoid duplicate operations.

---

# Testing Strategy

Unit Tests
Business logic
Calculation engine
Validation

Repository Tests
Database operations

Service Tests
Workflow logic

Widget Tests
Critical UI components

Integration Tests
End-to-end workflows

---

# Required Test Coverage

Invoice calculations
100%

Tax calculations
100%

Payment calculations
100%

Business rules
100%

Customer CRUD
High

Job workflows
High

Reports
High

UI components
Critical paths

---

# Performance Goals

Cold start
<3 seconds

Dashboard
<2 seconds

Search
<500ms

Invoice save
<2 seconds

PDF generation
<2 seconds

Memory usage
Optimized for mid-range Android devices.

---

# AI Development Rules

AI must

Read related documentation before coding.
Avoid assumptions.
Reuse existing components.
Follow naming conventions.
Follow architecture.
Write maintainable code.
Add documentation where appropriate.
Never bypass business rules.

AI must never:

Hardcode strings that should be localized/configurable.
Duplicate logic.
Calculate money using floating point.
Skip form validation.
Write Firestore calls outside repositories.
Create screens over 300 lines.
Leave TODO comments, placeholder code, or fake data.
Use deprecated Flutter APIs.

---

# Git Workflow

Main Branch
Stable

Development Branch
Active work

Feature Branches
One feature per branch.

Merge only after review and testing.
Meaningful commit messages required.

---

# Code Reviews

Every change reviewed for

Architecture
Security
Performance
Business rules
UI consistency
Documentation updates

No feature is complete without documentation.

---

# Documentation Rules

Every major feature must include

Purpose
Architecture
Data Flow
Dependencies
Known limitations
Future improvements

Documentation updated alongside code.

---

# Security Standards

No hardcoded secrets.
No API keys in source code.
Use Firebase Security Rules.
Validate every request.
Protect sensitive files.
Encrypt local sensitive data where appropriate.

---

# Accessibility Standards

Support screen readers.
Minimum touch target
48dp
Scalable text.
High contrast.
Keyboard accessibility where relevant.

---

# Release Checklist

Before every release

All tests pass.
No critical bugs.
Documentation updated.
Security rules reviewed.
Performance checked.
Crash-free testing completed.
Version number updated.
Release notes written.

---

# Definition of Done

A feature is complete only if

It works.
It is tested.
It follows the architecture.
It follows business rules.
It follows the design system.
It works offline where applicable.
It has documentation.
It introduces no known critical issues.

---

# Long-Term Maintainability

The project should remain understandable by a new developer within a reasonable amount of time.

Code should explain itself through structure and naming.
Complex logic should be documented.
Technical debt should be minimized.

---

# Guiding Principle

Business Buddy is intended to be a long-term product.

Every engineering decision should make future development easier, not harder.

Write software that future developers—and future AI systems—will thank you for maintaining.
