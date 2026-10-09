import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/game_theme.dart';
import '../widgets/neon_button.dart';

class FirebaseGuideModal extends StatelessWidget {
  final bool isConnected;

  const FirebaseGuideModal({
    super.key,
    required this.isConnected,
  });

  static void show(BuildContext context, {required bool isConnected}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FirebaseGuideModal(isConnected: isConnected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: GameTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: GameTheme.neonPurple, width: 2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isConnected
                      ? GameTheme.neonGreen.withValues(alpha: 0.2)
                      : GameTheme.neonAmber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConnected ? Icons.cloud_done : Icons.cloud_queue,
                  color: isConnected ? GameTheme.neonGreen : GameTheme.neonAmber,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Firebase Backend Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isConnected
                          ? 'Connected to Live Firebase Firestore'
                          : 'Running in Local Multi-tab / Simulation Mode',
                      style: TextStyle(
                        fontSize: 13,
                        color: isConnected ? GameTheme.neonGreen : GameTheme.neonAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 10),

          // Content scroll
          Expanded(
            child: ListView(
              children: [
                _buildInfoBox(
                  'Do you need to set up Firebase?',
                  'YES for online multi-device play across the internet! The app is 100% pre-coded for Firebase Firestore, but each project needs its own Firebase project credentials.\n\n⚡ GOOD NEWS: You can also test and play right now in Demo / Local mode with bots and instant rooms!',
                  Icons.info_outline,
                  GameTheme.neonCyan,
                ),
                const SizedBox(height: 16),
                const Text(
                  '3 Easy Steps to Connect Your Firebase:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStepItem(
                  '1',
                  'Create Firebase Project',
                  'Go to console.firebase.google.com and click "Add project". Name it e.g. "truth-or-dare-game".',
                ),
                _buildStepItem(
                  '2',
                  'Enable Cloud Firestore',
                  'In Firebase Console, click Build -> Firestore Database -> Create database. Select "Start in test mode" (rules allow read/write).',
                ),
                _buildStepItem(
                  '3',
                  'Run FlutterFire CLI',
                  'Open your terminal in this project folder and run:\n\n'
                      'npm install -g firebase-tools\n'
                      'dart pub global activate flutterfire_cli\n'
                      'flutterfire configure\n\n'
                      'This automatically generates `firebase_options.dart` and links Android/iOS/Web!',
                ),
                const SizedBox(height: 12),
                _buildCommandSnippet(context, 'flutterfire configure'),
                const SizedBox(height: 16),
                _buildInfoBox(
                  'Firestore Security Rules (Optional)',
                  'rules_version = \'2\';\nservice cloud.firestore {\n  match /databases/{database}/documents {\n    match /rooms/{roomCode} {\n      allow read, write: if true;\n    }\n  }\n}',
                  Icons.security,
                  GameTheme.neonPurple,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          NeonButton(
            text: 'Got it, Let\'s Play!',
            onPressed: () => Navigator.pop(context),
            primaryColor: GameTheme.neonPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: GameTheme.surfaceElevated,
              border: Border.fromBorderSide(
                BorderSide(color: GameTheme.neonPurple, width: 1.5),
              ),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: GameTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandSnippet(BuildContext context, String command) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              command,
              style: const TextStyle(
                fontFamily: 'Courier',
                color: GameTheme.neonGreen,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: command));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Command copied to clipboard!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
