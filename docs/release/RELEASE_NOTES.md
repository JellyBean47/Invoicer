# Business Buddy — Release Notes

## 1.0.0 Closed Beta (build 1)

**Date:** August 2026  
**Audience:** ~5 invited South African service business owners (Android)

### What’s in this beta

- Customers (create, search, archive/restore, timeline)
- Jobs with status lifecycle and smart actions
- Quotes with tax/discount and convert-to-job
- Invoices (draft → finalize), PDF share, payments
- Expenses and estimated profit
- Live dashboard + period reports
- Daily briefing and preference-controlled notifications
- Offline-friendly Firestore cache + sync status
- Settings for business, tax, terms, and notifications

### Known limitations

- Firebase must be configured before real use (`docs/FIREBASE_SETUP.md`)
- Invoice numbering is local-counter MVP (Cloud Functions later)
- Owner-only roles (no manager/employee UI yet)
- iOS is not the release priority for this beta
- Payment QR codes and report export are deferred

### Crash-free critical path (must pass before inviting owners)

1. Sign up → verify email → business setup  
2. Create customer → create job → complete job  
3. Generate / create invoice → finalize → share PDF  
4. Record partial then full payment  
5. Add expense → confirm reports/dashboard profit updates  

### Privacy

Analytics and Crashlytics are anonymous. Customer names, phones, addresses, and money amounts are not sent as analytics properties.
