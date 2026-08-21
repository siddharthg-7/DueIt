We are now starting STEP 8 of the DueIt production implementation.

STEP 7 — Payments & Collection — is complete and verified.

Current verified state:

- Authentication works
- Business setup works
- Customer management works
- Firestore ownership/security works
- Due engine works
- Due status calculation works
- Payment recording works
- Partial payments work
- Full payments work
- Payment history works
- Customer financial summary works
- Dashboard financial calculations work
- 75 automated tests pass
- flutter analyze = 0 issues
- Debug APK builds successfully

Now implement:

REMINDERS & LOCAL NOTIFICATIONS

This is one of DueIt's core product features.

==================================================
CORE PURPOSE
==================================================

DueIt exists partly to prevent business owners from forgetting to collect money.

A Due should be able to generate a reminder notification before or on its due date.

Core flow:

Due
→ Reminder configuration
→ Notification scheduled
→ Notification appears
→ User taps notification
→ DueIt opens
→ Due Details

==================================================
IMPORTANT
==================================================

Use LOCAL DEVICE NOTIFICATIONS for this step.

Do NOT implement Firebase Cloud Messaging yet.

Do NOT implement a backend notification scheduler.

Do NOT implement WhatsApp.

Do NOT implement email reminders.

Do NOT implement SMS.

Do NOT implement AI reminders.

Those are future features.

==================================================
PACKAGE
==================================================

Inspect the current Flutter project and add/use:

flutter_local_notifications

Use the current compatible version appropriate for the project's Flutter/Dart version.

Do not blindly copy old API examples.

Verify the current package API from its documentation/changelog if needed.

==================================================
PLATFORM
==================================================

The primary target is Android.

Implement Android notification support properly.

If the project has iOS configuration already, structure the notification service so iOS can be added cleanly later, but do not let iOS-specific work derail the Android MVP.

==================================================
NOTIFICATION SERVICE
==================================================

Create a centralized notification service.

Example responsibility:

LocalNotificationService

It should handle:

initialize()
requestPermissions()
scheduleReminder()
cancelReminder()
cancelRemindersForDue()
cancelAllDueReminders()
getPendingNotifications()

Do not put notification scheduling directly inside Due widgets.

==================================================
NOTIFICATION CHANNEL
==================================================

Create an appropriate Android notification channel for DueIt reminders.

Example conceptual channel:

Payment Reminders

Use an appropriate importance level.

Do not make notifications unnecessarily aggressive.

The purpose is helpful reminders, not alarm behavior.

==================================================
PERMISSIONS
==================================================

Handle Android notification permission correctly for supported Android versions.

Do not assume notification permission is automatically granted.

Ask for permission at an appropriate point.

Do not immediately show a permission prompt before the user understands why notifications are useful.

Prefer:

User creates their first reminder
→ explain reminder benefit
→ request notification permission

If permission is denied:

The Due should still be saved.

Show a useful message explaining that reminders are disabled until notification permission is enabled.

Do not break the Due creation workflow because notification permission was denied.

==================================================
REMINDER MODEL
==================================================

Create a proper reminder configuration model if the current Due architecture does not already contain one.

A Due should conceptually support:

reminderEnabled
reminderType
reminderTime

Reminder types:

NONE
ON_DUE_DATE
ONE_DAY_BEFORE
THREE_DAYS_BEFORE
SEVEN_DAYS_BEFORE
CUSTOM

If the current UI/design supports additional options, preserve them.

Do not create unnecessary complexity.

==================================================
REMINDER DATE CALCULATION
==================================================

Centralize reminder date calculation.

Examples:

Due:
Aug 25

One day before:
Aug 24

Three days before:
Aug 22

Seven days before:
Aug 18

Do not scatter this calculation across widgets.

Use the existing DueIt date-only utilities.

==================================================
TIME OF DAY
==================================================

A reminder needs a notification time.

Use a sensible default according to the existing Stitch design.

If the UI already specifies a reminder time, preserve it.

If not, use a reasonable configurable default such as:

9:00 AM local time.

Do not hardcode the notification time in multiple places.

Create a centralized default.

Allow future customization.

==================================================
SCHEDULE RULE
==================================================

Before scheduling:

Determine:

reminderDateTime

If reminder time is already in the past:

Do NOT schedule a notification in the past.

Handle this gracefully.

For example:

Due today
Reminder = on due date
Current time = 3 PM
Default reminder time = 9 AM

