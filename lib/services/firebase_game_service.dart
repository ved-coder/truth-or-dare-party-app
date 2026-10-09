import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_room_model.dart';
import '../models/player_model.dart';
import '../models/prompt_model.dart';
import '../models/round_history_model.dart';
import 'game_service.dart';
import 'prompt_repository.dart';

class FirebaseGameService implements GameService {
  final FirebaseFirestore _firestore;

  FirebaseGameService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  bool get isConnectedToFirebase => true;

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection('game_rooms');

  CollectionReference<Map<String, dynamic>> get _archiveRef =>
      _firestore.collection('game_sessions_archive');

  static String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
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
    final now = DateTime.now().millisecondsSinceEpoch;

    final hostWithMeta = hostPlayer.copyWith(
      isHost: true,
      isReady: true,
      joinedTimestamp: now,
    );

    final newRoom = GameRoom(
      roomCode: roomCode,
      hostId: hostPlayer.id,
      status: RoomStatus.lobby,
      players: {hostPlayer.id: hostWithMeta},
      intensityLevel: intensity,
      createdAt: now,
    );

    final roomDoc = _roomsRef.doc(roomCode);
    await roomDoc.set(newRoom.toMap());

    // Structured subcollection: game_rooms/{roomCode}/players/{playerId}
    await roomDoc.collection('players').doc(hostPlayer.id).set(hostWithMeta.toMap());

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
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedPlayer = player.copyWith(
      isHost: false,
      joinedTimestamp: now,
    );

    final updatedPlayers = Map<String, dynamic>.from(snapshot.data()!['players'] ?? {});
    updatedPlayers[player.id] = updatedPlayer.toMap();

    await docRef.update({
      'players': updatedPlayers,
      'totalPlayers': updatedPlayers.length,
    });

    // Structured subcollection: game_rooms/{roomCode}/players/{playerId}
    await docRef.collection('players').doc(player.id).set(updatedPlayer.toMap());

