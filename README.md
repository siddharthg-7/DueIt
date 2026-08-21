# DueIt — Financial Collection Assistant

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/State_Management-Riverpod_2.6-blueviolet" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Backend-Firebase_Firestore-FFCA28?logo=firebase&logoColor=black" alt="Firestore" />
  <img src="https://img.shields.io/badge/Auth-Firebase_Auth-FFA000?logo=firebase&logoColor=white" alt="Firebase Auth" />
  <img src="https://img.shields.io/badge/Platform-Android_%7C_iOS-3DDC84?logo=android&logoColor=white" alt="Platform" />
  <img src="https://img.shields.io/badge/Architecture-Clean_%2F_Feature--First-informational" alt="Clean Architecture" />
  <img src="https://img.shields.io/badge/Tests-155_Passing-success" alt="Tests" />
  <img src="https://img.shields.io/badge/License-Proprietary-red" alt="License" />
</p>

---

## Executive Summary

**DueIt** is a production-grade, offline-first mobile financial collection assistant engineered specifically for micro, small, and service-based business owners—such as tuition tutors, karate instructors, fitness trainers, music academies, and independent freelancers.

The platform provides an authoritative ledger answering the fundamental daily financial questions:
* *Who owes money?*
* *How much is outstanding?*
* *When is it due?*
* *What has been collected today?*

Built with Flutter and Google Cloud Firestore, DueIt pairs local device alarms with offline cloud persistence to deliver zero-latency operations even during intermittent network connectivity.

---

## Demo

<!-- DEMO PLACEHOLDER: Add video walk-through or animated GIF demonstrations here -->

<div align="center">
  <p><em>Demonstration assets will be placed here.</em></p>
</div>

---

## Features

### Core Due Ledger
* **Deterministic Status Engine**: Real-time status resolution (`Paid`, `Partially Paid`, `Due Today`, `Upcoming`, `Overdue`, `Cancelled`) with strict precedence hierarchy.
* **Granular Financial Details**: Tracks principle amount, collected balance, remaining balance, due dates, customer references, and transaction notes.
* **Instant Filtering & Search**: Sub-millisecond in-memory filtering across status tabs and customer names with whitespace and case normalization.

### Payment & Collection Tracking
* **Partial & Full Collections**: Accepts split payments over time, recalculating remaining balances automatically.
* **Mathematical Invariant Validation**: Blocks zero, negative, and overpayments with domain validation guards.
* **Immutable Payment History**: Detailed audit trail recording collection timestamp, amount, payment method (Cash, UPI, Bank Transfer, Card), and optional receipt notes.

### Recurring Schedule Automation
* **Multi-Cadence Schedules**: Supports Weekly, Monthly, Quarterly, and Yearly recurring dues.
* **Deterministic Idempotency**: Occurrence generation utilizes composite keys (`due_${scheduleId}_${dueDate}`) preventing duplicate charges across app restarts and network reconnections.
* **Historical Immutability**: Modifying future schedule amounts guarantees existing historical dues remain unmodified.
* **Catch-Up Safety Controls**: Automated loop throttling prevents runaway generation across long periods of inactivity.

### Local Reminders & Alarms
* **Device-Local Scheduling**: Native integration with Android AlarmManager ensuring reminders trigger accurately without cloud scheduling overhead.
* **Lifecycle Awareness**: Automatically cancels active alarms when a Due is marked `Paid` or `Cancelled`, and reschedules upon due date alteration.
* **Deep Linking**: Tapping system notifications routes directly to the specific Due Details screen.
* **Resilient Execution**: Notification permissions or alarm exceptions never block or roll back financial transactions.

### Financial Planning & Analytics Dashboard
* **Dynamic Daily Metrics**: Real-time aggregation of *To Collect Today*, *Collected Today*, *Remaining Today*, *Overdue Total*, and *Upcoming Total*.
* **Monthly Trajectory**: Monthly expected collection forecasts, actual collections, and collection efficiency percentage rates.
* **Visual Collection Trends**: Pure Flutter bar charts mapping 7-day daily collection velocity.
* **Needs Attention Action Center**: Priority alert queue highlighting overdue receivables and scheduled obligations.

