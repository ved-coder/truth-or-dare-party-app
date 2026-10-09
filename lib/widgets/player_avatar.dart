import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../theme/game_theme.dart';

class PlayerAvatar extends StatelessWidget {
  final Player player;
  final double size;
  final bool showName;
  final bool isHighlighted;
  final bool showScore;
  final VoidCallback? onTap;
  final bool useInitial;

  const PlayerAvatar({
    super.key,
    required this.player,
    this.size = 48,
    this.showName = true,
    this.isHighlighted = false,
    this.showScore = false,
    this.onTap,
    this.useInitial = true,
  });

  @override
  Widget build(BuildContext context) {
    final playerColor = Color(player.colorValue);
    final initial = player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P';
    final displayName = isHighlighted ? '${player.name} (You)' : player.name;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circle Avatar Container
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: playerColor,
              border: isHighlighted
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: Center(
              child: useInitial
                  ? Text(
                      initial,
                      style: TextStyle(
                        fontSize: size * 0.45,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    )
                  : Text(
                      player.avatarEmoji,
                      style: TextStyle(fontSize: size * 0.48),
                    ),
            ),
          ),

          if (showName) ...[
            const SizedBox(width: 12),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),

            if (player.isHost) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: GameTheme.neonAmber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'HOST',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],

          if (showScore) ...[
            const SizedBox(width: 8),
            Text(
              '${player.score} pts',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