    return room.copyWith(
      players: {
        ...room.players,
        player.id: updatedPlayer,
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

    // Delete or mark inactive in subcollection
    await docRef.collection('players').doc(playerId).delete().catchError((_) {});

    if (updatedPlayers.isEmpty) {
      // Archive session before deleting
      final now = DateTime.now().millisecondsSinceEpoch;
      final duration = room.startedAt > 0 ? (now - room.startedAt) ~/ 1000 : 0;

      await _archiveRef.doc(roomCode).set({
        ...room.toMap(),
        'endedAt': now,
        'totalDurationSeconds': duration,
        'status': RoomStatus.ended.name,
      });

      await docRef.delete();
      return;
    }

    String newHostId = room.hostId;
    if (room.hostId == playerId) {
      newHostId = updatedPlayers.keys.first;
      final newHost = updatedPlayers[newHostId]!.copyWith(isHost: true);
      updatedPlayers[newHostId] = newHost;
      await docRef.collection('players').doc(newHostId).update({'isHost': true});
    }

    await docRef.update({
      'hostId': newHostId,
      'players': updatedPlayers.map((k, v) => MapEntry(k, v.toMap())),
      'totalPlayers': updatedPlayers.length,
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
    await docRef.collection('players').doc(playerId).update({'isReady': isReady});
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

    // Structured subcollection: game_rooms/{roomCode}/questions/{promptId}
    await docRef.collection('questions').doc(prompt.id).set(prompt.toMap());
  }

  @override
  Future<void> startGame({
    required String roomCode,
  }) async {
    final docRef = _roomsRef.doc(roomCode.toUpperCase());
    final now = DateTime.now().millisecondsSinceEpoch;
    await docRef.update({
      'status': RoomStatus.spinning.name,
      'roundNumber': 1,
      'startedAt': now,
    });
  }

  @override
  Future<void> spinWheel({
    required String roomCode,
    required double targetAngle,
    required String chosenPlayerId,
  }) async {
    final docRef = _roomsRef.doc(roomCode.toUpperCase());
    final snapshot = await docRef.get();
    if (!snapshot.exists || snapshot.data() == null) return;

    final room = GameRoom.fromMap(snapshot.data()!);
    final now = DateTime.now().millisecondsSinceEpoch;
    final chosenPlayer = room.players[chosenPlayerId];

    await docRef.update({
      'status': RoomStatus.spinning.name,
      'spinTargetAngle': targetAngle,
      'spinTimestamp': now,
      'currentTurnPlayerId': chosenPlayerId,
      'currentPrompt': null,
      'currentTurnType': null,
      'votes': {},
    });

    // Record the spin result in structured subcollection: game_rooms/{roomCode}/rounds/round_{roundNumber}
    await docRef.collection('rounds').doc('round_${room.roundNumber}').set({
      'roundNumber': room.roundNumber,
      'selectedPlayerId': chosenPlayerId,
      'selectedPlayerName': chosenPlayer?.name ?? 'Player',
      'spinTargetAngle': targetAngle,
      'spinTimestamp': now,
      'createdAt': now,
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

    final turnPlayerId = room.currentTurnPlayerId;
    if (turnPlayerId != null && room.players.containsKey(turnPlayerId)) {
      final player = room.players[turnPlayerId]!;
      final updatedPlayer = type == PromptType.truth
          ? player.copyWith(truthsChosen: player.truthsChosen + 1)
          : player.copyWith(daresChosen: player.daresChosen + 1);

      await docRef.update({
        'status': RoomStatus.performing.name,
        'currentTurnType': type.name,
        'currentPrompt': prompt.toMap(),
        'timerRemainingSeconds': room.timerDurationSeconds,
        'votes': {},
        'players.$turnPlayerId': updatedPlayer.toMap(),
      });

      // Update player document in subcollection
      await docRef.collection('players').doc(turnPlayerId).update({
        'truthsChosen': updatedPlayer.truthsChosen,
        'daresChosen': updatedPlayer.daresChosen,
      });

      // Update round document in subcollection with the question details
      await docRef.collection('rounds').doc('round_${room.roundNumber}').set({
        'choiceType': type.name,
        'promptId': prompt.id,
        'promptText': prompt.text,
        'promptCategory': prompt.category,
        'promptIntensity': prompt.intensity.name,
        'submittedByPlayerName': prompt.submittedByPlayerName,
      }, SetOptions(merge: true));
    }
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

    final now = DateTime.now().millisecondsSinceEpoch;

    // Create RoundHistory entry
    final roundRecord = RoundHistory(
      roundNumber: room.roundNumber,
      selectedPlayerId: turnPlayerId,
      selectedPlayerName: player.name,
      spinTargetAngle: room.spinTargetAngle,
      spinTimestamp: room.spinTimestamp,
      choiceType: room.currentTurnType,
      promptId: room.currentPrompt?.id,
      promptText: room.currentPrompt?.text,
      promptCategory: room.currentPrompt?.category,
      promptIntensity: room.currentPrompt?.intensity,
      submittedByPlayerName: room.currentPrompt?.submittedByPlayerName,
      isCompleted: passed,
      pointsAwarded: passed ? 10 : 0,
      forfeitsAwarded: passed ? 0 : 1,
      completedTimestamp: now,
    );

    final updatedHistory = List<RoundHistory>.from(room.roundsHistory)..add(roundRecord);

    await docRef.update({
      'status': RoomStatus.roundSummary.name,
      'players.$turnPlayerId': updatedPlayer.toMap(),
      'roundsHistory': updatedHistory.map((r) => r.toMap()).toList(),
    });

    // Update player document in subcollection
    await docRef.collection('players').doc(turnPlayerId).update(updatedPlayer.toMap());

    // Finalize round document in subcollection
    await docRef.collection('rounds').doc('round_${room.roundNumber}').set(
      roundRecord.toMap(),
      SetOptions(merge: true),
    );
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
    final now = DateTime.now().millisecondsSinceEpoch;

    final botPlayer = Player(
      id: botId,
      name: botName,
      avatarEmoji: emojis[rand.nextInt(emojis.length)],
      colorValue: colors[rand.nextInt(colors.length)],
      isHost: false,
      isReady: true,
      score: 0,
      penalties: 0,
      joinedTimestamp: now,
    );

    final docRef = _roomsRef.doc(roomCode.toUpperCase());
    await docRef.update({
      'players.$botId': botPlayer.toMap(),
      'totalPlayers': FieldValue.increment(1),
    });

    await docRef.collection('players').doc(botId).set(botPlayer.toMap());
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
