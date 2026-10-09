import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_room_model.dart';
import '../models/prompt_model.dart';
import '../services/game_manager.dart';
import '../theme/game_theme.dart';
import '../widgets/neon_button.dart';
import '../widgets/player_avatar.dart';
import 'add_prompt_dialog.dart';
import 'game_arena_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String roomCode;

  const LobbyScreen({
    super.key,
    required this.roomCode,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  bool _navigatedToGame = false;

  void _copyRoomCode() {
    Clipboard.setData(ClipboardData(text: widget.roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room Code "${widget.roomCode}" copied to clipboard!'),
        backgroundColor: GameTheme.surfaceElevated,
        duration: const Duration(seconds: 2),
      ),
    );
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
    if (mounted) Navigator.pop(context);
  }

  void _toggleReady(bool currentReady) async {
    final currentP = GameManager().currentPlayer;
    if (currentP != null) {
      await GameManager().service.toggleReady(
            roomCode: widget.roomCode,
            playerId: currentP.id,
            isReady: !currentReady,
          );
    }
  }

  void _addBotPlayer() async {
    const botNames = ['Alex', 'Mia', 'CyberSam', 'Zoe', 'Leo', 'Nova'];
    final name = botNames[DateTime.now().millisecond % botNames.length];
    await GameManager().service.addBotPlayer(
          roomCode: widget.roomCode,
          botName: name,
        );
  }

  void _startGame() async {
    await GameManager().service.startGame(roomCode: widget.roomCode);
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
            onPressed: _leaveRoom,
          ),
          title: const Text(
            'PARTY LOBBY',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: GameTheme.neonPink),
              tooltip: 'Leave Room',
              onPressed: _leaveRoom,
            ),
          ],
        ),
        body: StreamBuilder<GameRoom?>(
          stream: GameManager().service.streamRoom(widget.roomCode),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: GameTheme.neonPurple),
              );
            }

            final room = snapshot.data;
            if (room == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Room was closed or not found.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    NeonButton(
                      text: 'Back to Home',
                      isFullWidth: false,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            }

            // Auto-navigate to game arena when game starts
            if (room.status != RoomStatus.lobby && !_navigatedToGame) {
              _navigatedToGame = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameArenaScreen(roomCode: widget.roomCode),
                  ),
                );
              });
            }

            final isHost = currentP?.id == room.hostId;
            final players = room.playerList;
            final myPlayer = currentP != null ? room.players[currentP.id] : null;
            final canStart = isHost && players.length >= 2;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Room Code Hero Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: GameTheme.glassBox(
                        borderColor: GameTheme.neonCyan,
                        radius: 20,
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'ROOM CODE • SHARE WITH FRIENDS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: GameTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                room.roomCode,
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 6,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 14),
                              IconButton(
                                icon: const Icon(Icons.copy, color: GameTheme.neonCyan),
                                tooltip: 'Copy Room Code',
                                onPressed: _copyRoomCode,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${players.length} Players in Lobby',
                            style: const TextStyle(
                              color: GameTheme.neonGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Players Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PLAYERS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: Colors.white70,
                          ),
                        ),
                        // Bot button for easy solo testing
                        GestureDetector(
                          onTap: _addBotPlayer,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: GameTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: GameTheme.neonPurple.withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.smart_toy_outlined, size: 14, color: GameTheme.neonPurple),
                                SizedBox(width: 4),
                                Text(
                                  '+ Add Bot',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: GameTheme.neonPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Players Grid
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: GameTheme.surfaceElevated.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 18,
                        alignment: WrapAlignment.center,
                        children: players.map((p) {
                          final isMe = p.id == currentP?.id;
                          return PlayerAvatar(
                            player: p,
                            size: 64,
                            isHighlighted: isMe,
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Host Settings Section
                    if (isHost) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'HOST SETTINGS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Intensity Selector
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: GameTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Question Spiciness:',
                              style: TextStyle(fontSize: 12, color: GameTheme.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildIntensityTab(
                                  label: 'Mild 😇',
                                  level: IntensityLevel.mild,
                                  current: room.intensityLevel,
                                  color: GameTheme.neonGreen,
                                ),
                                const SizedBox(width: 8),
                                _buildIntensityTab(
                                  label: 'Spicy 🌶️',
                                  level: IntensityLevel.spicy,
                                  current: room.intensityLevel,
                                  color: GameTheme.neonAmber,
                                ),
                                const SizedBox(width: 8),
                                _buildIntensityTab(
                                  label: 'Wild ⚡',
                                  level: IntensityLevel.extreme,
                                  current: room.intensityLevel,
                                  color: GameTheme.neonPink,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Custom Cards Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: GameTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.style_outlined, color: GameTheme.neonAmber, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Custom Cards: ${room.customPrompts.length}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              AddPromptDialog.show(
                                context,
                                playerName: myPlayer?.name ?? 'Player',
                                onPromptCreated: (prompt) {
                                  GameManager().service.addCustomPrompt(
                                        roomCode: widget.roomCode,
                                        prompt: prompt,
                                      );
                                },
                              );
                            },
                            child: const Text(
                              '+ Add Card',
                              style: TextStyle(
                                color: GameTheme.neonCyan,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Ready Toggle & Start Game Buttons
                    if (myPlayer != null && !isHost)
                      NeonButton(
                        text: myPlayer.isReady ? 'YOU ARE READY! ✓' : 'READY UP',
                        icon: myPlayer.isReady ? Icons.check_circle : Icons.radio_button_unchecked,
                        primaryColor: myPlayer.isReady ? GameTheme.neonGreen : GameTheme.neonPurple,
                        onPressed: () => _toggleReady(myPlayer.isReady),
                      ),

                    if (isHost)
                      Column(
                        children: [
                          NeonButton(
                            text: canStart ? 'START THE PARTY! 🚀' : 'WAITING FOR 2+ PLAYERS',
                            icon: Icons.play_arrow_rounded,
                            primaryColor: canStart ? GameTheme.neonPink : Colors.grey.shade800,
                            secondaryColor: canStart ? GameTheme.neonPurple : null,
                            onPressed: canStart ? _startGame : null,
                          ),
                          if (!canStart) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Tip: Tap "+ Add Bot" above to test the game right now!',
                              style: TextStyle(
                                fontSize: 11,
                                color: GameTheme.neonAmber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIntensityTab({
    required String label,
    required IntensityLevel level,
    required IntensityLevel current,
    required Color color,
  }) {
    final selected = current == level;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          GameManager().service.updateSettings(
                roomCode: widget.roomCode,
                intensity: level,
              );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Colors.white12,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : GameTheme.textSecondary,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
