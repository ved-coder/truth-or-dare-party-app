import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_room_model.dart';
import '../models/prompt_model.dart';
import '../services/game_manager.dart';
import '../theme/game_theme.dart';
import '../widgets/neon_button.dart';
import '../widgets/player_avatar.dart';
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
  bool _showSettings = false;

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

  void _addBotPlayer() async {
    const botNames = ['max', 'alex', 'sam', 'zoe', 'leo', 'mia'];
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
        backgroundColor: GameTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
            onPressed: _leaveRoom,
          ),
          actions: [
            IconButton(
              icon: Icon(
                _showSettings ? Icons.tune : Icons.tune_outlined,
                color: GameTheme.neonLavender,
              ),
              tooltip: 'Game Settings',
              onPressed: () => setState(() => _showSettings = !_showSettings),
            ),
          ],
        ),
        body: StreamBuilder<GameRoom?>(
          stream: GameManager().service.streamRoom(widget.roomCode),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: GameTheme.primaryPurple),
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

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: ROOM CODE + Large Code (PDF Page 1)
                    const Text(
                      'ROOM CODE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: GameTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          room.roomCode,
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: GameTheme.neonLavender,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: Colors.white54, size: 22),
                          onPressed: _copyRoomCode,
                          tooltip: 'Copy Code',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Players Card Container (PDF Page 1)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: GameTheme.cardBox(radius: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Players (${players.length})',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: GameTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (isHost)
                                        GestureDetector(
                                          onTap: _addBotPlayer,
                                          child: const Text(
                                            '+ Add Player',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: GameTheme.primaryPurple,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: players.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 16),
                                    itemBuilder: (context, index) {
                                      final p = players[index];
                                      final isMe = p.id == currentP?.id;
                                      return PlayerAvatar(
                                        player: p,
                                        size: 44,
                                        isHighlighted: isMe,
                                        showName: true,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Optional Host Settings drawer
                            if (_showSettings && isHost) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: GameTheme.cardBox(radius: 18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Question Intensity:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: GameTheme.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        _buildIntensityTab(
                                          label: 'Mild 😇',
                                          level: IntensityLevel.mild,
                                          current: room.intensityLevel,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildIntensityTab(
                                          label: 'Spicy 🌶️',
                                          level: IntensityLevel.spicy,
                                          current: room.intensityLevel,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildIntensityTab(
                                          label: 'Wild ⚡',
                                          level: IntensityLevel.extreme,
                                          current: room.intensityLevel,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bottom Action Buttons (PDF Page 1)
                    NeonButton(
                      text: 'Start Game',
                      primaryColor: GameTheme.primaryPurple,
                      onPressed: _startGame,
                    ),

                    const SizedBox(height: 12),

                    NeonButton(
                      text: 'Share Room Code',
                      isOutline: true,
                      onPressed: _copyRoomCode,
                    ),

                    const SizedBox(height: 12),
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
            color: selected ? GameTheme.primaryPurple.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? GameTheme.primaryPurple : Colors.white12,
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
