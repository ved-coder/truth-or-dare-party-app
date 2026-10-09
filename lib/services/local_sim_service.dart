import 'dart:async';
import 'dart:math';
import '../models/game_room_model.dart';
import '../models/player_model.dart';
import '../models/prompt_model.dart';
import '../models/round_history_model.dart';
import 'game_service.dart';
import 'prompt_repository.dart';

class LocalSimService implements GameService {
  static final LocalSimService _instance = LocalSimService._internal();
  factory LocalSimService() => _instance;
  LocalSimService._internal();

  @override
  bool get isConnectedToFirebase => false;

  final Map<String, GameRoom> _activeRooms = {};
  final Map<String, StreamController<GameRoom?>> _roomControllers = {};

  StreamController<GameRoom?> _getController(String roomCode) {
    final code = roomCode.toUpperCase();
    if (!_roomControllers.containsKey(code)) {
      _roomControllers[code] = StreamController<GameRoom?>.broadcast();
    }
    return _roomControllers[code]!;
  }

  void _notify(String roomCode) {
    final code = roomCode.toUpperCase();
    final room = _activeRooms[code];
    if (_roomControllers.containsKey(code)) {
      _roomControllers[code]!.add(room);
    }
  }

  static String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  @override
  Stream<GameRoom?> streamRoom(String roomCode) {
    final code = roomCode.toUpperCase();
    final controller = _getController(code);
    Future.microtask(() {
      controller.add(_activeRooms[code]);
    });
    return controller.stream;
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

    _activeRooms[roomCode] = newRoom;
    _notify(roomCode);
    return newRoom;
  }

  @override
  Future<GameRoom?> joinRoom({
    required String roomCode,
    required Player player,
  }) async {
    final code = roomCode.toUpperCase();
    final room = _activeRooms[code];
    if (room == null) return null;

    final updatedPlayers = Map<String, Player>.from(room.players);
    updatedPlayers[player.id] = player.copyWith(isHost: false);

    final updatedRoom = room.copyWith(players: updatedPlayers);
    _activeRooms[code] = updatedRoom;
    _notify(code);
    return updatedRoom;
  }

  @override
  Future<void> leaveRoom({
    required String roomCode,
    required String playerId,
  }) async {
    final code = roomCode.toUpperCase();
    final room = _activeRooms[code];
    if (room == null) return;

    final updatedPlayers = Map<String, Player>.from(room.players);
    updatedPlayers.remove(playerId);

    if (updatedPlayers.isEmpty) {
      _activeRooms.remove(code);
      _notify(code);
      return;
    }

    String newHostId = room.hostId;
    if (room.hostId == playerId) {
      newHostId = updatedPlayers.keys.first;
      updatedPlayers[newHostId] = updatedPlayers[newHostId]!.copyWith(isHost: true);
    }

    final updatedRoom = room.copyWith(
      hostId: newHostId,
      players: updatedPlayers,
    );
    _activeRooms[code] = updatedRoom;
    _notify(code);
  }

  @override
  Future<void> toggleReady({
    required String roomCode,
    required String playerId,
    required bool isReady,
  }) async {
    final code = roomCode.toUpperCase();
    final room = _activeRooms[code];
    if (room == null || !room.players.containsKey(playerId)) return;

    final updatedPlayers = Map<String, Player>.from(room.players);
    updatedPlayers[playerId] = updatedPlayers[playerId]!.copyWith(isReady: isReady);

    _activeRooms[code] = room.copyWith(players: updatedPlayers);
    _notify(code);
  }

  @override
  Future<void> updateSettings({
    required String roomCode,
    IntensityLevel? intensity,
    int? timerDurationSeconds,
  }) async {
    final code = roomCode.toUpperCase();
    final room = _activeRooms[code];
    if (room == null) return;

    _activeRooms[code] = room.copyWith(
      intensityLevel: intensity ?? room.intensityLevel,
      timerDurationSeconds: timerDurationSeconds ?? room.timerDurationSeconds,
      timerRemainingSeconds: timerDurationSeconds ?? room.timerRemainingSeconds,
    );
    _notify(code);
  }

  @override
  Future<void> addCustomPrompt({
    required String roomCode,
    required PromptItem prompt,
  }) async {
    final code = roomCode.toUpperCase();
    final room = _activeRooms[code];
    if (room == null) return;

    final updatedPrompts = List<PromptItem>.from(room.customPrompts)..add(prompt);
    _activeRooms[code] = room.copyWith(customPrompts: updatedPrompts);
    _notify(code);
  }

  @override
  Future<void> startGame({
    required String roomCode,
  }) async {
    final code = roomCode.toUpperCase();
    final room = _activeRooms[code];
    if (room == null) return;

    _activeRooms[code] = room.copyWith(
      status: RoomStatus.spinning,
      roundNumber: 1,
    );
    _notify(code);
  }

