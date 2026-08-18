You are now the lead developer for a mobile application called "DueIt".

IMPORTANT:
Do NOT modify the project yet.

First perform a complete audit of the project that was exported from Google AI Studio.

This project was originally designed in Google Stitch and then prototyped in Google AI Studio.

The AI Studio implementation is only a prototype/reference implementation.

The final production application must be built in Flutter/Dart.

==================================================
ABOUT DUEIT
==================================================

DueIt is a mobile financial collection assistant for small business owners.

Its core purpose is:

"Know what you're owed. Know when to collect. Never miss a payment."

Target users include:

- Karate instructors
- Gym owners
- Tuition teachers
- Dance instructors
- Coaching centers
- Freelancers
- Membership businesses
- Small service businesses
- Local businesses

The primary question DueIt must answer is:

"How much money do I need to collect today?"

==================================================
IMPORTANT PRODUCT FLOW
==================================================

The core workflow is:

Customer
→ Amount
→ Reason
→ Due Date
→ Reminder
→ Due
→ Notification
→ Payment
→ Mark Paid
→ Payment History

The primary action is:

ADD DUE

The core user journey is:

Login
→ Business Setup
→ Home
→ Add Due
→ Select Person
→ Enter Amount
→ Select Due Date
→ Configure Reminder
→ Optional Recurrence
→ Create Due
→ Home updates
→ Due appears
→ Open Due
→ Mark Paid
→ Dashboard updates
→ Payment history updates

==================================================
MVP FEATURES
==================================================

The MVP must eventually support:

1. Authentication
2. Business profile/setup
3. Customer/person management
4. Create a payment due
5. Amount
6. Description/reason
7. Due date
8. Reminder configuration
9. Today's collection
10. Upcoming payments
11. Overdue payments
12. Mark payment as paid
13. Payment history
14. Customer details
15. Recurring payments
16. Basic financial summary

Future features are NOT part of the current MVP:

- UPI integration
- Payment gateway
- WhatsApp automation
- AI financial assistant
- Advanced accounting
- GST
- Invoicing
- Bank integrations
- Staff accounts
- Multi-business management
- Complex expense management

==================================================
FINAL PRODUCTION STACK
==================================================

The final application must use:

Flutter
Dart
Riverpod
GoRouter
Material 3
Firebase Authentication
Cloud Firestore
Firebase Cloud Messaging
SQLite/local persistence
Local notifications

The goal is to use free/open-source tooling and free service tiers wherever possible.

The existing TypeScript project is NOT the final production technology.

Do not assume that the existing TypeScript architecture should be preserved.

==================================================
YOUR TASK
==================================================

Inspect the entire exported project.

Do NOT modify any files yet.

Analyze:

1. Every screen
2. Every route
3. Every component
4. Every interaction
5. Every form
6. Every piece of application state
7. Every mock-data source
8. Every feature that has been implemented
9. Every feature that is only visually represented
10. Every feature that is missing
11. Every broken interaction
12. Every inconsistent state update
13. Every hardcoded value
14. Every TypeScript-specific implementation
15. Every place where the implementation differs from the intended Stitch design

==================================================
FEATURE AUDIT
==================================================

Create a feature matrix with:

Feature
Status
Evidence in code
What actually works
What is missing
What must be rebuilt in Flutter

Use these statuses:

IMPLEMENTED
PARTIALLY_IMPLEMENTED
UI_ONLY
MOCKED
BROKEN
MISSING

Audit at minimum:

Authentication
Business setup
Home dashboard
Today's collection
Customer management
Add customer
Customer details
Create due
Edit due
Delete/cancel due
Due details
Due status
Upcoming payments
Overdue payments
Mark paid
Partial payment
Payment history
Reminders
Recurring payments
Insights
Empty states
Validation
Navigation

==================================================
DATA / STATE AUDIT
==================================================

Identify:

- Customer model
- Due model
- Payment model
- Business model
- Reminder model
- Recurrence model

For each one, explain:

- where it is defined
- what fields exist
- how state is stored
- whether it is persistent
- whether it is only mock state
- whether multiple screens share the same state
- whether changes survive reload

==================================================
IMPORTANT TEST
==================================================

Determine whether this complete flow actually works:

Login
→ Home
→ Add Due
→ Select customer
→ Enter ₹1,500
→ Enter description
→ Select today's date
→ Configure reminder
→ Create
→ Return to Home
→ Today's collection increases
→ Open the due
→ Mark Paid
→ Today's collection decreases
→ Due becomes PAID
→ Customer payment history updates

Do not assume that an interaction works just because a button exists.

Trace the actual code/state changes.

==================================================
VISUAL AUDIT
==================================================

Compare the current implementation against the imported Stitch design.

Identify:

- wrong layouts
- wrong spacing
- wrong typography
- wrong colors
- wrong component shapes
- missing components
- incorrect navigation
- inconsistent cards
- incorrect hierarchy
- missing empty states
- incorrect mobile behavior

Do not redesign anything yet.

==================================================
FINAL OUTPUT
==================================================

At the end, provide:

1. Overall project assessment
2. Feature audit table
3. Data/state audit
4. Navigation audit
5. Core user-flow audit
6. Visual/design audit
7. Critical bugs
8. Missing MVP features
9. Features that should be discarded/rebuilt
10. Recommended Flutter architecture
11. Recommended implementation order

IMPORTANT:

Do not modify files.

Do not install packages.

Do not convert anything yet.

Do not start implementing.

This is an inspection and planning task only.