### Offline-First Architecture & Resilience
* **Native Firestore Cache**: Cloud Firestore disk persistence configured with unlimited cache bounds.
* **Non-Intrusive UX Indicator**: Subtle connectivity status pill alerting users of offline status and automatic reconnection.
* **Optimistic Local Mutations**: All write operations succeed instantaneously to the local cache and synchronize automatically upon network restoration.

### Multi-Tenant Cloud Security
* **Isolated Subcollections**: Data scoped strictly to `/users/{userId}/*`.
* **Zero Wildcards**: Fine-grained Firestore Security Rules verifying `request.auth.uid == userId` and enforcing immutability of `ownerId` and `businessId`.
* **Session Cleansing**: Absolute memory cleanup across user logouts preventing cross-tenant data leaks.

---

## Technology Stack

<table width="100%">
  <tr>
    <td width="30%"><strong>Layer</strong></td>
    <td width="70%"><strong>Technology</strong></td>
  </tr>
  <tr>
    <td><strong>Client Framework</strong></td>
    <td>Flutter 3.24+ (Dart 3.5+)</td>
  </tr>
  <tr>
    <td><strong>State Management</strong></td>
    <td>Flutter Riverpod 2.6 (StateNotifier, Streams, Providers)</td>
  </tr>
  <tr>
    <td><strong>Routing & Navigation</strong></td>
    <td>GoRouter 14.8 (Declarative, StatefulShellRoute)</td>
  </tr>
  <tr>
    <td><strong>Authentication</strong></td>
    <td>Firebase Authentication (Email / Password)</td>
  </tr>
  <tr>
    <td><strong>Cloud Database</strong></td>
    <td>Cloud Firestore (Persistent Offline Cache, Subcollections)</td>
  </tr>
  <tr>
    <td><strong>Notifications</strong></td>
    <td>flutter_local_notifications 18.0, timezone 0.10</td>
  </tr>
  <tr>
    <td><strong>Connectivity</strong></td>
    <td>connectivity_plus 7.3</td>
  </tr>
  <tr>
    <td><strong>Design System</strong></td>
    <td>Material 3 Custom Tokens (Outfit, Roboto Google Fonts)</td>
  </tr>
  <tr>
    <td><strong>Quality & Testing</strong></td>
    <td>flutter_test, flutter_lints, Custom Mock Harnesses</td>
  </tr>
</table>

---

## Screenshots

<!-- SCREENSHOTS PLACEHOLDER: Add UI screen captures below -->

| Authentication & Setup | Dashboard & Metrics | Dues & Collection |
| :---: | :---: | :---: |
| *(Image Placeholder)* | *(Image Placeholder)* | *(Image Placeholder)* |

| Payment Receipt | Recurring Schedules | Customer Management |
| :---: | :---: | :---: |
| *(Image Placeholder)* | *(Image Placeholder)* | *(Image Placeholder)* |

---

## Project Structure

```
flutter_dueit/
├── android/                        # Native Android Gradle configuration & Manifest
├── assets/                         # Vector icons, branding graphics, assets
├── lib/
│   ├── app.dart                    # MaterialApp & theme configuration
│   ├── main.dart                   # Entry point & Firestore persistence initialization
│   ├── core/
│   │   ├── constants/              # Application constants & limits
│   │   ├── routing/                # GoRouter declarations & route paths
│   │   ├── services/               # Connectivity & device-level services
│   │   ├── theme/                  # Color tokens, typography & component themes
│   │   └── utils/                  # Currency, date, and math formatters
│   ├── features/
│   │   ├── auth/                   # Authentication domain, data & presentation
│   │   ├── customers/              # Customer management & client profiles
│   │   ├── dashboard/              # Financial aggregation services & metrics UI
│   │   ├── dues/                   # Core Due engine, payments & recurring schedules
│   │   ├── reminders/              # Local notification scheduling & date math
│   │   └── settings/               # Profile management & application settings
│   └── shared/                     # Reusable widgets (cards, summary pills, banners)
└── test/
    ├── audit/                      # Production QA & multi-tenant security test suites
    ├── features/                   # Feature unit and integration tests
    ├── mocks/                      # In-memory test repositories & fake services
    └── security/                   # Hardened Firestore rules logic tests
```

