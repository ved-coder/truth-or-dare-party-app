import '../models/game_room_model.dart';
import '../models/player_model.dart';
import '../models/prompt_model.dart';

abstract class GameService {
  Stream<GameRoom?> streamRoom(String roomCode);

  Future<GameRoom> createRoom({
    required Player hostPlayer,
    IntensityLevel intensity = IntensityLevel.spicy,
  });

  Future<GameRoom?> joinRoom({
    required String roomCode,
    required Player player,
  });

  Future<void> leaveRoom({
    required String roomCode,
    required String playerId,
  });

  Future<void> toggleReady({
    required String roomCode,
    required String playerId,
    required bool isReady,
  });

  Future<void> updateSettings({
    required String roomCode,
    IntensityLevel? intensity,
    int? timerDurationSeconds,
  });

  Future<void> addCustomPrompt({
    required String roomCode,
    required PromptItem prompt,
  });

  Future<void> startGame({
    required String roomCode,
  });

  Future<void> spinWheel({
    required String roomCode,
    required double targetAngle,
    required String chosenPlayerId,
  });

  Future<void> selectPromptChoice({
    required String roomCode,
    required PromptType type,
  });

  Future<void> submitVote({
    required String roomCode,
    required String votingPlayerId,
    required bool passed,
  });

  Future<void> completeTurn({
    required String roomCode,
    required bool passed,
  });

  Future<void> nextRound({
    required String roomCode,
  });

  Future<void> addBotPlayer({
    required String roomCode,
    required String botName,
  });

  Future<void> returnToLobby({
    required String roomCode,
  });

  bool get isConnectedToFirebase;
}