  @override
  Future<void> spinWheel({
    required String roomCode,
    required double targetAngle,
    required String chosenPlayerId,
  }) async {
    final code = roomCode.toUpperCase();
    final room = _activeRooms[code];
    if (room == null) return;

    _activeRooms[code] = room.copyWith(
      status: RoomStatus.spinning,
      spinTargetAngle: targetAngle,
      spinTimestamp: DateTime.now().millisecondsSinceEpoch,
      currentTurnPlayerId: chosenPlayerId,
      currentPrompt: null,
      currentTurnType: null,
      votes: {},
    );
    _notify(code);
  }

  @override
  Future<void> selectPromptChoice({
    required String roomCode,
    required PromptType type,
  }) async {
    final code = roomCode.toUpperCase();
    final room = _activeRooms[code];
    if (room == null) return;

    final prompt = PromptRepository.getRandomPrompt(
      type: type,
      intensity: room.intensityLevel,
      customPrompts: room.customPrompts,
    );

    final updatedPlayers = Map<String, Player>.from(room.players);
    final turnId = room.currentTurnPlayerId;
    if (turnId != null && updatedPlayers.containsKey(turnId)) {
      final p = updatedPlayers[turnId]!;
      updatedPlayers[turnId] = type == PromptType.truth
          ? p.copyWith(truthsChosen: p.truthsChosen + 1)
          : p.copyWith(daresChosen: p.daresChosen + 1);
    }

    _activeRooms[code] = room.copyWith(
      status: RoomStatus.performing,
      currentTurnType: type,
      currentPrompt: prompt,
      timerRemainingSeconds: room.timerDurationSeconds,
      votes: {},
      players: updatedPlayers,
    );
    _notify(code);
  }

  @override
  Future<void> submitVote({
    required String roomCode,
    required String votingPlayerId,
    required bool passed,
  }) async {
    final code = roomCode.toUpperCase();
    final room = _activeRooms[code];
    if (room == null) return;

    final updatedVotes = Map<String, bool>.from(room.votes);
    updatedVotes[votingPlayerId] = passed;

    _activeRooms[code] = room.copyWith(votes: updatedVotes);
    _notify(code);
  }

  @override
  Future<void> completeTurn({
    required String roomCode,
    required bool passed,
  }) async {
    final code = roomCode.toUpperCase();
    final room = _activeRooms[code];
    if (room == null || room.currentTurnPlayerId == null) return;

    final player = room.players[room.currentTurnPlayerId!];
    if (player == null) return;

    final updatedPlayers = Map<String, Player>.from(room.players);
    updatedPlayers[player.id] = passed
        ? player.copyWith(score: player.score + 10)
        : player.copyWith(penalties: player.penalties + 1);

    final roundRecord = RoundHistory(
      roundNumber: room.roundNumber,
      selectedPlayerId: player.id,
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
      completedTimestamp: DateTime.now().millisecondsSinceEpoch,
    );

    final updatedRounds = List<RoundHistory>.from(room.roundsHistory)..add(roundRecord);

    _activeRooms[code] = room.copyWith(
      status: RoomStatus.roundSummary,
      players: updatedPlayers,
      roundsHistory: updatedRounds,
    );
    _notify(code);
  }

  @override
  Future<void> nextRound({
    required String roomCode,
  }) async {
    final code = roomCode.toUpperCase();
    final room = _activeRooms[code];
    if (room == null) return;

    _activeRooms[code] = room.copyWith(
      status: RoomStatus.spinning,
      roundNumber: room.roundNumber + 1,
      currentTurnPlayerId: null,
      currentPrompt: null,
      currentTurnType: null,
      votes: {},
    );
    _notify(code);
  }

  @override
  Future<void> addBotPlayer({
    required String roomCode,
    required String botName,
  }) async {
    final code = roomCode.toUpperCase();
    final room = _activeRooms[code];
    if (room == null) return;

    final botId = 'bot_${DateTime.now().millisecondsSinceEpoch % 10000}';
    final emojis = ['🤖', '🦄', '🦁', '🎭', '⚡', '🔥'];
    final colors = [0xFFEC4899, 0xFF06B6D4, 0xFFF59E0B, 0xFF10B981, 0xFF6366F1];
    final rand = Random();

    final bot = Player(
      id: botId,
      name: botName,
      avatarEmoji: emojis[rand.nextInt(emojis.length)],
      colorValue: colors[rand.nextInt(colors.length)],
      isHost: false,
      isReady: true,
      score: 0,
      penalties: 0,
    );

    final updatedPlayers = Map<String, Player>.from(room.players);
    updatedPlayers[botId] = bot;

    _activeRooms[code] = room.copyWith(players: updatedPlayers);
    _notify(code);
  }

  @override
  Future<void> returnToLobby({
    required String roomCode,
  }) async {
    final code = roomCode.toUpperCase();
    final room = _activeRooms[code];
    if (room == null) return;

    _activeRooms[code] = room.copyWith(
      status: RoomStatus.lobby,
      currentTurnPlayerId: null,
      currentPrompt: null,
      currentTurnType: null,
      votes: {},
    );
    _notify(code);
  }
}