---

## Installation

### Prerequisites
* Flutter SDK (`>= 3.24.0`)
* Dart SDK (`>= 3.5.0`)
* Android Studio / Xcode (for mobile emulators or physical device deployment)
* Java JDK 17+
* Firebase CLI (`npm install -g firebase-tools`)

### Clone Repository
```bash
git clone https://github.com/siddharthg-7/DueIt.git
cd DueIt/flutter_dueit
```

### Install Dependencies
```bash
flutter pub get
```

---

## Environment Variables & Configuration

DueIt utilizes standard Firebase project initialization.

1. **Android Configuration**:
   Ensure `google-services.json` is located in `flutter_dueit/android/app/google-services.json`.
2. **FlutterFire Options**:
   Ensure `lib/firebase_options.dart` is present and populated with your Firebase project credentials.
3. **Firestore Security Rules**:
   Deploy the security rules from the repository root:
   ```bash
   firebase deploy --only firestore:rules
   ```

---

## Run Locally

### Start Development Server / Emulator
```bash
# Verify attached devices
flutter devices

# Run in debug mode
flutter run
```

### Run on Specific Target
```bash
# Run on Android emulator or connected device
flutter run -d android

# Run on iOS simulator
flutter run -d ios
```

---

## Deployment

### Android Production Build

1. **Generate Signing Keystore**:
   Configure your `key.properties` and keystore file inside `android/`.
2. **Build Debug APK**:
   ```bash
   flutter build apk --debug
   ```
3. **Build Release APK**:
   ```bash
   flutter build apk --release
   ```
4. **Build Android App Bundle (Google Play)**:
   ```bash
   flutter build appbundle --release
   ```
   Artifact output: `build/app/outputs/bundle/release/app-release.aab`

---

## API & Firestore Data Schema Reference

All data resides within authenticated user subcollections ensuring absolute tenant boundary isolation.

### `users/{userId}`
```typescript
interface UserProfile {
  id: string;                 // Matches request.auth.uid
  email: string;
  businessName: string;
  businessType: string;
  ownerName: string;
  phone?: string;
  upiId?: string;
  isSetupComplete: boolean;
  createdAt: timestamp;
  updatedAt: timestamp;
}
```

### `users/{userId}/customers/{customerId}`
```typescript
interface CustomerDocument {
  id: string;
  ownerId: string;            // Immutable (matches request.auth.uid)
  businessId: string;         // Immutable
  name: string;
  phone?: string;
  email?: string;
  notes?: string;
  createdAt: timestamp;
  updatedAt: timestamp;
}
```

### `users/{userId}/dues/{dueId}`
```typescript
interface DueDocument {
  id: string;
  ownerId: string;            // Immutable
  businessId: string;         // Immutable
  customerId: string;
  customerName: string;
  amount: number;
  paidAmount: number;
  description: string;
  dueDate: string;            // ISO Date: 'YYYY-MM-DD'
  status: string;             // 'due' | 'upcoming' | 'overdue' | 'partiallyPaid' | 'paid' | 'cancelled'
  reminderType: string;       // 'none' | 'morningOf' | 'oneDayBefore' | 'threeDaysBefore' | 'custom'
  reminderEnabled: boolean;
  recurrence: string;         // 'none' | 'weekly' | 'monthly' | 'quarterly' | 'yearly'
  recurringScheduleId?: string;
  occurrenceDate?: string;    // ISO Date: 'YYYY-MM-DD'
  createdAt: timestamp;
  updatedAt: timestamp;
}
```

### `users/{userId}/payments/{paymentId}`
```typescript
interface PaymentDocument {
  id: string;
  ownerId: string;            // Immutable
  businessId: string;         // Immutable
  dueId: string;
  customerId: string;
  amount: number;
  paymentMethod: string;      // 'cash' | 'upi' | 'bankTransfer' | 'card' | 'other'
  paidAt: string;             // ISO Date: 'YYYY-MM-DD'
  notes?: string;
  createdAt: timestamp;
}
```

