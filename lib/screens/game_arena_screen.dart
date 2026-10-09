import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/game_room_model.dart';
import '../models/player_model.dart';
import '../models/prompt_model.dart';
import '../services/game_manager.dart';
import '../theme/game_theme.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/neon_button.dart';
import '../widgets/player_avatar.dart';
import '../widgets/spin_wheel_widget.dart';
import 'lobby_screen.dart';

class GameArenaScreen extends StatefulWidget {
  final String roomCode;

  const GameArenaScreen({
    super.key,
    required this.roomCode,
  });

  @override
  State<GameArenaScreen> createState() => _GameArenaScreenState();
}

class _GameArenaScreenState extends State<GameArenaScreen> {
  late ConfettiController _confettiController;
  Player? _locallyLandedPlayer;
  bool _navigatingBack = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _onSpinTriggered(Player chosenPlayer, double finalAngle) async {
    setState(() {
      _locallyLandedPlayer = null;
    });
    await GameManager().service.spinWheel(
          roomCode: widget.roomCode,
          targetAngle: finalAngle,
          chosenPlayerId: chosenPlayer.id,
        );
  }

  void _onSpinLanded(Player landedPlayer) {
    setState(() {
      _locallyLandedPlayer = landedPlayer;
    });
  }

  void _selectChoice(PromptType type) async {
    await GameManager().service.selectPromptChoice(
          roomCode: widget.roomCode,
          type: type,
        );
  }

  void _completeTurn(bool passed) async {
    if (passed) {
      _confettiController.play();
    }
    await GameManager().service.completeTurn(
          roomCode: widget.roomCode,
          passed: passed,
        );
  }

  void _nextRound() async {
    setState(() {
      _locallyLandedPlayer = null;
    });
    await GameManager().service.nextRound(roomCode: widget.roomCode);
  }

  void _confirmQuitGame(bool isHost) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GameTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: Row(
          children: [
            Icon(
              isHost ? Icons.settings_power_rounded : Icons.logout_rounded,
              color: GameTheme.neonPink,
            ),
            const SizedBox(width: 10),
            Text(
              isHost ? 'End Game or Leave?' : 'Quit Game?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          isHost
              ? 'As the host, you can return all players back to the lobby or leave the party.'
              : 'Are you sure you want to quit? You will leave this party room.',
          style: const TextStyle(color: GameTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          if (isHost)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await GameManager().service.returnToLobby(roomCode: widget.roomCode);
              },
              child: const Text(
                'Back to Lobby',
                style: TextStyle(color: GameTheme.neonCyan, fontWeight: FontWeight.bold),
              ),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GameTheme.neonPink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final currentP = GameManager().currentPlayer;
              if (currentP != null) {
                await GameManager().service.leaveRoom(
                      roomCode: widget.roomCode,
                      playerId: currentP.id,
                    );
              }
              GameManager().setCurrentRoomCode(null);
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Quit Game', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showScoreboard(List<Player> players) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GameTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final sorted = List<Player>.from(players)
          ..sort((a, b) => b.score.compareTo(a.score));

        return Container(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.leaderboard_rounded, color: GameTheme.neonAmber, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'PARTY SCOREBOARD',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sorted.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final p = sorted[index];
                    final rankIcon = index == 0
                        ? '🥇'
                        : index == 1
                            ? '🥈'
                            : index == 2
                                ? '🥉'
                                : '#${index + 1}';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(rankIcon, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          PlayerAvatar(player: p, size: 38, showName: false),
                        ],
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: GameTheme.neonGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '★ ${p.score} pts',
                              style: const TextStyle(
                                color: GameTheme.neonGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: GameTheme.neonAmber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '⚡ ${p.penalties} forfeits',
                              style: const TextStyle(
                                color: GameTheme.neonAmber,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentP = GameManager().currentPlayer;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          // Trigger confirmation dialog
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: StreamBuilder<GameRoom?>(
                stream: GameManager().service.streamRoom(widget.roomCode),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: GameTheme.neonPurple),
                    );
                  }

                  final room = snapshot.data!;

                  // If host changed status back to lobby, return everyone to LobbyScreen
                  if (room.status == RoomStatus.lobby && !_navigatingBack) {
                    _navigatingBack = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LobbyScreen(roomCode: widget.roomCode),
                        ),
                      );
                    });
                  }

                  final isHost = currentP?.id == room.hostId;
                  final activePlayer = _locallyLandedPlayer ?? room.currentTurnPlayer;
                  final isMyTurn = currentP?.id == activePlayer?.id;
                  final isTurnPlayerBot = activePlayer != null && activePlayer.id.startsWith('bot_');

