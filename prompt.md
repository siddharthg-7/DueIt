We are now starting STEP 12 of the DueIt production implementation.

This is NOT a feature-development step.

This is a:

PRODUCTION QA + SECURITY + DATA INTEGRITY AUDIT

The objective is to verify that the existing DueIt implementation behaves correctly as a complete application before we add major new features.

==================================================
CURRENT VERIFIED STATE
==================================================

DueIt currently includes:

- Firebase Authentication
- Business setup
- Customer management
- Due management
- Due status calculation
- Partial payments
- Full payments
- Payment history
- Local reminders
- Android notifications
- Recurring dues
- Monthly / quarterly / yearly recurrence
- Weekly recurrence
- Financial planning dashboard
- Collection trends
- Needs Attention
- Firestore offline persistence
- Connectivity UX
- 148 automated tests
- flutter analyze = 0 issues
- Debug APK builds successfully

Do NOT add new product features during this step.

Do NOT add:

- AI
- WhatsApp
- SMS
- Email
- Payment gateway
- UPI integration
- Expenses
- Accounting
- New navigation
- New database

==================================================
PART 1 — FULL END-TO-END USER FLOW
==================================================

Perform a complete audit of the main business flow:

New user
→ Sign up
→ Business setup
→ Dashboard
→ Add Customer
→ Add Due
→ Configure Reminder
→ Save
→ Due appears
→ Reminder scheduled
→ Record partial payment
→ Remaining amount updates
→ Record final payment
→ Due becomes PAID
→ Reminder cancelled
→ Dashboard updates

Verify there are no broken transitions.

Verify no screen displays mock/static financial values.

All financial values must originate from real application state.

==================================================
PART 2 — AUTHENTICATION
==================================================

Audit:

Sign up
Login
Logout
Session persistence
Invalid credentials
Empty fields
Validation
Loading states
Permission errors
Network errors

Verify:

Unauthenticated user cannot access protected business data.

After logout:

Customer state
Due state
Payment state
Recurring schedule state

must not leak into another authenticated session.

Test:

User A login
→ data visible

Logout

User B login
→ only User B data visible

==================================================
PART 3 — MULTI-TENANT SECURITY
==================================================

This is CRITICAL.

Audit Firestore rules for:

users/{uid}/customers
users/{uid}/dues
users/{uid}/payments
users/{uid}/recurring_due_schedules

Verify:

User A:

READ own data → ALLOW
CREATE own data → ALLOW
UPDATE own data → ALLOW
DELETE own data → ALLOW

User A:

READ User B data → DENY
CREATE under User B → DENY
UPDATE User B → DENY
DELETE User B → DENY

Verify:

ownerId cannot be changed.

businessId cannot be changed.

Unauthenticated requests are denied.

Do not use recursive wildcards.

==================================================
PART 4 — DATA INTEGRITY
==================================================

Audit relationships:

Customer
Due
Payment
RecurringSchedule

Verify:

Every Due references a valid customer belonging to the same owner.

Every Payment references a valid Due belonging to the same owner.

Every Payment references the correct customer.

Every generated Due references the correct recurring schedule.

A user must not be able to create:

User A Due
→ User B Customer

or:

User A Payment
→ User B Due

==================================================
PART 5 — PAYMENT INTEGRITY
==================================================

Audit:

Full payment
Partial payment
Multiple payments
Payment deletion
Remaining balance
Paid status
Partially paid status

Test:

Due = ₹5,000

Payment = ₹2,000

Remaining = ₹3,000

Payment = ₹3,000

Remaining = ₹0

Status = PAID

Attempt:

Payment = ₹1

after fully paid

Must be rejected.

Attempt:

Payment > remaining

Must be rejected.

Attempt:

Payment = 0

Must be rejected.

Attempt:

Negative payment

Must be rejected.

==================================================
PART 6 — DUE STATUS
==================================================

Verify centralized status calculation:

CANCELLED
PAID
PARTIALLY_PAID
OVERDUE
DUE
UPCOMING

