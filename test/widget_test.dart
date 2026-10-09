import 'package:flutter_test/flutter_test.dart';
import 'package:truth_or_dare_app/models/player_model.dart';
import 'package:truth_or_dare_app/models/game_room_model.dart';
import 'package:truth_or_dare_app/models/prompt_model.dart';
import 'package:truth_or_dare_app/services/prompt_repository.dart';

void main() {
  test('Player model serialization test', () {
    const player = Player(
      id: 'p1',
      name: 'Tester',
      avatarEmoji: '🔥',
      colorValue: 0xFF8B5CF6,
      isHost: true,
      score: 20,
      penalties: 1,
    );

    final map = player.toMap();
    final restored = Player.fromMap(map);

    expect(restored.id, 'p1');
    expect(restored.name, 'Tester');
    expect(restored.isHost, true);
    expect(restored.score, 20);
    expect(restored.penalties, 1);
  });

  test('GameRoom model and PromptRepository test', () {
    final truth = PromptRepository.getRandomPrompt(type: PromptType.truth);
    expect(truth.type, PromptType.truth);
    expect(truth.text.isNotEmpty, true);

    final dare = PromptRepository.getRandomPrompt(type: PromptType.dare);
    expect(dare.type, PromptType.dare);
    expect(dare.text.isNotEmpty, true);

    const room = GameRoom(
      roomCode: 'XYZ123',
      hostId: 'p1',
      status: RoomStatus.lobby,
    );

    final map = room.toMap();
    final restored = GameRoom.fromMap(map);
    expect(restored.roomCode, 'XYZ123');
    expect(restored.hostId, 'p1');
    expect(restored.status, RoomStatus.lobby);
  });
}
