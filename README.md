# Bhawuk's Kharcha 🔥 💸

[![Release APK](https://github.com/geeky-bhawuk-arora/pocketLedger/actions/workflows/release_apk.yml/badge.svg)](https://github.com/geeky-bhawuk-arora/pocketLedger/actions/workflows/release_apk.yml)

**Oye! Paise da hisaab, Bhawuk da style!**

Bhawuk's Kharcha isn't just another boring expense tracker. It’s a premium, energetic, and slightly cheeky fintech app designed to keep your wallet in check with a touch of Punjabi flavor. 🚀

---

## ✨ Features

- **Nuclear Sync ⚛️**: Stale data is history. Real-time synchronization with Supabase ensures your records are always accurate across devices.
- **Cheeky Dashboard 📈**: From "Damage Reports" to "Udaan Reports," get a witty breakdown of where your money is going.
- **Daily Reminders 🔔**: Stay on track with randomized Punjabi nudges like *"Oye Bhawuk! Aaj ka kharcha daala ki nahi? 🔥"*
- **Home Screen Widget 📱**: Track your monthly damage without even opening the app.
- **Premium Dark UI 🎨**: A vibrant orange-gold theme that feels high-end and alive.
- **Search & Insights 🕵️**: Categorized breakdowns with labels and interactive 7-day spending charts.

---

## 📸 Screenshots

| Dashboard | Add Expense | Settings |
| :---: | :---: | :---: |
| ![Dashboard] | ![Add Expense] | ![Settings] |
| *Paise kithe gaye?* | *Daal De Paaji!* | *Reminder Set Karo* |

*(Note: Add your actual screenshot links here once uploaded!)*

---

## 🛠️ Built With

- **Flutter & Dart** - Cross-platform excellence.
- **Supabase** - Real-time database & Auth.
- **Riverpod** - Rock-solid state management.
- **Hive** - Lightning-fast local persistence.
- **FL Chart** - Beautiful, interactive data viz.
- **Google Fonts** - Stylish typography (Poppins).

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (Latest Stable)
- Supabase Account (for backend)

### Setup

1. **Clone the repo:**
   ```bash
   git clone https://github.com/geeky-bhawuk-arora/pocketLedger.git
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase:**
   Create a `lib/core/constants.dart` and add your keys:
   ```dart
   class AppConstants {
     static const String supabaseUrl = 'YOUR_URL';
     static const String supabaseAnonKey = 'YOUR_ANON_KEY';
   }
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

---

## 📦 How to Build (Release)

Need to install it on your phone? Run this "jugaad" command:

```bash
flutter build apk --release --split-per-abi
```

The APKs will be waiting for you in `build/app/outputs/flutter-apk/`.

---

## 🤝 Contribution

Found a bug? Or have a cheekier Punjabi dialogue idea? 
- Open an Issue.
- Fork it and send a PR.

*banaaya with ☕ & galat decisions by Bhawuk 🫡*
