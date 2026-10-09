import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/player_model.dart';
import 'game_service.dart';
import 'firebase_game_service.dart';
import 'local_sim_service.dart';

class GameManager extends ChangeNotifier {
  static final GameManager _instance = GameManager._internal();
  factory GameManager() => _instance;
  GameManager._internal();

  GameService? _activeService;
  bool _firebaseConfigured = false;
  Player? _currentPlayer;
  String? _currentRoomCode;

  GameService get service => _activeService ?? LocalSimService();
  bool get isFirebaseActive => _firebaseConfigured && (_activeService is FirebaseGameService);
  Player? get currentPlayer => _currentPlayer;
  String? get currentRoomCode => _currentRoomCode;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load or generate player profile
    final savedPlayerStr = prefs.getString('local_player_profile');
    if (savedPlayerStr != null) {
      try {
        final map = jsonDecode(savedPlayerStr) as Map<String, dynamic>;
        _currentPlayer = Player.fromMap(map);
      } catch (_) {}
    }

    if (_currentPlayer == null) {
      final newId = const Uuid().v4().substring(0, 8);
      _currentPlayer = Player(
        id: newId,
        name: 'Player_${newId.substring(0, 4)}',
        avatarEmoji: '⚡',
        colorValue: 0xFF8B5CF6,
      );
      await savePlayerProfile(_currentPlayer!);
    }

    // Check Firebase initialization
    try {
      if (Firebase.apps.isNotEmpty) {
        _firebaseConfigured = true;
        _activeService = FirebaseGameService();
      } else {
        _firebaseConfigured = false;
        _activeService = LocalSimService();
      }
    } catch (e) {
      _firebaseConfigured = false;
      _activeService = LocalSimService();
    }

    notifyListeners();
  }

  Future<void> savePlayerProfile(Player player) async {
    _currentPlayer = player;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_player_profile', jsonEncode(player.toMap()));
    notifyListeners();
  }

  void setCurrentRoomCode(String? code) {
    _currentRoomCode = code;
    notifyListeners();
  }

  void forceSwitchToLocalSim() {
    _activeService = LocalSimService();
    notifyListeners();
  }

  void forceSwitchToFirebase() {
    if (Firebase.apps.isNotEmpty) {
      _activeService = FirebaseGameService();
      _firebaseConfigured = true;
      notifyListeners();
    }
  }
}
