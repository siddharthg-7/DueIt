We are now starting STEP 3 of the DueIt production implementation.

The Flutter foundation has already been created and verified.

Now focus ONLY on implementing the DueIt visual design system and application navigation.

DO NOT implement Firebase authentication yet.
DO NOT implement Firestore yet.
DO NOT implement notifications yet.
DO NOT implement customer CRUD yet.
DO NOT implement payment business logic yet.
DO NOT implement recurring payment logic yet.

This step is ONLY:

1. Stitch design system
2. Flutter theme
3. Reusable UI components
4. Application shell
5. Navigation
6. Static screen layouts
7. Responsive mobile behavior

==================================================
SOURCE OF TRUTH
==================================================

The original Google Stitch designs are the visual source of truth.

The Google AI Studio TypeScript prototype is NOT the visual source of truth.

If the AI Studio implementation differs from Stitch, follow Stitch.

Do not invent a new design.

==================================================
DUEIT DESIGN PRINCIPLES
==================================================

DueIt should feel:

- Professional
- Simple
- Trustworthy
- Calm
- Modern
- Friendly
- Financial but not like complicated accounting software
- Easy for a non-technical small business owner
- Fast and action-oriented

The most important information in the app is:

"How much money do I need to collect today?"

The interface should prioritize clarity over information density.

==================================================
SCREENS TO IMPLEMENT
==================================================

Implement the static Flutter UI for the following screens based on the Stitch designs:

1. Splash
2. Welcome / onboarding
3. Login
4. Business setup
5. Home dashboard
6. Add Due
7. Due details
8. People
9. Person details
10. All dues
11. Notifications
12. Insights
13. Settings if present in the Stitch design

Use realistic static/mock data only for visual rendering.

Do not implement persistence yet.

==================================================
HOME SCREEN
==================================================

The Home screen is the most important screen.

Its visual hierarchy should communicate:

Today's Collection

₹8,500

5 payments

Then:

Overdue
₹4,000

Then:

Upcoming
₹18,500

Then:

Monthly summary

Use the exact visual hierarchy from Stitch.

Do not redesign the screen.

Do not make charts more prominent than today's collection.

==================================================
ADD DUE SCREEN
==================================================

The Add Due screen should visually support:

Customer/person
Amount
Description/reason
Due date
Reminder
Recurrence

Example:

Who?
Rahul Kumar

Amount
₹1,500

For
August Karate Fee

Due date
25 Aug 2026

Reminder
1 day before

Repeat
Monthly

Create Due

These are currently visual/static controls only.

Production functionality will be added later.

==================================================
DUE STATUS COMPONENTS
==================================================

Implement reusable status components for:

UPCOMING
DUE
OVERDUE
PARTIALLY_PAID
PAID
CANCELLED

Follow the Stitch visual language.

Do not use excessive colors.

Status colors should be accessible and consistent.

==================================================
REUSABLE COMPONENTS
==================================================

Create reusable Flutter widgets where appropriate.

Examples:

DueCard
CustomerCard
CollectionSummaryCard
AmountDisplay
StatusBadge
PrimaryButton
SecondaryButton
AppTextField
DateSelector
ReminderSelector
RecurrenceSelector
SectionHeader
EmptyState
SearchField
BottomNavigation
AppBar

Do not duplicate visually identical components.

If an existing reusable component already exists from STEP 2, improve/reuse it instead of creating a duplicate.

==================================================
TYPOGRAPHY
==================================================

Implement the typography hierarchy from Stitch.

Pay particular attention to:

- Currency amounts
- Page titles
- Section headings
- Due dates
- Customer names
- Status labels
- Button labels
- Secondary information

Currency values should have strong visual hierarchy.

For example:

₹8,500

should immediately communicate more importance than:

To collect today

while still following the exact Stitch design.

==================================================
SPACING AND SHAPES
==================================================

Use consistent design tokens for:

- spacing
- corner radius
- elevation
- borders
- icon sizes
- touch targets

Do not hardcode random values repeatedly throughout widgets.

Create centralized theme/design constants where appropriate.

==================================================
NAVIGATION
==================================================

Implement the application navigation structure.

Primary navigation:

Home
Dues
People
Insights

Settings should be accessible through the appropriate secondary navigation location according to the Stitch design.

Implement routes using GoRouter.

The navigation should work between the static screens.

Example:

Home
→ Add Due
→ Due Details

Home
→ People
→ Person Details

Home
→ Notifications

Home
→ Insights

Dues
→ Due Details

People
→ Person Details

==================================================
BOTTOM NAVIGATION
==================================================

Use the exact Stitch bottom navigation design.

Do not add unnecessary navigation items.

The navigation should:

- preserve selected state
- animate only if consistent with the Stitch design
- maintain navigation state appropriately
- work correctly with GoRouter

==================================================
MOCK DATA
==================================================

Use realistic mock data for visual rendering.

Example customers:

Rahul Kumar
Arjun Sharma
Sneha Reddy
Vikram Rao

Example dues:

Rahul Kumar
₹1,500
August Karate Fee
Due Today

Arjun Sharma
₹2,000
Monthly Membership
Due Today

Sneha Reddy
₹1,500
August Tuition
Paid

Vikram Rao
₹2,500
Monthly Training
Overdue

Do not store this as production data.

This is only for visual development.

==================================================
EMPTY STATES
==================================================

Create appropriate empty states for:

No customers
No dues
No payments today
No upcoming payments
No overdue payments
No notifications

Follow the Stitch design language.

==================================================
MOBILE REQUIREMENTS
==================================================

This is a mobile application.

Prioritize:

- one-handed use
- comfortable touch targets
- safe areas
- keyboard behavior
- scrolling
- small Android screens
- different Android screen sizes

Avoid horizontal overflow.

Do not design for desktop.

==================================================
ACCESSIBILITY
==================================================

Ensure:

- sufficient contrast
- readable text
- accessible touch targets
- meaningful semantic labels
- icons are not the only indication of meaning
- status information is also communicated through text

==================================================
QUALITY CHECK
==================================================

After implementation:

1. Run dart format.
2. Run flutter analyze.
3. Run available tests.
4. Build/run the application.
5. Check every implemented screen.
6. Check navigation.
7. Check for overflow.
8. Check keyboard/input layouts.
9. Check bottom navigation.
10. Check small-screen behavior.

Fix all compilation errors and obvious UI issues.

==================================================
IMPORTANT RESTRICTION
==================================================

Do not implement backend functionality in this step.

Do not implement:

Firebase Auth
Firestore
FCM
SQLite persistence
Local notifications
Recurring-payment calculations
Payment calculations
Customer CRUD
Production data repositories

Only build the visual system and navigation.

When finished, provide a concise report containing:

1. Screens implemented
2. Components created/reused
3. Routes created
4. Design-system changes
5. Validation performed
6. Any remaining visual differences from Stitch
7. Any issues that need attention before moving to authentication

Keep the application in a working state.