import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/game_manager.dart';
import 'theme/game_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with generated project options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init fallback: $e');
  }

  // Initialize player identity & room service manager
  await GameManager().initialize();

  runApp(const TruthOrDareApp());
}

class TruthOrDareApp extends StatelessWidget {
  const TruthOrDareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truth or Dare • Party Arena',
      debugShowCheckedModeBanner: false,
      theme: GameTheme.themeData,
      home: const HomeScreen(),
    );
  }
}
