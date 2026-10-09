import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/game_room_model.dart';
import '../models/player_model.dart';
import '../models/prompt_model.dart';
import '../services/game_manager.dart';
import '../theme/game_theme.dart';
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

  // Wager & Reaction state
  double _wagerAmount = 40;
  String? _selectedWagerOption;
  String? _selectedRating;

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
      _selectedWagerOption = null;
      _selectedRating = null;
    });
    await GameManager().service.nextRound(roomCode: widget.roomCode);
  }

  void _leaveRoom() async {
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
  }

  @override
  Widget build(BuildContext context) {
    final currentP = GameManager().currentPlayer;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leaveRoom();
      },
      child: Scaffold(
        backgroundColor: GameTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
            onPressed: _leaveRoom,
          ),
        ),
        body: Stack(
          children: [
            SafeArea(
              child: StreamBuilder<GameRoom?>(
                stream: GameManager().service.streamRoom(widget.roomCode),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: GameTheme.primaryPurple),
                    );
                  }

                  final room = snapshot.data!;

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

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (room.status == RoomStatus.spinning || room.currentPrompt == null)
                                  _buildWheelStage(room, isHost, activePlayer)
                                else if (room.status == RoomStatus.performing && room.currentPrompt?.type == PromptType.truth)
                                  _buildTruthStage(room, activePlayer, isMyTurn)
                                else if (room.status == RoomStatus.performing && room.currentPrompt?.type == PromptType.dare)
                                  _buildDareStage(room, activePlayer, isMyTurn)
                                else if (room.status == RoomStatus.roundSummary)
                                  _buildRateAndScoreStage(room, activePlayer),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Confetti Overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  GameTheme.neonPink,
                  GameTheme.neonGreen,
                  GameTheme.neonAmber,
                  GameTheme.primaryPurple,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STAGE 1 & 2: WHEEL / VOTE (PDF Page 2 & Page 3) ---
  Widget _buildWheelStage(GameRoom room, bool isHost, Player? activePlayer) {
    final showVoteStage = activePlayer != null;

    if (showVoteStage) {
      // PDF Page 3: Step 2 Vote
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GameTheme.buildStepBadge('2', 'Vote'),
          const SizedBox(height: 36),

          Center(
            child: Column(
              children: [
                PlayerAvatar(
                  player: activePlayer,
                  size: 80,
                  showName: false,
                ),
                const SizedBox(height: 16),
                Text(
                  '${activePlayer.name} was picked',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Vote for their round',
                  style: TextStyle(
                    fontSize: 14,
                    color: GameTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 36),

                // Choice Cards: Truth & Dare (PDF Page 3)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectChoice(PromptType.truth),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: GameTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: GameTheme.neonGreen, width: 1.5),
                          ),
                          child: const Center(
                            child: Text(
                              'Truth',
                              style: TextStyle(
                                color: GameTheme.neonGreen,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectChoice(PromptType.dare),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: GameTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: GameTheme.neonPink, width: 1.5),
                          ),
                          child: const Center(
                            child: Text(
                              'Dare',
                              style: TextStyle(
                                color: GameTheme.neonPink,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                Text(
                  '${room.playerList.length > 2 ? room.playerList.length - 1 : 1} of ${room.playerList.length} players voted',
                  style: const TextStyle(
                    fontSize: 13,
                    color: GameTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // PDF Page 2: Step 1 Wheel
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameTheme.buildStepBadge('1', 'Wheel'),
        const SizedBox(height: 30),

        Center(
          child: Column(
            children: [
              SpinWheelWidget(
                players: room.playerList,
                isHost: isHost,
                targetAngle: room.spinTargetAngle,
                spinTimestamp: room.spinTimestamp,
                onSpinTriggered: (chosen, angle) => _onSpinTriggered(chosen, angle),
                onSpinLanded: (landed) => _onSpinLanded(landed),
              ),

              const SizedBox(height: 36),

              const Text(
                'Waiting for host to spin...',
                style: TextStyle(
                  fontSize: 14,
                  color: GameTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- STAGE 4 TRUTH: WAGER (PDF Page 4) ---
  Widget _buildTruthStage(GameRoom room, Player? activePlayer, bool isMyTurn) {
    final prompt = room.currentPrompt!;
    final name = activePlayer?.name ?? 'Player';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameTheme.buildStepBadge('4', 'Truth'),
        const SizedBox(height: 24),

        // Prompt Card (PDF Page 4)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: GameTheme.cardBox(radius: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$name is answering',
                style: const TextStyle(
                  fontSize: 13,
                  color: GameTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '"${prompt.text}"',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Wager Section (PDF Page 4)
        Text(
          'Your wager: is $name telling the truth?',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedWagerOption = 'Truth'),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: _selectedWagerOption == 'Truth'
                        ? GameTheme.neonGreen.withValues(alpha: 0.2)
                        : GameTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: GameTheme.neonGreen,
                      width: _selectedWagerOption == 'Truth' ? 2 : 1.2,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Truth',
                      style: TextStyle(
                        color: GameTheme.neonGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedWagerOption = 'Half-Truth'),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: _selectedWagerOption == 'Half-Truth'
                        ? GameTheme.neonAmber.withValues(alpha: 0.2)
                        : GameTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: GameTheme.neonAmber,
                      width: _selectedWagerOption == 'Half-Truth' ? 2 : 1.2,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Half-Truth',
                      style: TextStyle(
                        color: GameTheme.neonAmber,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Slider (PDF Page 4)
        Row(
          children: [
            const Text(
              'Wager',
              style: TextStyle(
                fontSize: 13,
                color: GameTheme.textSecondary,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: GameTheme.neonLavender,
                  inactiveTrackColor: GameTheme.surfaceElevated,
                  thumbColor: GameTheme.neonLavender,
                  overlayColor: GameTheme.neonLavender.withValues(alpha: 0.2),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _wagerAmount,
                  min: 10,
                  max: 100,
                  divisions: 9,
                  onChanged: (val) => setState(() => _wagerAmount = val),
                ),
              ),
            ),
            Text(
              '${_wagerAmount.toInt()} pts',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: GameTheme.neonLavender,
              ),
            ),
          ],
        ),

        const SizedBox(height: 36),

        NeonButton(
          text: 'Lock In Wager',
          primaryColor: GameTheme.primaryPurple,
          onPressed: () => _completeTurn(true),
        ),
      ],
    );
  }

  // --- STAGE 4 DARE (PDF Page 5) ---
  Widget _buildDareStage(GameRoom room, Player? activePlayer, bool isMyTurn) {
    final prompt = room.currentPrompt!;
    final name = activePlayer?.name ?? 'Player';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameTheme.buildStepBadge('4', 'Dare'),
        const SizedBox(height: 24),

        // Prompt Card with Pink Border (PDF Page 5)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: GameTheme.cardBox(
            borderColor: GameTheme.neonPink,
            radius: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$name\'s dare',
                style: const TextStyle(
                  fontSize: 13,
                  color: GameTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '"${prompt.text}"',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(
          '$name is completing this now',
          style: const TextStyle(
            fontSize: 14,
            color: GameTheme.textSecondary,
          ),
        ),

        const SizedBox(height: 16),

        // Reaction Bar (PDF Page 5)
        Row(
          children: [
            const Text('😂', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            const Text('🔥', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            const Text('👏', style: TextStyle(fontSize: 22)),
            const Spacer(),
            const Text(
              'react',
              style: TextStyle(
                fontSize: 13,
                color: GameTheme.textSecondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 48),

        // Bottom Action Buttons (PDF Page 5)
        NeonButton(
          text: 'Mark Complete',
          primaryColor: GameTheme.neonPink,
          onPressed: () => _completeTurn(true),
        ),

        const SizedBox(height: 12),

        NeonButton(
          text: 'Skip (costs points)',
          isOutline: true,
          onPressed: () => _completeTurn(false),
        ),
      ],
    );
  }

  // --- STAGE 5 RATE & SCORE (PDF Page 6) ---
  Widget _buildRateAndScoreStage(GameRoom room, Player? activePlayer) {
    final name = activePlayer?.name ?? 'Player';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameTheme.buildStepBadge('5', 'Rate & Score'),
        const SizedBox(height: 24),

        Text(
          'How was $name\'s answer?',
          style: const TextStyle(
            fontSize: 14,
            color: GameTheme.textSecondary,
          ),
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: NeonButton(
                text: 'Good',
                primaryColor: GameTheme.neonGreen,
                isOutline: _selectedRating == 'Weak',
                onPressed: () => setState(() => _selectedRating = 'Good'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: NeonButton(
                text: 'Weak',
                primaryColor: GameTheme.surfaceElevated,
                isOutline: _selectedRating != 'Weak',
                onPressed: () => setState(() => _selectedRating = 'Weak'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // LEADERBOARD Card (PDF Page 6)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: GameTheme.cardBox(radius: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LEADERBOARD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: GameTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: room.playerList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final p = room.playerList[index];
                  final isMe = p.id == GameManager().currentPlayer?.id;
                  final initial = p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P';
                  final color = Color(p.colorValue);

                  return Row(
                    children: [
                      Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: GameTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isMe ? '${p.name} (You)' : p.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '🔥${p.penalties}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: GameTheme.neonAmber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${p.score}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 36),

        NeonButton(
          text: 'Next Round',
          primaryColor: GameTheme.primaryPurple,
          onPressed: _nextRound,
        ),
      ],
    );
  }
}
