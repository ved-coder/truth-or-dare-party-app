enum PromptType { truth, dare }

enum IntensityLevel { mild, spicy, extreme }

class PromptItem {
  final String id;
  final String text;
  final PromptType type;
  final IntensityLevel intensity;
  final String category;
  final String? submittedByPlayerName;

  const PromptItem({
    required this.id,
    required this.text,
    required this.type,
    this.intensity = IntensityLevel.mild,
    this.category = 'General',
    this.submittedByPlayerName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'type': type.name,
      'intensity': intensity.name,
      'category': category,
      if (submittedByPlayerName != null) 'submittedByPlayerName': submittedByPlayerName,
    };
  }

  factory PromptItem.fromMap(Map<String, dynamic> map) {
    return PromptItem(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
      type: (map['type'] == 'dare') ? PromptType.dare : PromptType.truth,
      intensity: _parseIntensity(map['intensity'] as String?),
      category: map['category'] as String? ?? 'General',
      submittedByPlayerName: map['submittedByPlayerName'] as String?,
    );
  }

  static IntensityLevel _parseIntensity(String? val) {
    switch (val) {
      case 'spicy':
        return IntensityLevel.spicy;
      case 'extreme':
        return IntensityLevel.extreme;
      case 'mild':
      default:
        return IntensityLevel.mild;
    }
  }
}
