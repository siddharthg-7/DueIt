We are starting STEP 13 of DueIt.

STEP 12 is complete.

The previous Firestore authorization bug has been fixed and manually verified.

Current stable state:

- Firebase Authentication
- Business setup
- Customers
- One-time Dues
- Recurring Dues
- Payments
- Partial Payments
- Payment History
- Local Notifications
- Recurring Reminders
- Financial Dashboard
- Offline Firestore persistence
- Connectivity UX
- Hardened Firestore Security Rules
- Production QA completed
- 155 automated tests passing
- flutter analyze = 0 issues
- Debug APK builds successfully

Do NOT modify existing architecture unnecessarily.

==================================================
STEP 13 — WHATSAPP COLLECTION ASSISTANT
==================================================

OBJECTIVE:

Allow a business owner to quickly send a payment reminder to a customer through WhatsApp using a pre-filled message.

IMPORTANT:

This feature must remain completely FREE.

DO NOT implement:

- WhatsApp Business API
- Meta Cloud API
- paid messaging services
- backend message delivery
- automatic WhatsApp sending
- scheduled WhatsApp messages
- WhatsApp authentication
- third-party paid services

Use the device's WhatsApp application through a pre-filled message/deep link.

The owner must always review and manually send the message.

==================================================
1. DUE DETAILS ACTION
==================================================

Add a primary/secondary action to Due Details:

"Remind Customer"

Only show the action when:

- Due is active
- customer exists
- customer has a usable phone number
- remaining amount > 0

For PAID dues:

Do not show "Remind Customer".

For CANCELLED dues:

Do not show "Remind Customer".

==================================================
2. MESSAGE TYPE
==================================================

Automatically determine the default message based on Due status/date.

Possible states:

UPCOMING
DUE TODAY
OVERDUE
PARTIALLY PAID

Do not send reminders for:

PAID
CANCELLED

==================================================
3. MESSAGE GENERATOR
==================================================

Create a pure domain/service class.

Example:

PaymentMessageGenerator

It should receive:

customerName
amount
dueDate
remainingAmount
status
businessName if available

and return a message string.

Keep message generation independent of Flutter widgets.

==================================================
4. UPCOMING MESSAGE
==================================================

Example:

"Hi Rahul, this is a friendly reminder that ₹1,500 is due on August 25. Please let me know once the payment is completed. Thank you."

Use the actual:

customer name
amount
date

Do not hardcode Rahul or ₹1,500.

==================================================
5. DUE TODAY MESSAGE
==================================================

Example:

"Hi Rahul, a quick reminder that ₹1,500 is due today. Please let me know once the payment is completed. Thank you."

Use real data.

==================================================
6. OVERDUE MESSAGE
==================================================

Example:

"Hi Rahul, just a reminder that ₹1,500 is currently overdue. Please make the payment when possible. Thank you."

Use the actual remaining balance, NOT the original amount.

Example:

Original Due = ₹5,000
Paid = ₹2,000
Remaining = ₹3,000

The overdue message must say:

₹3,000

not:

₹5,000.

==================================================
7. PARTIAL PAYMENT MESSAGE
==================================================

If appropriate, allow:

"Hi Rahul, this is a reminder regarding your remaining balance of ₹3,000. Please complete the payment when possible. Thank you."

Again:

Use remaining balance.

==================================================
8. MESSAGE PREVIEW
==================================================

Do NOT immediately launch WhatsApp.

First show a preview bottom sheet/dialog.

Display:

Customer
Phone
Amount
Due date
Generated message

Actions:

[Edit Message]

[Open WhatsApp]

[Cancel]

==================================================
9. EDIT MESSAGE
==================================================

The owner must be able to modify the generated message.

Use a multiline text field.

Validation:

Message cannot be empty.

Do not restrict normal punctuation.

==================================================
10. OPEN WHATSAPP
==================================================

Use the existing URL launcher infrastructure if appropriate.

Generate a WhatsApp-compatible URL with:

customer phone number
URL-encoded message

Preferred behavior:

Open WhatsApp with the message pre-filled.

The owner manually presses Send.

Do NOT send automatically.

==================================================
11. PHONE NUMBER NORMALIZATION
==================================================

Implement a small pure helper:

PhoneNumberNormalizer

The MVP is primarily for India.

However, do not blindly modify numbers.

Handle common Indian formats such as:

9876543210
+919876543210
919876543210

