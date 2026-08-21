We are now starting STEP 4 of the DueIt production implementation.

STEP 3 is complete and verified.

The Flutter visual design system, reusable components, application shell, routes, static screens, tests, analysis, and debug APK are already working.

Now implement:

AUTHENTICATION + BUSINESS SETUP

Do not implement customers, dues, payments, reminders, recurring payments, or insights yet.

==================================================
STEP 4 OBJECTIVE
==================================================

Turn the existing static authentication flow into a real Firebase Authentication flow while preserving the existing Stitch-based UI exactly.

The production flow should be:

Splash
→ Check authentication state
→ Welcome
→ Login / Create Account
→ Business Setup
→ Home

For returning users:

Splash
→ Check authentication state
→ Check business profile
→ Home OR Business Setup

==================================================
AUTHENTICATION
==================================================

Use:

Firebase Authentication
Email + Password

Do not add:

- Google Sign-In
- Phone OTP
- Apple Sign-In
- Facebook
- Anonymous authentication

Those are not part of the current MVP.

==================================================
FIREBASE SETUP
==================================================

Inspect the existing Flutter project first.

Determine whether Firebase has already been configured.

If Firebase is NOT configured:

Set up the project using the standard FlutterFire workflow.

Use:

firebase_core
firebase_auth

Do not manually hardcode Firebase configuration values.

Do not expose private credentials or secrets.

Do not create a custom backend authentication system.

Use the existing Firebase project if the project configuration is already present.

If Firebase configuration requires a manual Firebase Console action, clearly tell me exactly what I need to enable/configure rather than inventing credentials.

==================================================
REGISTRATION
==================================================

Implement a real account creation flow.

Required:

Email
Password
Confirm Password

Validation:

- email cannot be empty
- email must be valid
- password cannot be empty
- password must satisfy Firebase password requirements
- confirmation must match password

Use Firebase:

createUserWithEmailAndPassword()

After successful registration:

1. User becomes authenticated.
2. Continue to Business Setup.
3. Do not send the user directly to Home unless a business profile already exists.

Handle Firebase authentication errors gracefully.

Do not expose raw technical Firebase error messages directly to users.

Convert common errors into understandable messages.

Examples:

"An account with this email already exists."
"Please enter a valid email address."
"Your password is too weak."
"Unable to create your account. Please try again."

==================================================
LOGIN
==================================================

Implement:

Email
Password

Use:

signInWithEmailAndPassword()

Handle common failure cases.

Do not reveal unnecessary information that could help enumerate accounts.

Show friendly errors such as:

"Email or password is incorrect."

Include the existing Stitch-designed:

Forgot Password

flow.

==================================================
PASSWORD RESET
==================================================

Implement password reset using Firebase Authentication.

Use:

sendPasswordResetEmail()

Flow:

Forgot Password
→ Enter Email
→ Send Reset Email
→ Success state

Success message:

"If an account exists for this email, we've sent instructions to reset your password."

Do not expose unnecessary account-existence information.

==================================================
LOGOUT
==================================================

Implement logout using Firebase Authentication.

Use:

FirebaseAuth.instance.signOut()

After logout:

→ authentication state changes
→ user returns to the appropriate unauthenticated screen

Do not simply navigate to Login without actually signing out.

==================================================
AUTH STATE
==================================================

Create a proper authentication state layer.

Use Riverpod consistently with the existing architecture.

The application must react to:

authenticated
unauthenticated
loading

Do not manually scatter authentication checks across every screen.

Create a centralized authentication state/provider/service.

The application should listen to Firebase authentication state changes.

Do not rely only on checking auth once during app startup.

==================================================
ROUTING
==================================================

Use the existing GoRouter architecture.

Implement proper route protection.

Unauthenticated user:

Cannot access:

/dashboard
/dues
/customers
/insights
/settings
/customer/:id
/due/:id
/add-due

Authenticated user:

Can access the main application.

Do not allow authenticated users to unnecessarily return to Login through normal back navigation.

Handle redirects centrally through the routing/auth architecture.

Do not create redirect loops.

==================================================
SPLASH
==================================================

Use the existing Stitch Splash screen.

The splash screen should:

1. Initialize required Firebase state.
2. Determine authentication state.
3. Determine whether the user has completed Business Setup.
4. Navigate appropriately.

Do not use arbitrary delays just to make the splash screen visible.

Do not use:

Future.delayed()

as a substitute for real initialization.

==================================================
BUSINESS SETUP
==================================================

After a new user successfully registers, show Business Setup.

The purpose is to collect minimal information about the business.

Required:

Business name

Optional:

Business type/category

Examples:

Karate Academy
Fitness Studio
Tuition Center
Dance Academy
Freelance Services
Other

Do not ask unnecessary questions.

The setup should be fast.

==================================================
BUSINESS PROFILE
==================================================

For now, conceptually store:

BusinessProfile

Fields:

id
ownerId
businessName
businessType
createdAt
updatedAt

The ownerId must correspond to the Firebase authenticated user's UID.

Do not associate business data using email addresses.

Use Firebase UID as the identity key.

==================================================
BUSINESS PROFILE STORAGE
==================================================

Use Cloud Firestore for the production business profile.

Recommended conceptual structure:

