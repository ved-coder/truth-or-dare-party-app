<div align="center">
  <img src="assets/logo.png" alt="Truth or Dare Party Logo" width="180" style="border-radius: 24px; box-shadow: 0 10px 30px rgba(139, 92, 246, 0.4);" />
  
  # 🎡 Truth or Dare • Multiplayer Party Arena

  [![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
  [![Platform](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows-blue)](#getting-started)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
  
  *A real-time multiplayer party game with synchronized physics spin-the-wheel, curated truth or dare prompts, and comprehensive Firebase cloud session tracking.*
</div>

---

## 🗄️ Database & Document Architecture (Firebase Cloud Firestore)

The backend is structured into relational document collections and subcollections for live multiplayer gameplay and session history analytics:

```
cloud_firestore/
│
├── 📁 game_rooms/                          # Active game rooms
│   └── 📄 {roomCode}/                     # Document ID: e.g. "TRUTH-789"
│       ├── roomCode: string
│       ├── hostId: string
│       ├── status: "lobby" | "spinning" | "choosing" | "performing" | "roundSummary" | "ended"
│       ├── totalPlayers: number           # Active player count
│       ├── intensityLevel: "mild" | "spicy" | "extreme"
│       ├── roundNumber: number            # Current round index
│       ├── currentTurnPlayerId: string    # Player currently selected by the pointer
│       ├── spinTargetAngle: number        # Synchronized angle in radians
│       ├── spinTimestamp: timestamp       # Spin start timestamp
│       ├── createdAt: timestamp           # When room was created
│       ├── startedAt: timestamp           # When game started
│       ├── endedAt: timestamp             # When game ended
│       ├── totalDurationSeconds: number   # Total room active time
│       │
│       ├── 📁 players/                    # Subcollection: Joined players & live scores
│       │   └── 📄 {playerId}/
│       │       ├── id: string
│       │       ├── name: string
│       │       ├── avatarEmoji: string
│       │       ├── colorValue: number
│       │       ├── isHost: boolean
│       │       ├── isReady: boolean
│       │       ├── score: number          # Total points (+10 per passed prompt)
│       │       ├── penalties: number      # Forfeit strikes count
│       │       ├── truthsChosen: number   # How many truths this player selected
│       │       ├── daresChosen: number    # How many dares this player selected
│       │       └── joinedTimestamp: timestamp
│       │
│       ├── 📁 rounds/                     # Subcollection: Complete history of every round
│       │   └── 📄 round_{roundNumber}/
│       │       ├── roundNumber: number
│       │       ├── selectedPlayerId: string
│       │       ├── selectedPlayerName: string
│       │       ├── spinTargetAngle: number
│       │       ├── spinTimestamp: timestamp
│       │       ├── choiceType: "truth" | "dare"
│       │       ├── promptId: string
│       │       ├── promptText: string     # The exact question/dare asked
│       │       ├── promptCategory: string
│       │       ├── promptIntensity: string
│       │       ├── submittedByPlayerName: string? # If player custom card
│       │       ├── isCompleted: boolean   # Passed vs Forfeit strike
│       │       ├── pointsAwarded: number
│       │       ├── forfeitsAwarded: number
│       │       └── completedTimestamp: timestamp
│       │
│       └── 📁 questions/                  # Subcollection: Custom cards submitted in room
│           └── 📄 {promptId}/
│               ├── id: string
│               ├── text: string
│               ├── type: "truth" | "dare"
│               ├── intensity: "mild" | "spicy" | "extreme"
│               └── submittedByPlayerName: string
│
└── 📁 game_sessions_archive/               # Immutable archive of ended party sessions
    └── 📄 {roomCode}/                     # Complete room record with duration & leaderboard
```

---

## ✨ Features

- 🎮 **Real-Time Multiplayer Lobbies**
  - Instant room creation with clean 6-character room codes (e.g. `TRUTH-842`).
  - Join via code from any device (Mobile, Web, or Desktop).
  - Personalized player profiles (choose name, avatar emoji, and glow theme color).
  - One-click `+ Add Bot` button to test multiplayer solo immediately.

- 🎡 **Synchronized Physics Spin-the-Wheel**
  - Dynamic CustomPainter roulette wheel divided into slices based on active players.
  - High-precision pointer needle at 12 o'clock—the player on whose slice the arrow stops is declared the active turn player.
  - Synchronized wheel spin across all devices via Firestore.

- 💭 **Truth or Dare Decision Stage**
  - Active player chooses **TRUTH 💭** or **DARE 🔥**.
  - 150+ curated prompts categorized by intensity:
    - 😇 **Mild / Icebreaker** (fun, friendly questions)
    - 🌶️ **Spicy** (embarrassing confessions & bold challenges)
    - ⚡ **Wild / Extreme** (outrageous party antics)

- ✍️ **Custom Cards Creator**
  - Players can submit their own custom Truths and Dares to the room's live deck during the lobby.

- ⚡ **Decent Forfeit Strike System**
  - Family-friendly and decent party rules:
    - **`COMPLETED! (+10 PTS) 🎉`** with confetti celebration!
    - **`PASS / TAKE FORFEIT STRIKE (+1) ⚡`** for skipping or failing a dare.

- 🏆 **Light Yellow & Orange Mix Scoreboard**
  - Radiant score modal with warm yellow and orange sunset gradients.
  - Live ranking leaderboard showing player points (★) and forfeit strikes (⚡).

- 🚪 **Quit & End Game Controls**
  - In-game exit modal:
    - **Host:** Option to "Return to Lobby" (bringing all players back) or "Quit Game".
    - **Players:** Clean option to exit back to the Home screen.

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

## 🔒 Firestore Security Rules

In your Firebase Console ➜ **Firestore Database** ➜ **Rules**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allows full access to active game rooms and archives
    match /game_rooms/{roomCode} {
      allow read, write: if true;
      
      match /{allSubcollections=**} {
        allow read, write: if true;
      }
    }
    match /game_sessions_archive/{roomCode} {
      allow read, write: if true;
    }
  }
}
```

---

## 📄 License
This project is licensed under the MIT License - feel free to use and modify for your party game nights!
