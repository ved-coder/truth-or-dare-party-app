# SYSTEM PROJECT
## ITP31 Mini Project (Research Project)

# Truth or Dare • Multiplayer Party Arena

## Project Guidelines

### 1. Application Development Project

| Chapter No | Details |
|------------|---------|
| 1 | Institute Certificate |
| 2 | Introduction |
| 2.1 | Project Purpose |
| 2.2 | Project functions / Modules |
| 3 | Analysis and Design |
| 3.1 | Entity Relationship Diagram (ERD) |
| 3.2 | Table Structure / Data Dictionary |
| 3.3 | Use Case Diagrams |
| 3.4 | Sample Input and Output Screens |
| 4 | Testing |
| 4.1 | Test Case / Test Script |
| 4.2 | Defect report / Test Log |
| 5 | Publication / Competition certificates (If Applicable) |
| 6 | User Manual |

---

## 1. Introduction

### 1.1 Project Purpose
This project aims to design and develop a mobile and web-based party game application called Truth or Dare • Multiplayer Party Arena. The system allows multiple players to join a shared room, spin a game wheel, choose between truth or dare challenges, and compete through scoring, penalties, and real-time interaction.

The application is intended to provide entertainment for social gatherings, group hangouts, and online friend interactions. It combines a fun game experience with the use of modern technologies such as Flutter for the frontend and Firebase for real-time synchronization and cloud data storage.

### 1.2 Project Function / Modules
The project is divided into the following functional modules:

1. User Profile Module
   - Player name customization
   - Avatar/emoji selection
   - Color theme selection
   - Persistent profile storage using local preferences

2. Room Creation and Join Module
   - Create a multiplayer room with a unique room code
   - Join room using code
   - Support for host and player roles

3. Lobby Module
   - Show joined players
   - Host controls for starting the game
   - Add bot option for testing
   - Player readiness and room management

4. Spin Wheel Module
   - Real-time wheel rotation
   - Pointer-based selection of the active player
   - Custom painter for fair player distribution

5. Challenge Selection Module
   - Truth or Dare decision
   - Prompt category selection (mild, spicy, extreme)
   - Game logic for turn progression

6. Scoring and Forfeit Module
   - Award points for completed actions
   - Record forfeit strikes for skipped or failed actions
   - Leaderboard display

7. Custom Prompt Module
   - Add new truth and dare prompts in a shared room
   - Manage prompt deck for live rounds

8. Firebase Sync Module
   - Real-time communication between devices
   - Room state synchronization
   - Round history and session recording

9. Admin/User Manual Module
   - Easy-to-follow flow for game play
   - Setup and usage instructions

---

## 2. Analysis and Design

### 2.1 System Overview
The application follows a client-server style architecture using Flutter as the client application and Firebase Firestore as the backend service. The app stores live room information, players, prompts, and round history in Firestore collections and subcollections. Local simulation is also used when Firebase is unavailable, so the game can still run in a local demo mode.

### 2.2 Target Users
- Friends or classmates playing in the same room
- Party organizers hosting group games
- Users who want a simple, entertaining game experience

### 2.3 Functional Requirements
- The system should allow a user to create a new room.
- The system should allow another user to join the room using a unique code.
- The system should display the current list of players.
- The system should randomly select a player for a turn.
- The system should show truth or dare prompts based on the active turn.
- The system should keep track of scores and penalties.
- The system should maintain a leaderboard.
- The system should store room history and active room data in the database.

### 2.4 Non-Functional Requirements
- User-friendly interface
- Fast response time
- Secure data handling for game sessions
- Cross-platform compatibility across mobile, web, and desktop
- Robust error handling for invalid room codes or failed network operations

---

## 3. Entity Relationship Diagram (ERD)

The project can be modeled using the following entities:

- Player
- Room
- Prompt
- RoundHistory
- Vote
- Leaderboard

### ERD Description
A single room is hosted by one user and contains multiple players. Each room has multiple rounds. Each round contains one selected player, one prompt type, and one prompt text. A player can submit custom prompts and can receive score updates after each round.

### Text-Based ERD
```text
PLAYER      1 ----- *      ROOM
  |                         |
  |                         | 1
  |                         *
  +----< submits custom prompt

ROOM        1 ----- *      ROUND_HISTORY
  |                         |
  |                         | 1
  |                         *
  +----< contains player turn state

ROOM        1 ----- *      PROMPT
  |
  +----< shows current truth/dare choices

PLAYER      1 ----- *      SCOREBOARD
  |
  +----< receives points and penalties
```

### 3.1 Main Entities and Attributes

#### Player
- id
- name
- avatarEmoji
- colorValue
- isHost
- isReady
- score
- penalties
- truthsChosen
- daresChosen
- joinedTimestamp

#### Room
- roomCode
- hostId
- status
- totalPlayers
- intensityLevel
- roundNumber
- spinTargetAngle
- spinTimestamp
- createdAt
- startedAt
- endedAt
- totalDurationSeconds

#### Prompt
- id
- text
- type
- intensity
- submittedByPlayerName

#### RoundHistory
- roundNumber
- selectedPlayerId
- selectedPlayerName
- choiceType
- promptId
- promptText
- isCompleted
- pointsAwarded
- forfeitsAwarded
- completedTimestamp

---

## 4. Table Structure / Data Dictionary

### 4.1 Game Room Collection
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| roomCode | String | Unique room identifier |
| hostId | String | Host player ID |
| status | String | Lobby or game status |
| totalPlayers | Number | Number of active players |
| intensityLevel | String | Mild, Spicy, Extreme |
| roundNumber | Number | Current round |
| spinTargetAngle | Number | Wheel angle for synchronized turn selection |
| spinTimestamp | Timestamp | Spin timing |
| createdAt | Timestamp | Room creation time |
| startedAt | Timestamp | Game start time |
| endedAt | Timestamp | End of game time |
| totalDurationSeconds | Number | Total room duration |

