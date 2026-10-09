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

  const PlayerAvatar({
    super.key,
    required this.player,
    this.size = 56,
    this.showName = true,
    this.isHighlighted = false,
    this.showScore = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final playerColor = Color(player.colorValue);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Outer glow if highlighted
              if (isHighlighted)
                Container(
                  width: size + 16,
                  height: size + 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: GameTheme.neonPink.withValues(alpha: 0.8),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),

              // Avatar circle
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      playerColor,
                      playerColor.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isHighlighted ? Colors.white : Colors.white.withValues(alpha: 0.4),
                    width: isHighlighted ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: playerColor.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    player.avatarEmoji,
                    style: TextStyle(fontSize: size * 0.48),
                  ),
                ),
              ),

              // Host crown badge
              if (player.isHost)
                Positioned(
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: GameTheme.neonAmber,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: GameTheme.neonAmber.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Text(
                      '👑',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),

              // Ready status indicator
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: size * 0.32,
                  height: size * 0.32,
                  decoration: BoxDecoration(
                    color: player.isReady ? GameTheme.neonGreen : Colors.grey.shade700,
                    shape: BoxShape.circle,
                    border: Border.all(color: GameTheme.surface, width: 2),
                  ),
                  child: Icon(
                    player.isReady ? Icons.check : Icons.hourglass_empty,
                    size: size * 0.18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          if (showName) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: size + 24,
              child: Text(
                player.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                  color: isHighlighted ? Colors.white : GameTheme.textSecondary,
                ),
              ),
            ),
          ],

          if (showScore) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: GameTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                '★ ${player.score}  ⚡ ${player.penalties}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
