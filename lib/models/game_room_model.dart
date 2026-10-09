import 'player_model.dart';
import 'prompt_model.dart';

enum RoomStatus {
  lobby,
  spinning,
  choosing,
  performing,
  voting,
  roundSummary,
}

class GameRoom {
  final String roomCode;
  final String hostId;
  final RoomStatus status;
  final Map<String, Player> players;
  final String? currentTurnPlayerId;
  final String? challengerPlayerId; // The player who assigned or spun
  final PromptType? currentTurnType;
  final PromptItem? currentPrompt;
  final double spinTargetAngle; // Synchronized spin angle in radians
  final int spinTimestamp; // Epoch millisecond to synchronize animation start
  final int roundNumber;
  final int timerDurationSeconds;
  final int timerRemainingSeconds;
  final IntensityLevel intensityLevel;
  final List<PromptItem> customPrompts;
  final Map<String, bool> votes; // playerId -> pass/fail

  const GameRoom({
    required this.roomCode,
    required this.hostId,
    this.status = RoomStatus.lobby,
    this.players = const {},
    this.currentTurnPlayerId,
    this.challengerPlayerId,
    this.currentTurnType,
    this.currentPrompt,
    this.spinTargetAngle = 0.0,
    this.spinTimestamp = 0,
    this.roundNumber = 1,
    this.timerDurationSeconds = 45,
    this.timerRemainingSeconds = 45,
    this.intensityLevel = IntensityLevel.spicy,
    this.customPrompts = const [],
    this.votes = const {},
  });

  Player? get hostPlayer => players[hostId];
  Player? get currentTurnPlayer =>
      currentTurnPlayerId != null ? players[currentTurnPlayerId] : null;
  List<Player> get playerList => players.values.toList();

  GameRoom copyWith({
    String? roomCode,
    String? hostId,
    RoomStatus? status,
    Map<String, Player>? players,
    String? currentTurnPlayerId,
    String? challengerPlayerId,
    PromptType? currentTurnType,
    PromptItem? currentPrompt,
    double? spinTargetAngle,
    int? spinTimestamp,
    int? roundNumber,
    int? timerDurationSeconds,
    int? timerRemainingSeconds,
    IntensityLevel? intensityLevel,
    List<PromptItem>? customPrompts,
    Map<String, bool>? votes,
  }) {
    return GameRoom(
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      status: status ?? this.status,
      players: players ?? this.players,
      currentTurnPlayerId: currentTurnPlayerId ?? this.currentTurnPlayerId,
      challengerPlayerId: challengerPlayerId ?? this.challengerPlayerId,
      currentTurnType: currentTurnType ?? this.currentTurnType,
      currentPrompt: currentPrompt ?? this.currentPrompt,
      spinTargetAngle: spinTargetAngle ?? this.spinTargetAngle,
      spinTimestamp: spinTimestamp ?? this.spinTimestamp,
      roundNumber: roundNumber ?? this.roundNumber,
      timerDurationSeconds:
          timerDurationSeconds ?? this.timerDurationSeconds,
      timerRemainingSeconds:
          timerRemainingSeconds ?? this.timerRemainingSeconds,
      intensityLevel: intensityLevel ?? this.intensityLevel,
      customPrompts: customPrompts ?? this.customPrompts,
      votes: votes ?? this.votes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomCode': roomCode,
      'hostId': hostId,
      'status': status.name,
      'players': players.map((k, v) => MapEntry(k, v.toMap())),
      'currentTurnPlayerId': currentTurnPlayerId,
      'challengerPlayerId': challengerPlayerId,
      'currentTurnType': currentTurnType?.name,
      'currentPrompt': currentPrompt?.toMap(),
      'spinTargetAngle': spinTargetAngle,
      'spinTimestamp': spinTimestamp,
      'roundNumber': roundNumber,
      'timerDurationSeconds': timerDurationSeconds,
      'timerRemainingSeconds': timerRemainingSeconds,
      'intensityLevel': intensityLevel.name,
      'customPrompts': customPrompts.map((p) => p.toMap()).toList(),
      'votes': votes,
    };
  }

  factory GameRoom.fromMap(Map<String, dynamic> map) {
    Map<String, Player> parsedPlayers = {};
    if (map['players'] is Map) {
      (map['players'] as Map).forEach((k, v) {
        if (v is Map) {
          parsedPlayers[k.toString()] =
              Player.fromMap(Map<String, dynamic>.from(v));
        }
      });
    }

    List<PromptItem> parsedCustomPrompts = [];
    if (map['customPrompts'] is List) {
      for (var p in (map['customPrompts'] as List)) {
        if (p is Map) {
          parsedCustomPrompts
              .add(PromptItem.fromMap(Map<String, dynamic>.from(p)));
        }
      }
    }

    Map<String, bool> parsedVotes = {};
    if (map['votes'] is Map) {
      (map['votes'] as Map).forEach((k, v) {
        if (v is bool) {
          parsedVotes[k.toString()] = v;
        }
      });
    }

    return GameRoom(
      roomCode: map['roomCode'] as String? ?? '',
      hostId: map['hostId'] as String? ?? '',
      status: _parseStatus(map['status'] as String?),
      players: parsedPlayers,
      currentTurnPlayerId: map['currentTurnPlayerId'] as String?,
      challengerPlayerId: map['challengerPlayerId'] as String?,
      currentTurnType: map['currentTurnType'] == 'dare'
          ? PromptType.dare
          : (map['currentTurnType'] == 'truth' ? PromptType.truth : null),
      currentPrompt: map['currentPrompt'] is Map
          ? PromptItem.fromMap(
              Map<String, dynamic>.from(map['currentPrompt'] as Map))
          : null,
      spinTargetAngle: (map['spinTargetAngle'] as num?)?.toDouble() ?? 0.0,
      spinTimestamp: (map['spinTimestamp'] as num?)?.toInt() ?? 0,
      roundNumber: (map['roundNumber'] as num?)?.toInt() ?? 1,
      timerDurationSeconds:
          (map['timerDurationSeconds'] as num?)?.toInt() ?? 45,
      timerRemainingSeconds:
          (map['timerRemainingSeconds'] as num?)?.toInt() ?? 45,
      intensityLevel: _parseIntensity(map['intensityLevel'] as String?),
      customPrompts: parsedCustomPrompts,
      votes: parsedVotes,
    );
  }

  static RoomStatus _parseStatus(String? val) {
    for (var s in RoomStatus.values) {
      if (s.name == val) return s;
    }
    return RoomStatus.lobby;
  }

  static IntensityLevel _parseIntensity(String? val) {
    for (var i in IntensityLevel.values) {
      if (i.name == val) return i;
    }
    return IntensityLevel.spicy;
  }
}