                  return Column(
                    children: [
                      // Top Clean App Bar
                      _buildHeader(room, isHost),

                      // Main Content Area
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Column(
                            children: [
                              if (room.currentPrompt == null)
                                _buildSpinStage(room, isHost, activePlayer, isMyTurn)
                              else if (room.status == RoomStatus.performing)
                                _buildPerformingStage(room, activePlayer, isMyTurn, isTurnPlayerBot, isHost)
                              else if (room.status == RoomStatus.roundSummary)
                                _buildSummaryStage(room),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Confetti Layer
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  GameTheme.neonPink,
                  GameTheme.neonCyan,
                  GameTheme.neonAmber,
                  GameTheme.neonPurple,
                  Colors.white,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(GameRoom room, bool isHost) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: GameTheme.surface,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GameTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ROUND ${room.roundNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: GameTheme.neonPurple,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '#${room.roomCode}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                ),
              ),
            ],
          ),

          Row(
            children: [
              // Scoreboard Button
              IconButton(
                icon: const Icon(Icons.leaderboard_rounded, color: GameTheme.neonAmber, size: 22),
                tooltip: 'Scoreboard',
                onPressed: () => _showScoreboard(room.playerList),
              ),

              // End Game / Quit Button
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: GameTheme.neonPink, size: 22),
                tooltip: isHost ? 'End Game / Lobby' : 'Quit Game',
                onPressed: () => _confirmQuitGame(isHost),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpinStage(
    GameRoom room,
    bool isHost,
    Player? activePlayer,
    bool isMyTurn,
  ) {
    return Column(
      children: [
        const SizedBox(height: 6),

        if (activePlayer == null) ...[
          const Text(
            'SPIN THE WHEEL',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: GameTheme.neonCyan,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Tap the center button to choose a player!',
            style: TextStyle(fontSize: 12, color: GameTheme.textSecondary),
          ),
        ] else ...[
          // Clean Player Turn Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: GameTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GameTheme.neonPurple.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(activePlayer.avatarEmoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Text(
                  '👉 It is ${activePlayer.name}\'s Turn!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Animated Roulette Wheel
        SpinWheelWidget(
          players: room.playerList,
          isHost: isHost,
          targetAngle: room.spinTargetAngle,
          spinTimestamp: room.spinTimestamp,
          onSpinTriggered: (chosen, angle) => _onSpinTriggered(chosen, angle),
          onSpinLanded: (landed) => _onSpinLanded(landed),
        ),

        const SizedBox(height: 20),

        // Turn Choice Buttons (Appear when the wheel has selected a player)
        if (activePlayer != null) ...[
          Text(
            isMyTurn
                ? 'Pick Truth or Dare:'
                : 'Waiting for ${activePlayer.name} to choose...',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: NeonButton(
                  text: 'TRUTH 💭',
                  primaryColor: GameTheme.neonCyan,
                  secondaryColor: const Color(0xFF0284C7),
                  onPressed: (isMyTurn || isHost)
                      ? () => _selectChoice(PromptType.truth)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeonButton(
                  text: 'DARE 🔥',
                  primaryColor: GameTheme.neonPink,
                  secondaryColor: const Color(0xFFE11D48),
                  onPressed: (isMyTurn || isHost)
                      ? () => _selectChoice(PromptType.dare)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPerformingStage(
    GameRoom room,
    Player? activePlayer,
    bool isMyTurn,
    bool isTurnPlayerBot,
    bool isHost,
  ) {
    final prompt = room.currentPrompt!;
    final isDare = prompt.type == PromptType.dare;
    final accentColor = isDare ? GameTheme.neonPink : GameTheme.neonCyan;

    return Column(
      children: [
        const SizedBox(height: 8),

        if (activePlayer != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PlayerAvatar(player: activePlayer, size: 40, showName: false),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activePlayer.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    isDare ? 'Facing the Dare' : 'Answering the Truth',
                    style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),

        const SizedBox(height: 16),

        // Countdown Timer
        CountdownTimerWidget(
          totalSeconds: room.timerDurationSeconds,
          onTimerExpired: () {},
        ),

        const SizedBox(height: 16),

        // Clean Prompt Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: GameTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isDare ? '🔥 DARE' : '💭 TRUTH',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      prompt.intensity.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                prompt.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),

              if (prompt.submittedByPlayerName != null) ...[
                const SizedBox(height: 14),
                Text(
                  'Card created by: ${prompt.submittedByPlayerName}',
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Clean Decent Action Buttons (Completed vs Forfeit)
        if (isMyTurn || isHost || isTurnPlayerBot) ...[
          NeonButton(
            text: 'COMPLETED! (+10 PTS) 🎉',
            icon: Icons.check_circle_outline,
            primaryColor: GameTheme.neonGreen,
            secondaryColor: const Color(0xFF059669),
            onPressed: () => _completeTurn(true),
          ),
          const SizedBox(height: 10),
          NeonButton(
            text: 'PASS / TAKE FORFEIT STRIKE (+1) ⚡',
            icon: Icons.flash_on_rounded,
            primaryColor: GameTheme.neonAmber,
            secondaryColor: const Color(0xFFD97706),
            onPressed: () => _completeTurn(false),
          ),
        ] else ...[
          const Text(
            'Waiting for player to complete their challenge...',
            style: TextStyle(color: GameTheme.textSecondary, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryStage(GameRoom room) {
    final activePlayer = room.currentTurnPlayer;

    return Column(
      children: [
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: GameTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              const Text('✨', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 8),
              Text(
                'Round ${room.roundNumber} Finished!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              if (activePlayer != null)
                Text(
                  '${activePlayer.name} has ${activePlayer.score} Points and ${activePlayer.penalties} Forfeit Strikes',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GameTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        NeonButton(
          text: 'NEXT ROUND 🎡',
          icon: Icons.arrow_forward_rounded,
          primaryColor: GameTheme.neonPurple,
          onPressed: _nextRound,
        ),
      ],
    );
  }
}
