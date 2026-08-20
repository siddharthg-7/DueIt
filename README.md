# DueIt - Financial Collection Assistant  ( Mobile App ) 

**DueIt** is a mobile financial collection assistant for small business owners. Its core purpose is: *"Know what you're owed. Know when to collect. Never miss a payment."*

Target users include Karate instructors, Gym owners, Tuition teachers, Dance instructors, and Freelance coaches.

## Architecture

This project is built natively for mobile devices using **Flutter** and **Dart**, leveraging a clean feature-based architecture.

### Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod 2 (with `flutter_riverpod`)
- **Routing**: GoRouter (with `StatefulShellRoute` for bottom navigation)
- **Design System**: Material 3 (customized to match Google Stitch high-fidelity tokens)

## Project Structure

The Flutter mobile application is located in the `flutter_dueit` directory.

```
flutter_dueit/
├── lib/
│   ├── app.dart                   # Root MaterialApp configuration
│   ├── main.dart                  # Application entry point
│   ├── core/                      # Routing, Themes, Constants, Utils
│   ├── features/                  # Feature modules (Auth, Dashboard, Customers, Dues, Insights, Reminders, Settings)
│   └── shared/                    # Reusable UI components (Cards, Badges, Buttons)
```

## Setup & Running

1. Ensure you have the Flutter SDK installed (`flutter --version`).
2. Navigate to the Flutter project directory:
   ```bash
   cd flutter_dueit
   ```
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application (requires a connected device or emulator):
   ```bash
   flutter run
   ```

## Features
- **Dashboard**: Real-time overview of collections, expected revenue, and upcoming dues.
- **Client Management**: Track customer profiles, batch assignments, and payment histories.
- **Due Tracking**: Log new dues, set recurrences (Weekly/Monthly/Yearly), and monitor payment status.
- **Payment Ledger**: Record partial or full payments and generate shareable digital receipts.
- **Automated Reminders**: Built-in 1-tap WhatsApp statement and reminder generators.
- **Insights**: Collection efficiency metrics and batch-wise performance breakdown.

## Design System
DueIt uses a strict, custom design system adapted from Google Stitch:
- **Primary Color**: Deep Teal (`#00685F`)
- **Typography**: Inter (Google Fonts)
- **Components**: High-fidelity custom cards, bottom navigation, and action buttons ensuring a premium mobile experience.
