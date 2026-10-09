# 🎡 Truth or Dare • Real-Time Multiplayer Party Game

[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows-blue)](#getting-started)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A modern, real-time multiplayer **Truth or Dare** party game built with **Flutter** and **Firebase Cloud Firestore**. Players join custom party lobbies using a unique 6-character room code, customize their avatars, and take turns spinning a synchronized neon roulette wheel!

---

## ✨ Features

- 🎮 **Real-Time Multiplayer Lobbies**
  - Instant room creation with clean 6-character room codes (e.g. `TRUTH-842`).
  - Join via code from any device (Mobile, Web, or Desktop).
  - Personalized player profiles (choose name, avatar emoji, and glow theme color).
  - One-click `+ Add Bot` button to test multiplayer solo immediately.

- 🎡 **Synchronized Physics Spin-the-Wheel**
  - Dynamic CustomPainter roulette wheel divided into slices based on active players in the room.
  - High-precision pointer needle at 12 o'clock—the player on whose slice the arrow stops is declared the active turn player.
  - Synchronized wheel spin across all devices via Firestore so all players watch the wheel spin and land simultaneously!

- 💭 **Truth or Dare Decision Stage**
  - Active player chooses **TRUTH 💭** or **DARE 🔥**.
  - 150+ curated prompts categorized by intensity:
    - 😇 **Mild / Icebreaker** (fun, friendly questions)
    - 🌶️ **Spicy** (embarrassing confessions & bold challenges)
    - ⚡ **Wild / Extreme** (outrageous party antics)

- ✍️ **Custom Cards Creator**
  - Players can submit their own custom Truths and Dares to the room's live deck during the lobby.

- ⏱️ **Live Countdown Timer**
  - Visual circular countdown timer with haptic alerts for completing the challenge.

- ⚡ **Decent Forfeit Strike System**
  - Family-friendly and decent party rules:
    - **`COMPLETED! (+10 PTS) 🎉`** with confetti celebration!
    - **`PASS / TAKE FORFEIT STRIKE (+1) ⚡`** for skipping or failing a dare.

- 🏆 **Real-Time Scoreboard**
  - Live ranking leaderboard showing player points (★) and forfeit strikes (⚡).

- 🚪 **Quit & End Game Controls**
  - In-game exit modal:
    - **Host:** Option to "Return to Lobby" (bringing all players back) or "Quit Game".
    - **Players:** Clean option to exit back to the Home screen.

- ⚡ **Dual-Mode Backend Architecture**
  - **Firebase Firestore:** Full production real-time sync across devices over the internet.
  - **Local Reactive Simulator (`LocalSimService`):** Automatic fallback allowing instant testing and offline play without requiring Firebase credentials.

---

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev) (Dart 3.x)
- **Backend:** [Firebase Cloud Firestore](https://firebase.google.com/docs/firestore) & [Firebase Core](https://firebase.google.com)
- **State & Real-Time Sync:** Streams & Reactive Listeners
- **Animations & Effects:** Flutter Canvas CustomPainter, [Confetti](https://pub.dev/packages/confetti)
- **Typography:** [Google Fonts (Outfit)](https://fonts.google.com/specimen/Outfit)
- **Local Cache:** [shared_preferences](https://pub.dev/packages/shared_preferences)

---

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/ved-coder/truth-or-dare-party-app.git
cd truth-or-dare-party-app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App

#### Run on Google Chrome (Fastest for testing):
```bash
flutter run -d chrome
```

#### Run on Android:
```bash
flutter run -d android
```

#### Run on Windows Desktop:
```bash
flutter run -d windows
```

---

## 🔥 Firebase Setup (Optional for Online Multi-Device Play)

The app is pre-configured with `firebase_options.dart`. To link your own Firebase project:

1. Install Firebase CLI & FlutterFire CLI:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   ```
2. Log in and configure:
   ```bash
   firebase login
   flutterfire configure --project=YOUR_PROJECT_ID
   ```
3. Set your Firestore Security Rules in the Firebase Console:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /rooms/{roomCode} {
         allow read, write: if true;
       }
     }
   }
   ```

---

## 📁 Project Structure

```
lib/
├── main.dart                      # App entry point & Firebase initialization
├── firebase_options.dart          # Auto-generated Firebase client credentials
├── models/
│   ├── player_model.dart          # Player profile & score model
│   ├── game_room_model.dart       # Room state, sync flags & status enums
│   └── prompt_model.dart          # Truth & Dare challenge model
├── services/
│   ├── game_service.dart          # Abstract interface for game rooms
│   ├── firebase_game_service.dart # Real-time Cloud Firestore implementation
│   ├── local_sim_service.dart     # In-memory reactive simulator fallback
│   ├── game_manager.dart          # Facade managing player identity & backend
│   └── prompt_repository.dart     # 150+ categorized truths & dares database
├── theme/
│   └── game_theme.dart            # Cyber party styling, colors & decorations
├── widgets/
│   ├── spin_wheel_widget.dart     # CustomPainter physics-based roulette wheel
│   ├── countdown_timer_widget.dart# Circular timer with warning haptics
│   ├── player_avatar.dart         # Player badge with crown & status
│   ├── neon_button.dart           # Animated tactile neon button
│   └── firebase_guide_modal.dart  # In-app setup instructions modal
└── screens/
    ├── home_screen.dart           # Profile setup, create & join room
    ├── lobby_screen.dart          # Live waiting room, room code card & host controls
    ├── game_arena_screen.dart     # Main spin wheel, challenge & scoreboard arena
    └── add_prompt_dialog.dart     # Custom card creator modal
```

---

## 📄 License
This project is licensed under the MIT License - feel free to use and modify for your party game nights!
