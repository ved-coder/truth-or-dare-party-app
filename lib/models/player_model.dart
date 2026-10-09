class Player {
  final String id;
  final String name;
  final String avatarEmoji;
  final int colorValue;
  final bool isHost;
  final bool isReady;
  final int score;
  final int penalties; // Forfeit strikes
  final int truthsChosen;
  final int daresChosen;
  final int joinedTimestamp;

  const Player({
    required this.id,
    required this.name,
    this.avatarEmoji = '😎',
    this.colorValue = 0xFF8B5CF6,
    this.isHost = false,
    this.isReady = false,
    this.score = 0,
    this.penalties = 0,
    this.truthsChosen = 0,
    this.daresChosen = 0,
    this.joinedTimestamp = 0,
  });

  Player copyWith({
    String? id,
    String? name,
    String? avatarEmoji,
    int? colorValue,
    bool? isHost,
    bool? isReady,
    int? score,
    int? penalties,
    int? truthsChosen,
    int? daresChosen,
    int? joinedTimestamp,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      colorValue: colorValue ?? this.colorValue,
      isHost: isHost ?? this.isHost,
      isReady: isReady ?? this.isReady,
      score: score ?? this.score,
      penalties: penalties ?? this.penalties,
      truthsChosen: truthsChosen ?? this.truthsChosen,
      daresChosen: daresChosen ?? this.daresChosen,
      joinedTimestamp: joinedTimestamp ?? this.joinedTimestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarEmoji': avatarEmoji,
      'colorValue': colorValue,
      'isHost': isHost,
      'isReady': isReady,
      'score': score,
      'penalties': penalties,
      'truthsChosen': truthsChosen,
      'daresChosen': daresChosen,
      'joinedTimestamp': joinedTimestamp,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Player',
      avatarEmoji: map['avatarEmoji'] as String? ?? '😎',
      colorValue: map['colorValue'] as int? ?? 0xFF8B5CF6,
      isHost: map['isHost'] as bool? ?? false,
      isReady: map['isReady'] as bool? ?? false,
      score: map['score'] as int? ?? 0,
      penalties: map['penalties'] as int? ?? 0,
      truthsChosen: (map['truthsChosen'] as num?)?.toInt() ?? 0,
      daresChosen: (map['daresChosen'] as num?)?.toInt() ?? 0,
      joinedTimestamp: (map['joinedTimestamp'] as num?)?.toInt() ?? 0,
    );
  }
}