Do not schedule a notification for 9 AM today.

Instead:

Either skip the reminder

or, if the existing UX explicitly supports it, schedule an appropriate next valid reminder.

Do not unexpectedly fire an old reminder immediately.

==================================================
DUE CREATION
==================================================

When a Due is created with a reminder:

1. Save the Due.
2. Determine reminder datetime.
3. Schedule local notification.
4. Store enough reminder metadata to manage the notification later.

Do not schedule the notification before the Due has successfully been saved.

If scheduling fails:

The Due should remain saved.

Show a warning that the reminder could not be scheduled.

Do not roll back a valid Due simply because the local notification failed.

==================================================
NOTIFICATION ID
==================================================

Create a deterministic notification ID for each Due/reminder.

Do not rely on random IDs that cannot later be found.

The ID should allow:

schedule
cancel
reschedule

for the specific Due.

If one Due eventually supports multiple reminders, structure the ID generation so this can be extended.

==================================================
EDIT DUE
==================================================

This is extremely important.

If any reminder-related field changes:

Cancel the existing notification.

Then calculate the new reminder.

Then schedule the new notification.

Example:

Original:

Due Aug 25
Reminder Aug 24

Edit:

Due Aug 28
Reminder one day before

Result:

Old Aug 24 notification must be cancelled.

New Aug 27 notification must be scheduled.

Do not leave stale notifications.

==================================================
STATUS CHANGES
==================================================

When a Due becomes:

PAID

Cancel any pending reminders.

When a Due becomes:

CANCELLED

Cancel any pending reminders.

When a Due becomes:

PARTIALLY_PAID

Keep the reminder active for the remaining balance unless the existing product requirements explicitly say otherwise.

The owner still needs to collect the remaining amount.

==================================================
PAYMENT INTERACTION
==================================================

If:

Due = ₹5,000
Paid = ₹2,000
Remaining = ₹3,000

Reminder should communicate the remaining amount where appropriate.

Example:

"₹3,000 remaining from Rahul Kumar."

Do not show the original ₹5,000 as still fully outstanding.

For PAID:

No future reminder should remain scheduled.

==================================================
NOTIFICATION CONTENT
==================================================

Notification title examples:

"Payment due today"
"Payment due tomorrow"
"Payment overdue"

Notification body should include:

Customer name
Remaining amount
Description

Example:

Payment due tomorrow

Rahul Kumar owes ₹1,500 for August Karate Fee.

Keep notifications concise.

Do not expose unnecessary private information.

==================================================
OVERDUE NOTIFICATIONS
==================================================

Do not implement continuous daily overdue notifications yet.

For this step, only schedule the configured reminder.

The existing Overdue screen can continue to show overdue payments.

Future versions may support recurring overdue reminders.

==================================================
NOTIFICATION TAP
==================================================

When the user taps a DueIt notification:

Open the application.

Navigate to the relevant:

/due/:id

Use the existing GoRouter architecture.

If the Due no longer exists:

Open DueIt safely without crashing.

If the Due is already PAID:

Open the Due Details screen showing PAID status.

Do not open a broken route.

==================================================
APP STATE
==================================================

Notification tap must work when:

1. App is already open
2. App is in background
3. App was previously closed

Use the correct flutter_local_notifications launch/tap handling.

Do not assume one lifecycle state.

==================================================
REMINDER UI
==================================================

Connect the existing Stitch ReminderSelector.

The UI should support:

None
On due date
1 day before
3 days before
7 days before
Custom if already designed

Do not redesign the existing Stitch screen.

Preserve:

- typography
- spacing
- buttons
- selector style
- colors
- hierarchy

==================================================
ADD DUE FLOW
==================================================

The final flow should be:

Add Due

Customer
Amount
Description
Due Date
Reminder

→ Save

Then:

Due saved
+
Reminder scheduled

Show a subtle success confirmation.

Example:

"Due added. Reminder scheduled."

Do not create an intrusive popup.

==================================================
EDIT DUE FLOW
==================================================

When editing:

Due
→ Edit
→ Change reminder
→ Save

Cancel old reminder.

Schedule new reminder.

Show appropriate confirmation.

==================================================
REMINDER SETTINGS
==================================================

If the existing Settings screen has notification/reminder preferences, connect them only if they already exist in the Stitch design.

Do not build a large notification settings system yet.

At minimum allow:

Notifications enabled/disabled

if the current design already contains such a control.

