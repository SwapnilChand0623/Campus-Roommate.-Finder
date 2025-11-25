# Campus Roommate Finder

A mobile app built with **Flutter**, **Riverpod**, and **Supabase** to help university students discover compatible roommates, chat in real time, and trade essentials via a simple marketplace.

---

## ✨ Features

- **Onboarding & University Selection**  
  Select your university (validated by email domain) and complete a detailed roommate profile.

- **Compatibility-Based Matching**  
  - Uses profile data (interests, lifestyle, gender preferences, distance, housing) to compute a match score.  
  - Ranked feed shows best matches first.

- **Filters & Favorites**  
  - Refine matches using filters (distance, housing, preferences, etc.).  
  - Save favorite profiles for quick access.

- **Real-Time Chat**  
  - 1:1 messaging between matched users.  
  - Conversations list and message history.  
  - Supabase real-time + local notifications (new match, new message).

- **Marketplace**  
  - Create listings with photos, price, and details.  
  - Browse categories (e.g. furniture, textbooks, appliances).  
  - Message the seller directly from a listing.  
  - Sellers can edit, mark as sold, or delete listings.

---

## 🧱 Tech Stack

**Frontend**
- Flutter 3.x (Dart)
- Material 3 design
- Riverpod for state management

**Backend**
- Supabase (PostgreSQL + Auth + Storage + Realtime)
- Row Level Security (RLS) for data protection

**Key Packages** (high level)
- `supabase_flutter` – backend integration
- `flutter_riverpod` – state management
- `flutter_local_notifications` – local notifications
- `cached_network_image`, `image_picker` – media handling

---

## 🚀 Getting Started

### 1. Prerequisites

- Flutter SDK installed
- Dart SDK (included with Flutter)
- Android Studio or Xcode (for device/emulator)
- Supabase project (URL + anon/public key)

### 2. Clone the Repository

```bash
git clone https://github.com/SwapnilChand0623/Campus-Roommate.-Finder.git
cd Campus-Roommate.-Finder  # or campus_roommate_finder depending on folder name
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Configure Supabase

Create a config file (for example `lib/config/supabase_config.dart`) and ensure it is imported where Supabase is initialized:

```dart
class SupabaseConfig {
  static const String url = '<YOUR_SUPABASE_URL>';
  static const String anonKey = '<YOUR_SUPABASE_ANON_KEY>';
}
```

Do **not** commit real keys to a public repo.

### 5. Database & Storage

- Run the provided SQL migrations (users/messages/favorites/listings, RLS, storage) in the Supabase SQL editor.
- Ensure storage buckets for **profile photos** and **listings** are created and policies applied.

> See `TECHNICAL_DOCUMENTATION.md` for more detail on schema and policies.

### 6. Run the App (Debug)

```bash
flutter run
```

Choose a device (Android / iOS simulator or physical device).

---

## 📦 Building a Release APK (Android)

From the project root:

```bash
flutter build apk --release
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

You can then:
- Copy the APK to a device (USB, AirDrop, cloud).
- Enable installation from unknown sources on the device.
- Install and test.

For more detail, see `APK_DISTRIBUTION_GUIDE.md`.

---

## 🧪 High-Level Architecture

- **Screens (UI)** – Flutter widgets for onboarding, match feed, filters, chat, marketplace, profile, etc.
- **Providers (Riverpod)** – Expose app state and async data to the UI.
- **Services** – Encapsulate business logic and Supabase operations:
  - `DatabaseService` – users, messages, favorites
  - `MatchingService` – compatibility scoring and ranked matches
  - `ListingService` – marketplace CRUD & photo upload
  - `NotificationService` – local notifications & realtime listeners

Data flows roughly as:

```text
UI (Screens)
  ↓
State (Riverpod Providers)
  ↓
Services (business logic)
  ↓
Supabase (Auth, DB, Storage, Realtime)
```

More detail is available in `TECHNICAL_DOCUMENTATION.md`.

---

## 🔐 Security & Privacy

- Supabase Row Level Security (RLS) used on core tables.  
- Users can only access their own sensitive data and conversations.  
- Storage policies restrict who can upload/delete images.

If making the project public, ensure:
- No secrets (Supabase keys, etc.) are committed.  
- You provide a basic privacy policy if sharing with real users.

---

## 📝 License

Specify your license of choice here (e.g. MIT, Apache-2.0, or "All rights reserved").

---

## 🙋‍♂️ Contact

For questions, feedback, or collaboration:
- GitHub: [@SwapnilChand0623](https://github.com/SwapnilChand0623)