Normalize appropriately for WhatsApp.

If the number cannot safely be normalized:

show:

"Please check this customer's phone number."

Do not create a broken WhatsApp link.

Do not silently guess international country codes for arbitrary foreign numbers.

==================================================
12. NO WHATSAPP INSTALLED
==================================================

If WhatsApp cannot be opened:

show:

"WhatsApp isn't available on this device."

Offer:

[Copy Message]

[Close]

Copying the message must work even without WhatsApp.

==================================================
13. COPY MESSAGE
==================================================

Add:

"Copy Message"

Use Flutter clipboard functionality.

After copying:

"Message copied"

Use a SnackBar or equivalent feedback.

==================================================
14. CUSTOMER DETAILS
==================================================

Add a convenient action:

"Remind"

on Customer Details only when the customer has an active unpaid Due.

If multiple active dues exist:

DO NOT automatically choose one.

Instead show:

"Choose a Due"

and list:

Due amount
Remaining amount
Due date
Status

The owner chooses which Due to remind about.

==================================================
15. DASHBOARD INTEGRATION
==================================================

In the Dashboard:

For:

Needs Attention
Due Today
Overdue

allow navigation to the relevant Due.

Do not introduce WhatsApp buttons everywhere.

Keep the UI clean.

The main WhatsApp action should remain inside Due Details.

==================================================
16. PAYMENT RECEIVED MESSAGE
==================================================

After recording a payment successfully, optionally offer:

"Send Payment Update"

Generate:

"Hi Rahul, we received your payment of ₹500. Your remaining balance is ₹1,000. Thank you."

For fully paid:

"Hi Rahul, we received your payment of ₹1,000. Your balance is now fully settled. Thank you."

IMPORTANT:

Do not automatically send.

Show preview first.

==================================================
17. NO DATABASE REQUIRED
==================================================

Do NOT create a WhatsApp database collection.

Do NOT store generated messages in Firestore.

Messages are generated dynamically.

The user may edit a message before sending.

No additional backend required.

==================================================
18. PRIVACY
==================================================

Do not log:

customer phone numbers
message contents
payment information

in debug logs.

Do not expose customer phone numbers unnecessarily.

==================================================
19. UI DESIGN
==================================================

Follow the existing Google Stitch design system.

Use existing:

colors
typography
buttons
bottom sheets
dialogs
spacing
icons
theme

Do NOT redesign DueIt.

The WhatsApp action should feel like a native part of the existing application.

==================================================
20. ARCHITECTURE
==================================================

Suggested structure:

features/communication/

payment_message_generator.dart
phone_number_normalizer.dart
whatsapp_service.dart

Use existing repository/controller patterns where appropriate.

Keep pure logic testable.

==================================================
21. TESTS
==================================================

Add focused unit tests for:

1. Upcoming message generation
2. Due-today message generation
3. Overdue message generation
4. Partial payment message
5. Fully paid message
6. Remaining amount calculation in messages
7. Phone number normalization
8. Invalid phone number
9. Message URL encoding
10. Empty message validation

Add widget tests for:

1. Remind Customer button
2. Message preview
3. Edit message
4. Copy message
5. Missing phone number
6. Multiple active dues selection

Do NOT test actual WhatsApp delivery in automated tests.

Clearly distinguish:

message generation tested
URL generation tested
physical WhatsApp launch requires device testing

==================================================
22. SECURITY
==================================================

Do not weaken Firestore rules.

Do not expose customer data through new endpoints.

Do not create backend APIs.

Do not add API keys.

==================================================
23. REGRESSION TEST
==================================================

Existing features must continue working:

Customers
Dues
Payments
Recurring Dues
Reminders
Dashboard
Offline mode

==================================================
24. QUALITY GATE
==================================================

Run:

dart format .

flutter analyze

flutter test

flutter build apk --debug

Requirements:

flutter analyze = 0 issues

All tests pass

APK builds successfully

==================================================
25. FINAL REPORT
==================================================

Report:

1. Message generator
2. Message types
3. Phone normalization
4. WhatsApp integration
5. Preview UI
6. Copy fallback
7. Customer Details integration
8. Payment update message
9. Dashboard integration
10. Tests added
11. Total tests
12. flutter analyze
13. APK build
14. Physical WhatsApp testing status
15. Known limitations

IMPORTANT:

Do not claim WhatsApp was physically tested unless an Android device with WhatsApp was actually used.

STOP after STEP 13.