users/{uid}

or an equivalent secure structure that works cleanly with the future DueIt data model.

Before implementing the collection structure, inspect the existing architecture and choose a structure that will scale cleanly to:

customers
dues
payments
reminders
business settings

Do not create a complicated multi-tenant architecture yet.

One authenticated account should own one DueIt business in the MVP.

==================================================
SECURITY
==================================================

Do not leave Firestore open to everyone.

Create security rules so that an authenticated user can only access their own business data.

Do not use:

allow read, write: if true;

Do not create insecure test rules.

The authenticated Firebase UID must be used to determine ownership.

If rules require Firebase Console deployment/configuration, explain what needs to be done.

==================================================
BUSINESS SETUP BEHAVIOR
==================================================

After registration:

User
→ Business Setup
→ Enter Business Name
→ Select optional business type
→ Save
→ Business profile created
→ Navigate Home

After successful setup:

The Home screen should display the business context appropriately if the Stitch design includes it.

Do not redesign the Home screen.

==================================================
RETURNING USERS
==================================================

When the app is reopened:

If authenticated AND business profile exists:

→ Home

If authenticated BUT business profile does not exist:

→ Business Setup

If unauthenticated:

→ Welcome/Login

Do not force a logged-in user through Business Setup every time.

==================================================
ERROR HANDLING
==================================================

Handle:

- no internet connection
- Firebase unavailable
- invalid credentials
- weak password
- duplicate email
- password mismatch
- empty fields
- invalid email
- Firestore failure
- timeout

Use friendly UI states.

Do not crash.

Do not expose stack traces to the user.

==================================================
LOADING STATES
==================================================

Every asynchronous authentication/business operation must have a proper loading state.

Examples:

Signing in...
Creating account...
Saving business...

Prevent duplicate submissions while an operation is running.

Disable the primary button while submitting.

==================================================
DESIGN REQUIREMENT
==================================================

DO NOT redesign the existing Stitch screens.

Preserve:

- colors
- typography
- spacing
- button styles
- input styles
- cards
- navigation
- illustrations
- hierarchy
- animations if already present

Only add the necessary states:

- loading
- validation error
- Firebase error
- success

These states should use the existing DueIt design system.

==================================================
ARCHITECTURE
==================================================

Follow the existing feature-based Flutter architecture.

Authentication should have appropriate separation between:

- data/service layer
- authentication state
- repository/service where appropriate
- presentation
- routing

Do not put Firebase calls directly into UI widgets.

Do not put business setup Firestore calls directly into widgets.

Keep widgets focused on presentation and user interaction.

==================================================
TESTING
==================================================

Add/update tests where practical.

At minimum verify:

1. Unauthenticated state routes to authentication.
2. Authenticated state is recognized.
3. Registration validation works.
4. Password confirmation validation works.
5. Login validation works.
6. Password reset validation works.
7. Business setup validation works.
8. Logout clears authentication state.
9. Authenticated users cannot access unauthenticated-only screens.
10. Unauthenticated users cannot access protected application screens.

Do not write tests that depend on real production Firebase credentials unless the project already has an appropriate test setup.

Use mocks/fakes for unit-level tests where appropriate.

==================================================
MANUAL VERIFICATION
==================================================

After implementation:

Run:

dart format .
flutter analyze
flutter test
flutter build apk --debug

Also run the application and manually verify:

TEST A — NEW USER

Welcome
→ Create Account
→ Email
→ Password
→ Confirm Password
→ Register
→ Business Setup
→ Enter Business Name
→ Save
→ Home

TEST B — EXISTING USER

Login
→ Email
→ Password
→ Home

TEST C — INVALID LOGIN

Wrong credentials
→ Friendly error
→ Remains on Login

TEST D — PASSWORD RESET

Forgot Password
→ Email
→ Submit
→ Success state

TEST E — LOGOUT

Home
→ Settings
→ Logout
→ Authentication screen

TEST F — APP RESTART

Authenticated user closes/reopens app
→ Should remain authenticated
→ Should return to Home if business setup is complete

TEST G — AUTH GUARD

Attempt to access protected routes while logged out
→ Should redirect to authentication

==================================================
DO NOT IMPLEMENT YET
==================================================

Do NOT implement:

Customers
Dues
Payments
Payment history
Recurring payments
Reminders
Notifications
Insights logic
SQLite
Offline synchronization
FCM
WhatsApp
UPI
AI features

Those belong to later implementation stages.

==================================================
FINAL VALIDATION
==================================================

Before declaring STEP 4 complete:

- flutter analyze must have 0 issues
- tests must pass
- debug APK must build successfully
- authentication must be real Firebase Authentication
- business setup must persist correctly
- protected routes must work
- logout must work
- app restart/auth persistence must work
- no existing Stitch visual design should be unnecessarily changed

When finished, report:

1. Files created/changed
2. Firebase packages added
3. Firebase configuration status
4. Authentication flow implemented
5. Business profile implementation
6. Firestore structure chosen
7. Security rules created/changed
8. Routes/auth guards implemented
9. Tests performed
10. Build result
11. Any Firebase Console actions I still need to perform manually

Do not proceed to customer management after completing this step.

Stop after STEP 4 and report the results.