The operating-system permission remains authoritative.

==================================================
PERSISTENCE
==================================================

Reminder configuration should persist with the Due.

Use Firestore for the Due's reminder configuration.

Local scheduled notification state is device-specific.

Do not attempt to store local notification state in Firestore as if it were the notification itself.

The Firestore record describes the desired reminder.

The device notification service schedules the actual notification.

==================================================
MULTI-DEVICE BEHAVIOR
==================================================

Important:

Local notifications are device-local.

If the same account is used on two devices:

Each device may need to schedule reminders independently.

Do not claim server-side synchronization of local notifications.

Structure the code so a future server-driven notification system can replace/augment local notifications.

==================================================
NOTIFICATION FAILURE
==================================================

If local notification scheduling fails:

- Due creation must still succeed.
- Show a warning.
- Log the technical failure for debugging.
- Do not crash.

If permission is denied:

- Save Due.
- Mark reminder as configured in data if appropriate.
- Clearly indicate reminders are currently disabled.

==================================================
TESTING
==================================================

Add tests for:

1. Reminder model serialization
2. Reminder model deserialization
3. Reminder date calculation
4. One-day-before calculation
5. Three-days-before calculation
6. Seven-days-before calculation
7. Due-date reminder calculation
8. Past reminder time handling
9. Notification ID generation
10. Payment status interaction
11. PAID cancels reminder
12. CANCELLED cancels reminder
13. PARTIALLY_PAID keeps reminder
14. Editing due reschedules reminder

Mock the notification service for unit tests.

Do not require actual Android notifications for normal unit tests.

==================================================
MANUAL TEST FLOW
==================================================

TEST 1 — ONE DAY BEFORE

Create:

Rahul
₹1,500
Due Aug 25
Reminder 1 day before

Verify:

Reminder is scheduled for Aug 24 at configured/default time.

TEST 2 — DUE DATE

Create:

Arjun
₹2,000
Due tomorrow
Reminder on due date

Verify:

Correct notification schedule.

TEST 3 — NO REMINDER

Create Due with:

Reminder = None

Verify:

No notification scheduled.

TEST 4 — EDIT

Create:

Due Aug 25
Reminder Aug 24

Edit:

Due Aug 28

Verify:

Old notification cancelled.

New notification scheduled.

TEST 5 — PAID

Create Due with reminder.

Mark fully paid.

Verify:

Pending reminder is cancelled.

TEST 6 — PARTIAL

Create:

₹5,000

Pay:

₹2,000

Verify:

Remaining ₹3,000.

Reminder remains scheduled.

TEST 7 — CANCEL

Create Due with reminder.

Cancel Due.

Verify:

Reminder is cancelled.

TEST 8 — TAP

Trigger a test notification.

Tap it.

Verify:

DueIt opens the correct Due Details screen.

TEST 9 — APP CLOSED

Close the app.

Trigger/test notification.

Tap notification.

Verify:

Application opens and routes safely.

==================================================
ANDROID REQUIREMENTS
==================================================

Verify Android configuration required by flutter_local_notifications.

Handle notification permission correctly for supported Android versions.

Do not blindly add permissions without understanding their purpose.

Ensure scheduled notifications work after app restart.

If exact Android configuration is required, implement it and document it.

==================================================
DO NOT IMPLEMENT
==================================================

Do NOT implement:

Firebase Cloud Messaging
Backend notification scheduler
WhatsApp
Email
SMS
Recurring reminders
Daily overdue reminders
AI-generated reminders
UPI
Payment gateway
SQLite
Offline sync

==================================================
QUALITY GATE
==================================================

Before declaring STEP 8 complete:

Run:

dart format .
flutter analyze
flutter test
flutter build apk --debug

Requirements:

flutter analyze = 0 issues.

All tests pass.

Debug APK builds successfully.

Manually verify notification behavior on an actual Android device if available.

Do not claim scheduled Android notifications work solely because the project compiles.

If physical-device verification is not possible, explicitly state that.

==================================================
FINAL REPORT
==================================================

Report:

1. Notification package/version
2. Notification service
3. Reminder model
4. Reminder scheduling logic
5. Notification ID strategy
6. Add Due integration
7. Edit Due rescheduling
8. Paid cancellation
9. Cancelled cancellation
10. Partial payment behavior
11. Notification tap routing
12. Android permission/configuration
13. Tests
14. APK build
15. Physical-device verification status
16. Known limitations

STOP after STEP 8.