Priority:

CANCELLED
↓
PAID
↓
PARTIALLY_PAID
↓
date-based status

Test date boundaries carefully.

==================================================
PART 7 — DASHBOARD FINANCIAL INTEGRITY
==================================================

Verify:

To Collect Today
Collected Today
Remaining Today
Overdue
Upcoming
Monthly Expected
Monthly Collected
Monthly Outstanding
Collection Rate
Collection Trend

Use real test data.

Example:

Today:

Due A = ₹5,000
Payment = ₹2,000

Yesterday:

Due B = ₹4,000
Payment = ₹1,000

Tomorrow:

Due C = ₹3,000

Expected:

To Collect Today = ₹3,000

Collected Today = ₹2,000

Overdue = ₹3,000

Upcoming = ₹3,000

Verify no double counting.

==================================================
PART 8 — RECURRING DUE INTEGRITY
==================================================

Audit:

Monthly
Quarterly
Yearly
Weekly

Verify:

No duplicate occurrences.

Occurrence IDs remain deterministic.

Historical dues never change when schedule configuration changes.

Example:

August = ₹1,500

Edit recurring schedule:

₹1,500 → ₹2,000

August remains:

₹1,500

Future occurrences:

₹2,000

Verify:

Pause
Resume
Stop

behave correctly.

Verify maximum catch-up limit.

==================================================
PART 9 — REMINDER INTEGRITY
==================================================

Audit:

Reminder creation
Reminder editing
Reminder cancellation
Paid cancellation
Cancelled Due cancellation
Partial payment
Notification tap

Verify:

Paid Due has no pending reminder.

Cancelled Due has no pending reminder.

Editing Due date cancels old reminder and creates new reminder.

Changing reminder option does the same.

Do not leave stale notifications.

==================================================
PART 10 — ANDROID NOTIFICATION AUDIT
==================================================

Inspect:

AndroidManifest.xml

Verify required permissions and receivers.

Verify:

POST_NOTIFICATIONS

SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM

and other permissions are actually required by the implementation.

Do not retain unnecessary permissions.

Verify notification channel configuration.

Verify notification IDs are deterministic and stable.

Verify notification tap routing.

==================================================
PART 11 — OFFLINE AUDIT
==================================================

Verify the existing Firestore offline architecture.

Test:

Offline:

Add Customer
Add Due
Record Payment
Edit Due
Cancel Due

Verify immediate local state.

Reconnect.

Verify synchronization.

Verify no duplicate records.

Verify dashboard recalculates.

Verify search/filter continue working.

Do NOT introduce SQLite.

==================================================
PART 12 — APP RESTART
==================================================

Test:

Online:

Create data.

Disconnect network.

Close application.

Reopen.

Verify cached data is available.

Verify application does not crash.

Reconnect.

Verify synchronization.

==================================================
PART 13 — DATA LEAK AUDIT
==================================================

Search the codebase for:

hardcoded customer names
hardcoded amounts
fake payment data
placeholder financial metrics
mock dashboards
sample data accidentally included in production state
test data loaded automatically

Remove accidental production mock data.

UI placeholders are acceptable only where they are clearly empty states.

==================================================
PART 14 — ERROR HANDLING
==================================================

Audit every major user action.

Errors must distinguish:

Validation
Authentication
Authorization
Network
Firestore
Notification

Avoid:

"Something went wrong."

when a more useful message is possible.

Verify loading states prevent duplicate submission.

==================================================
PART 15 — DOUBLE SUBMISSION
==================================================

Test rapidly tapping:

Add Customer
Save Due
Record Payment
Create Recurring Schedule

Verify duplicate records cannot be created.

==================================================
PART 16 — DELETE SAFETY
==================================================

Audit deletion.

Customer deletion must not destroy financial history accidentally.

Due deletion/cancellation must not corrupt payment calculations.

Payment deletion must recalculate:

Paid
Remaining
Status
Dashboard

Recurring schedule deletion must not delete historical Due records.

