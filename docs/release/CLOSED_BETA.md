# Closed Beta Guide (~5 business owners)

## Goal

Prove the crash-free critical path with real owners:

**customer → job → invoice → payment**

## Before inviting anyone

1. Finish [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) engineering + critical path items  
2. Configure Firebase and deploy rules/indexes  
3. Upload an App Bundle to Play Console **Closed testing**  
4. Prepare a WhatsApp/email invite with install link + 5-minute script  

## Who to invite

Prefer owners who already invoice somehow (WhatsApp photos, notebooks, Excel):

- 2–3 plumbers / electricians / handymen, **or**  
- 2–3 salon / beauty owners  

Pick **one** primary profession for messaging; mix is fine for learning.

## 5-minute script for testers

1. Create your business profile  
2. Add one real customer  
3. Create and complete one job  
4. Create invoice → Finalize → Share PDF (WhatsApp yourself)  
5. Record a payment (even a small test amount)  
6. Optional: add one expense and open Reports  

Ask them to voice-note: “What was confusing?” and “Would you use this next week?”

## What you watch

- Crashlytics (fatal + non-fatal)  
- Analytics: `invoice_finalized`, `payment_recorded`, `pdf_shared`  
- Direct feedback — friction beats feature requests at this stage  

## Success criteria (Phase 11 acceptance)

- Critical path is crash-free for you on a release build  
- At least 5 owners can complete customer → job → invoice → payment  
- No P0 data-loss or payment-balance bugs  

## Out of scope for this beta

- Public Play production listing  
- iOS TestFlight  
- Subscription billing go-live  
- Multi-employee roles  
