import 'prompt_model.dart';

class RoundHistory {
  final int roundNumber;
  final String selectedPlayerId;
  final String selectedPlayerName;
  final double spinTargetAngle;
  final int spinTimestamp;
  final PromptType? choiceType;
  final String? promptId;
  final String? promptText;
  final String? promptCategory;
  final IntensityLevel? promptIntensity;
  final String? submittedByPlayerName;
  final bool isCompleted;
  final int pointsAwarded;
  final int forfeitsAwarded;
  final int completedTimestamp;

  const RoundHistory({
    required this.roundNumber,
    required this.selectedPlayerId,
    required this.selectedPlayerName,
    required this.spinTargetAngle,
    required this.spinTimestamp,
    this.choiceType,
    this.promptId,
    this.promptText,
    this.promptCategory,
    this.promptIntensity,
    this.submittedByPlayerName,
    this.isCompleted = false,
    this.pointsAwarded = 0,
    this.forfeitsAwarded = 0,
    this.completedTimestamp = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'roundNumber': roundNumber,
      'selectedPlayerId': selectedPlayerId,
      'selectedPlayerName': selectedPlayerName,
      'spinTargetAngle': spinTargetAngle,
      'spinTimestamp': spinTimestamp,
      'choiceType': choiceType?.name,
      'promptId': promptId,
      'promptText': promptText,
      'promptCategory': promptCategory,
      'promptIntensity': promptIntensity?.name,
      'submittedByPlayerName': submittedByPlayerName,
      'isCompleted': isCompleted,
      'pointsAwarded': pointsAwarded,
      'forfeitsAwarded': forfeitsAwarded,
      'completedTimestamp': completedTimestamp,
    };
  }

  factory RoundHistory.fromMap(Map<String, dynamic> map) {
    return RoundHistory(
      roundNumber: (map['roundNumber'] as num?)?.toInt() ?? 1,
      selectedPlayerId: map['selectedPlayerId'] as String? ?? '',
      selectedPlayerName: map['selectedPlayerName'] as String? ?? '',
      spinTargetAngle: (map['spinTargetAngle'] as num?)?.toDouble() ?? 0.0,
      spinTimestamp: (map['spinTimestamp'] as num?)?.toInt() ?? 0,
      choiceType: map['choiceType'] == 'dare'
          ? PromptType.dare
          : (map['choiceType'] == 'truth' ? PromptType.truth : null),
      promptId: map['promptId'] as String?,
      promptText: map['promptText'] as String?,
      promptCategory: map['promptCategory'] as String?,
      promptIntensity: _parseIntensity(map['promptIntensity'] as String?),
      submittedByPlayerName: map['submittedByPlayerName'] as String?,
      isCompleted: map['isCompleted'] as bool? ?? false,
      pointsAwarded: (map['pointsAwarded'] as num?)?.toInt() ?? 0,
      forfeitsAwarded: (map['forfeitsAwarded'] as num?)?.toInt() ?? 0,
      completedTimestamp: (map['completedTimestamp'] as num?)?.toInt() ?? 0,
    );
  }

  static IntensityLevel? _parseIntensity(String? val) {
    if (val == null) return null;
    for (var i in IntensityLevel.values) {
      if (i.name == val) return i;
    }
    return IntensityLevel.mild;
  }
}