==================================================
PART 17 — SEARCH AND FILTER
==================================================

Verify:

Customer search
Due search
Today filter
Upcoming filter
Overdue filter
Paid filter

Work with:

Empty data
Large data
Partial search
Case differences
Whitespace
Special characters

==================================================
PART 18 — UI/UX AUDIT
==================================================

Compare the running application against the original Google Stitch design.

Audit:

Colors
Typography
Spacing
Cards
Buttons
Bottom navigation
Top bars
Empty states
Loading states
Error states
Dialogs
Bottom sheets
Form validation

Do not redesign the application.

Only fix clear regressions.

==================================================
PART 19 — ACCESSIBILITY
==================================================

Audit:

Text readability
Touch target sizes
Contrast
Semantic labels
Keyboard behavior
Form field focus
Screen reader labels where appropriate

Do not sacrifice the Stitch design unnecessarily.

==================================================
PART 20 — PERFORMANCE
==================================================

Look for:

N+1 Firestore queries
unnecessary rebuilds
large widget rebuilds
duplicate streams
duplicate listeners
memory leaks
unclosed controllers
unclosed subscriptions

Verify:

Dues screen
Customers screen
Dashboard

do not create duplicate subscriptions when repeatedly opened.

==================================================
PART 21 — FIRESTORE COST REVIEW
==================================================

Review:

watchCustomers
watchDues
watchPayments
watchRecurringSchedules

Verify no accidental listeners are created repeatedly.

Verify listeners are disposed when no longer required.

Document expected Firestore read behavior for a typical small business.

Do not optimize prematurely.

==================================================
PART 22 — SECURITY CODE AUDIT
==================================================

Search for:

hardcoded Firebase credentials
API secrets
private keys
service-account JSON
passwords
tokens
secret API keys

No secrets should be committed into source code.

Firebase client configuration values that are intentionally public identifiers are not equivalent to private secrets.

Do not expose actual secrets in the final report.

==================================================
PART 23 — DEPENDENCY AUDIT
==================================================

Inspect pubspec.yaml.

Identify:

unused dependencies
duplicate functionality
obviously outdated dependencies
unnecessary packages

Do NOT perform a mass dependency upgrade.

Only recommend upgrades that have a clear security or correctness reason.

Do not upgrade flutter_local_notifications during this audit unless a concrete issue is discovered.

==================================================
PART 24 — TEST EXPANSION
==================================================

Add tests only for genuine uncovered risks discovered during the audit.

Do not inflate the test count artificially.

Run:

dart format .
flutter analyze
flutter test
flutter build apk --debug

==================================================
PART 25 — PHYSICAL DEVICE
==================================================

If an Android device is available:

Install the debug APK.

Test at minimum:

1. Login
2. Add customer
3. Add due
4. Schedule reminder
5. Receive reminder
6. Tap notification
7. Partial payment
8. Full payment
9. Recurring due
10. Offline create
11. Reconnect
12. App restart

If no device is available:

DO NOT claim physical verification.

Clearly report:

"Physical-device verification not performed."

==================================================
FINAL REPORT
==================================================

Provide a production audit report with:

1. End-to-end flow result
2. Authentication result
3. Firestore security result
4. Data integrity result
5. Payment integrity result
6. Due status result
7. Dashboard result
8. Recurring result
9. Reminder result
10. Android notification result
11. Offline result
12. Restart result
13. Data leak result
14. Error handling result
15. Double-submission result
16. Delete safety result
17. Search/filter result
18. UI/UX result
19. Accessibility result
20. Performance result
21. Firestore cost observations
22. Security code audit
23. Dependency audit
24. New tests added
25. Total tests
26. flutter analyze
27. APK build
28. Physical-device verification
29. Critical issues
30. Recommended fixes

IMPORTANT:

Classify every discovered issue as:

CRITICAL
HIGH
MEDIUM
LOW
INFORMATIONAL

Do NOT silently fix risky architectural/security issues without reporting them.

Do not start STEP 13.

STOP after the audit.