### `users/{userId}/recurring_due_schedules/{scheduleId}`
```typescript
interface RecurringScheduleDocument {
  id: string;
  ownerId: string;            // Immutable
  businessId: string;         // Immutable
  customerId: string;
  customerName: string;
  amount: number;
  description: string;
  frequency: string;          // 'monthly' | 'quarterly' | 'yearly' | 'weekly'
  dayOfMonth: number;         // 1-31
  dayOfWeek?: number;         // 1-7 (Monday = 1)
  startDate: string;          // ISO Date: 'YYYY-MM-DD'
  endDate?: string;           // ISO Date: 'YYYY-MM-DD'
  status: string;             // 'active' | 'paused' | 'ended'
  nextDueDate: string;        // ISO Date: 'YYYY-MM-DD'
  reminderType: string;
  reminderEnabled: boolean;
  createdAt: timestamp;
  updatedAt: timestamp;
}
```

---

## Usage & Implementation Examples

### Recording a Payment
```dart
final duesController = ref.read(duesControllerProvider.notifier);

final paymentRecord = await duesController.recordPayment(
  dueId: 'due_12345',
  amount: 1500.0,
  paymentMethod: PaymentMethod.upi,
  notes: 'Collected via UPI reference #98124',
);

if (paymentRecord != null) {
  // Balance recalculated, status transitioned, and reminder updated automatically
}
```

### Pure Domain Financial Calculation
```dart
final metrics = DashboardFinancialCalculator.calculate(
  dues: duesList,
  payments: paymentsList,
  referenceDate: DateTime.now(),
);

print('To Collect Today: ₹${metrics.toCollectToday}');
print('Collected Today: ₹${metrics.collectedToday}');
print('Collection Rate: ${metrics.collectionRate}%');
```

---

## Quality Assurance & Verification

The project includes an automated test harness covering pure domain math, Riverpod controllers, widget flows, security rules, and offline reliability.

```bash
# Execute static analysis
flutter analyze

# Run all 155 automated tests
flutter test

# Format all project files
dart format .
```

---

## Roadmap

* **WhatsApp Statement Generation**: One-tap payment reminder generator formatting personalized WhatsApp messages with balance breakdowns.
* **Direct UPI Deep Linking**: Dynamic UPI Intent URI generation allowing customers to initiate payments via GPay, PhonePe, or Paytm.
* **Export & Reporting**: PDF collection statements and CSV financial exports for local accounting.
* **Customer Portal**: Lightweight read-only web view for clients to view payment ledgers and download digital receipts.
* **Cloud Notification Sync**: Background push notifications triggered via Cloud Functions to complement local device alarms.

---

## Optimizations

* **Zero-Cost Firestore Queries**: Subcollection data partitioning ensures business queries execute against indexed subsets, maintaining read operations well within free tier limits.
* **Deterministic 31-bit Hashing**: Notification ID generation employs FNV-1a integer hashing bounded by `0x7FFFFFFF`, guaranteeing stable ID reconstruction without storing random ID maps.
* **Disposed Stream Subscriptions**: StateNotifier lifecycle bindings automatically cancel active Firestore listeners upon signout, preventing memory retention.
* **In-Memory Filtering**: Tab switching and customer searches operate on cached domain collections, eliminating redundant network queries.

---

## Lessons Learned

* **Single Source of Truth**: Utilizing Cloud Firestore native persistence on Android eliminates the schema synchronization complexity and race conditions inherent in dual SQLite + Cloud database architectures.
* **Decoupled System Alarms**: Isolating system alarm exceptions from transaction operations ensures transient permission errors never corrupt financial writes.
* **Deterministic Occurrence Generation**: Deriving recurring entity identifiers from `${scheduleId}_${dueDate}` guarantees total idempotency across reconnections and catch-up evaluations.

---

## Authors

* **Siddharth G** — *Lead Developer & Architect* — [@siddharthg-7](https://github.com/siddharthg-7)

---

## Feedback

Contributions, feedback, and issue reports are welcome:
* **Issue Tracker**: [GitHub Issues](https://github.com/siddharthg-7/DueIt/issues)
* **Discussions**: [GitHub Discussions](https://github.com/siddharthg-7/DueIt/discussions)

---

## Support

For commercial inquiries, customization, or technical support, please file an issue on GitHub or reach out via project communication channels.