### 4.2 Players Subcollection
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| id | String | Player ID |
| name | String | Display name |
| avatarEmoji | String | Selected emoji |
| colorValue | Number | Player theme color |
| isHost | Boolean | Indicates host status |
| isReady | Boolean | Player readiness |
| score | Number | Total score |
| penalties | Number | Forfeit count |
| truthsChosen | Number | Number of truth actions chosen |
| daresChosen | Number | Number of dare actions chosen |

### 4.3 Rounds Subcollection
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| roundNumber | Number | Round count |
| selectedPlayerId | String | Selected player for the turn |
| promptText | String | Text of selected prompt |
| choiceType | String | Truth or dare |
| isCompleted | Boolean | Whether prompt was completed |
| pointsAwarded | Number | Score earned |
| forfeitsAwarded | Number | Penalty count |

---

## 5. Use Case Diagrams

### 5.1 Main Use Cases
1. Create Room
2. Join Room
3. Customize Profile
4. Spin Wheel
5. Choose Truth or Dare
6. Submit Prompt
7. View Leaderboard
8. End Game

### Use Case Narrative
- A user creates a room and becomes the host.
- The host shares the room code with other players.
- Players join using the code.
- The host starts the game.
- The wheel randomly selects a player.
- The selected player chooses a challenge type.
- A prompt is displayed and the player either completes it or receives a penalty.
- The score is updated and the round ends.

---

## 6. Sample Input and Output Screens

### 6.1 Sample Input Screens
1. Home Screen
   - Player name input
   - Avatar selection
   - Room code field
   - Create room / join room actions

2. Lobby Screen
   - Room code display
   - Player list
   - Add bot option
   - Ready/start game controls

3. Add Custom Prompt Dialog
   - Prompt text input
   - Type selection (Truth / Dare)
   - Intensity selection (Mild / Spicy / Extreme)

### 6.2 Sample Output Screens
1. Game Arena Screen
   - Spin wheel animation
   - Selected player highlight
   - Truth/Dare choice UI
   - Countdown timer

2. Leaderboard / Scoreboard Screen
   - Player rankings
   - Total score display
   - Penalty count display
   - Confetti and success celebration for completed actions

3. End Game Summary Screen
   - Final results
   - Winner display
   - Session duration and room statistics

---

## 7. Testing

### 7.1 Test Case / Test Script
The following table shows a sample test plan for the application:

| Test ID | Test Name | Input | Expected Result |
|---------|-----------|-------|-----------------|
| TC01 | Create room | Enter player details, click create room | Room is created and unique code generated |
| TC02 | Join room | Enter valid room code | User joins room successfully |
| TC03 | Invalid room code | Enter wrong room code | Error message shown |
| TC04 | Spin wheel | Tap spin button | Player rotates wheel and selection updates |
| TC05 | Choose truth/dare | Select option from challenge panel | Correct prompt is shown |
| TC06 | Score update | Complete challenge | Score increments by 10 |
| TC07 | Forfeit update | Skip or fail challenge | Penalty increases by 1 |
| TC08 | Add custom prompt | Submit a custom prompt | Prompt appears in session deck |

### 7.2 Defect Report / Test Log
| Defect ID | Description | Severity | Status |
|-----------|-------------|----------|--------|
| DF01 | Room not found error in invalid room code scenario | Medium | Fixed |
| DF02 | Timer countdown resets unexpectedly | Low | Fixed |
| DF03 | Leaderboard not updating in real time | Medium | Fixed |
| DF04 | Firebase initialization fails sometimes in offline mode | Medium | Handled with local simulation fallback |

The project was tested with interactive validation of UI flows, manual gameplay simulation, and backend synchronization checks across Firebase and local mode.

---

## 8. Publication / Competition Certificates

This project is suitable for research and innovation showcases, student competitions, or technical exhibitions. If required, the application can be presented with the following supporting materials:

- Project abstract
- System design diagrams
- Screenshots of screenshots and working prototype
- Test results and feature summary
- Demonstration video
- Participant certificate and presentation sheet

If the project is used for competition entry, the project can be documented through a short abstract and participation certificate.

---

## 9. User Manual

### 9.1 How to Run the Project
1. Install Flutter SDK.
2. Open the project folder.
3. Run the following command:

```bash
flutter pub get
```

4. Start the app using:

```bash
flutter run -d chrome
```

or for Android:

```bash
flutter run -d android
```

### 9.2 How to Play
1. Open the app.
2. Enter your player name and choose an avatar.
3. Create a game room or join one using a room code.
4. Wait for other players to join.
5. Press start when the host is ready.
6. The wheel will rotate and choose a player.
7. The selected player chooses Truth or Dare.
8. Complete the challenge or accept the forfeit.
9. Scores update automatically and the leaderboard changes in real time.
10. Continue until the game ends or the room is closed.

### 9.3 Features for Users
- Real-time room synchronization
- Spin wheel gameplay
- Multiplayer party environment
- Score tracking and penalties
- Custom prompt submission
- Fun, modern UI design

---

## 10. Conclusion

The Truth or Dare • Multiplayer Party Arena project is a complete and engaging application that combines entertainment, social interaction, and real-time game logic. It demonstrates practical implementation of Flutter, Firebase, UI design, and logic-based game development. The project is suitable for academic demonstration, group-based entertainment systems, and research-based application development tasks.

This documentation follows the structure required by the project guideline image and provides a formal academic summary of the system.

---

## 11. References

- Flutter Documentation
- Firebase Firestore Documentation
- Dart Programming Guide
- UI design and project planning notes created during system development

