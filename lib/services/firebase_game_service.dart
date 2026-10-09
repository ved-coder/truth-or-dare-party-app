import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_room_model.dart';
import '../models/player_model.dart';
import '../models/prompt_model.dart';
import 'game_service.dart';
import 'prompt_repository.dart';

class FirebaseGameService implements GameService {
  final FirebaseFirestore _firestore;

  FirebaseGameService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  bool get isConnectedToFirebase => true;

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection('rooms');

  static String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    final code = List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
    return code;
  }

  @override
  Stream<GameRoom?> streamRoom(String roomCode) {
    return _roomsRef.doc(roomCode.toUpperCase()).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return GameRoom.fromMap(snapshot.data()!);
    });
  }

  @override
  Future<GameRoom> createRoom({
    required Player hostPlayer,
    IntensityLevel intensity = IntensityLevel.spicy,
  }) async {
    final roomCode = generateRoomCode();
    final newRoom = GameRoom(
      roomCode: roomCode,
      hostId: hostPlayer.id,
      status: RoomStatus.lobby,
      players: {hostPlayer.id: hostPlayer.copyWith(isHost: true, isReady: true)},
      intensityLevel: intensity,
    );

    await _roomsRef.doc(roomCode).set(newRoom.toMap());
    return newRoom;
  }

  @override
  Future<GameRoom?> joinRoom({
    required String roomCode,
    required Player player,
  }) async {
    final docRef = _roomsRef.doc(roomCode.toUpperCase());
    final snapshot = await docRef.get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    final room = GameRoom.fromMap(snapshot.data()!);
    final updatedPlayers = Map<String, dynamic>.from(snapshot.data()!['players'] ?? {});
    updatedPlayers[player.id] = player.copyWith(isHost: false).toMap();

    await docRef.update({'players': updatedPlayers});
    return room.copyWith(
      players: {
        ...room.players,
        player.id: player.copyWith(isHost: false),
      },
    );
  }

  @override
  Future<void> leaveRoom({
    required String roomCode,
    required String playerId,
  }) async {
    final docRef = _roomsRef.doc(roomCode.toUpperCase());
    final snapshot = await docRef.get();
    if (!snapshot.exists || snapshot.data() == null) return;

    final room = GameRoom.fromMap(snapshot.data()!);
    final updatedPlayers = Map<String, Player>.from(room.players);
    updatedPlayers.remove(playerId);

    if (updatedPlayers.isEmpty) {
      await docRef.delete();
      return;
    }

    String newHostId = room.hostId;
    if (room.hostId == playerId) {
      newHostId = updatedPlayers.keys.first;
      final newHost = updatedPlayers[newHostId]!.copyWith(isHost: true);
      updatedPlayers[newHostId] = newHost;
    }

    await docRef.update({
      'hostId': newHostId,
      'players': updatedPlayers.map((k, v) => MapEntry(k, v.toMap())),
    });
  }

  @override
  Future<void> toggleReady({
    required String roomCode,
    required String playerId,
    required bool isReady,
  }) async {
    final docRef = _roomsRef.doc(roomCode.toUpperCase());
    await docRef.update({
      'players.$playerId.isReady': isReady,
    });
  }

  @override
  Future<void> updateSettings({
    required String roomCode,
    IntensityLevel? intensity,
    int? timerDurationSeconds,
  }) async {
    final docRef = _roomsRef.doc(roomCode.toUpperCase());
    final updates = <String, dynamic>{};
    if (intensity != null) updates['intensityLevel'] = intensity.name;
    if (timerDurationSeconds != null) {
      updates['timerDurationSeconds'] = timerDurationSeconds;
      updates['timerRemainingSeconds'] = timerDurationSeconds;
    }
    if (updates.isNotEmpty) {
      await docRef.update(updates);
    }
  }

  @override
  Future<void> addCustomPrompt({
    required String roomCode,
    required PromptItem prompt,
  }) async {
    final docRef = _roomsRef.doc(roomCode.toUpperCase());
    await docRef.update({
      'customPrompts': FieldValue.arrayUnion([prompt.toMap()]),
    });
  }

  @override
  Future<void> startGame({
    required String roomCode,
  }) async {
    final docRef = _roomsRef.doc(roomCode.toUpperCase());
    await docRef.update({
      'status': RoomStatus.spinning.name,
      'roundNumber': 1,
    });
  }

  @override
  Future<void> spinWheel({
    required String roomCode,
    required double targetAngle,
    required String chosenPlayerId,
  }) async {
    final docRef = _roomsRef.doc(roomCode.toUpperCase());
    await docRef.update({
      'status': RoomStatus.spinning.name,
      'spinTargetAngle': targetAngle,
      'spinTimestamp': DateTime.now().millisecondsSinceEpoch,
      'currentTurnPlayerId': chosenPlayerId,
      'currentPrompt': null,
      'currentTurnType': null,
      'votes': {},
    });
  }

  @override
  Future<void> selectPromptChoice({
    required String roomCode,
    required PromptType type,
  }) async {
    final docRef = _roomsRef.doc(roomCode.toUpperCase());
    final snapshot = await docRef.get();
    if (!snapshot.exists || snapshot.data() == null) return;

    final room = GameRoom.fromMap(snapshot.data()!);
    final prompt = PromptRepository.getRandomPrompt(
      type: type,
      intensity: room.intensityLevel,
      customPrompts: room.customPrompts,
    );

    await docRef.update({
      'status': RoomStatus.performing.name,
      'currentTurnType': type.name,
      'currentPrompt': prompt.toMap(),
      'timerRemainingSeconds': room.timerDurationSeconds,
      'votes': {},
    });
  }

  @override
  Future<void> submitVote({
    required String roomCode,
    required String votingPlayerId,
    required bool passed,
  }) async {
    final docRef = _roomsRef.doc(roomCode.toUpperCase());
    await docRef.update({
      'votes.$votingPlayerId': passed,
    });
  }

  @override
  Future<void> completeTurn({
    required String roomCode,
    required bool passed,
  }) async {
    final docRef = _roomsRef.doc(roomCode.toUpperCase());
    final snapshot = await docRef.get();
    if (!snapshot.exists || snapshot.data() == null) return;

    final room = GameRoom.fromMap(snapshot.data()!);
    final turnPlayerId = room.currentTurnPlayerId;
    if (turnPlayerId == null) return;

    final player = room.players[turnPlayerId];
    if (player == null) return;

    final updatedPlayer = passed
        ? player.copyWith(score: player.score + 10)
        : player.copyWith(penalties: player.penalties + 1);

    await docRef.update({
      'status': RoomStatus.roundSummary.name,
      'players.$turnPlayerId': updatedPlayer.toMap(),
    });
  }

  @override
  Future<void> nextRound({
    required String roomCode,
  }) async {
    final docRef = _roomsRef.doc(roomCode.toUpperCase());
    final snapshot = await docRef.get();
    if (!snapshot.exists || snapshot.data() == null) return;

    final room = GameRoom.fromMap(snapshot.data()!);
    await docRef.update({
      'status': RoomStatus.spinning.name,
      'roundNumber': room.roundNumber + 1,
      'currentTurnPlayerId': null,
      'currentPrompt': null,
      'currentTurnType': null,
      'votes': {},
    });
  }

  @override
  Future<void> addBotPlayer({
    required String roomCode,
    required String botName,
  }) async {
    final botId = 'bot_${DateTime.now().millisecondsSinceEpoch % 10000}';
    final emojis = ['🤖', '🦄', '🦁', '🎭', '⚡', '🔥'];
    final colors = [0xFFEC4899, 0xFF06B6D4, 0xFFF59E0B, 0xFF10B981, 0xFF6366F1];
    final rand = Random();

    final botPlayer = Player(
      id: botId,
      name: botName,
      avatarEmoji: emojis[rand.nextInt(emojis.length)],
      colorValue: colors[rand.nextInt(colors.length)],
      isHost: false,
      isReady: true,
      score: 0,
      penalties: 0,
    );

    final docRef = _roomsRef.doc(roomCode.toUpperCase());
    await docRef.update({
      'players.$botId': botPlayer.toMap(),
    });
  }

  @override
  Future<void> returnToLobby({
    required String roomCode,
  }) async {
    final docRef = _roomsRef.doc(roomCode.toUpperCase());
    await docRef.update({
      'status': RoomStatus.lobby.name,
      'currentTurnPlayerId': null,
      'currentPrompt': null,
      'currentTurnType': null,
      'votes': {},
    });
  }
}
