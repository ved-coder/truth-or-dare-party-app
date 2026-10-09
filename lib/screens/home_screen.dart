import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../models/prompt_model.dart';
import '../services/game_manager.dart';
import '../theme/game_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/neon_button.dart';
import '../widgets/firebase_guide_modal.dart';
import 'lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  String _selectedEmoji = '😎';
  int _selectedColorValue = 0xFF8B5CF6;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(_glowController);

    final player = GameManager().currentPlayer;
    if (player != null) {
      _nameController.text = player.name;
      _selectedEmoji = player.avatarEmoji;
      _selectedColorValue = player.colorValue;
    } else {
      _nameController.text = 'Player_${DateTime.now().millisecond % 1000}';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomCodeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final existing = GameManager().currentPlayer;
    final updated = (existing ?? const Player(id: '1', name: 'Player')).copyWith(
      name: name,
      avatarEmoji: _selectedEmoji,
      colorValue: _selectedColorValue,
    );
    await GameManager().savePlayerProfile(updated);
  }

  Future<void> _createRoom() async {
    await _updateProfile();
    setState(() => _isLoading = true);

    try {
      final player = GameManager().currentPlayer!;
      final newRoom = await GameManager().service.createRoom(
        hostPlayer: player,
        intensity: IntensityLevel.spicy,
      );

      GameManager().setCurrentRoomCode(newRoom.roomCode);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LobbyScreen(roomCode: newRoom.roomCode),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create room: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinRoom(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a room code!')),
      );
      return;
    }

    await _updateProfile();
    setState(() => _isLoading = true);

    try {
      final player = GameManager().currentPlayer!;
      final room = await GameManager().service.joinRoom(
        roomCode: cleanCode,
        player: player,
      );

      if (room == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room not found! Check code and try again.')),
        );
        return;
      }

      GameManager().setCurrentRoomCode(cleanCode);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LobbyScreen(roomCode: cleanCode),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join room: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showJoinRoomDialog() {
    _roomCodeController.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GameTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: GameTheme.primaryPurple, width: 1.5),
        ),
        title: const Text(
          'Enter Room Code',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the 6-character room code from your friends to join their party lobby:',
              style: TextStyle(fontSize: 13, color: GameTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roomCodeController,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: GameTheme.neonLavender,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. 7X9K2M',
                hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 2),
                filled: true,
                fillColor: GameTheme.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          NeonButton(
            text: 'Join Lobby',
            isFullWidth: false,
            primaryColor: GameTheme.royalPurple,
            secondaryColor: GameTheme.primaryPurple,
            onPressed: () {
              final code = _roomCodeController.text;
              Navigator.pop(context);
              _joinRoom(code);
            },
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: GameTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Your Avatar & Color',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('Avatar Emoji:', style: TextStyle(color: GameTheme.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: GameTheme.availableEmojis.map((emoji) {
                  final isSelected = _selectedEmoji == emoji;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() => _selectedEmoji = emoji);
                      setState(() => _selectedEmoji = emoji);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? GameTheme.primaryPurple.withValues(alpha: 0.3) : GameTheme.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? GameTheme.primaryPurple : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text('Theme Glow Color:', style: TextStyle(color: GameTheme.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: GameTheme.playerColors.map((color) {
                  final isSelected = _selectedColorValue == color.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      setModalState(() => _selectedColorValue = color.toARGB32());
                      setState(() => _selectedColorValue = color.toARGB32());
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              NeonButton(
                text: 'Save Avatar',
                primaryColor: GameTheme.royalPurple,
                onPressed: () {
                  _updateProfile();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFirebase = GameManager().isFirebaseActive;

    return Scaffold(
      backgroundColor: GameTheme.pureBlack,
      body: AmbientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Bar with Firebase Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: GameTheme.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: GameTheme.primaryPurple.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('✨', style: TextStyle(fontSize: 12)),
                          SizedBox(width: 6),
                          Text(
                            'PARTY ARENA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: GameTheme.neonLavender,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Firebase Status Badge (Clickable for setup guide)
                    GestureDetector(
                      onTap: () => FirebaseGuideModal.show(context, isConnected: isFirebase),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: (isFirebase ? GameTheme.neonGreen : GameTheme.scoreAmber).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isFirebase ? GameTheme.neonGreen : GameTheme.scoreAmber,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFirebase ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                              size: 14,
                              color: isFirebase ? GameTheme.neonGreen : GameTheme.scoreAmber,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isFirebase ? 'Firebase Live' : 'Demo Mode (Guide)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isFirebase ? GameTheme.neonGreen : GameTheme.scoreAmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Exciting Hero Title with Purple & Black Glow
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: GameTheme.royalPurple.withValues(alpha: _glowAnimation.value * 0.45),
                            blurRadius: 36,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: GameTheme.primaryPurple.withValues(alpha: 0.5), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: GameTheme.royalPurple.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Text('🎡', style: TextStyle(fontSize: 48)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'TRUTH ',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2.5,
                              ),
                            ),
                            TextSpan(
                              text: 'OR ',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: GameTheme.neonLavender,
                                letterSpacing: 1.5,
                              ),
                            ),
                            TextSpan(
                              text: 'DARE',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: GameTheme.primaryPurple,
                                letterSpacing: 2.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                        decoration: BoxDecoration(
                          color: GameTheme.surfaceElevated.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: GameTheme.primaryPurple.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'MULTIPLAYER SPIN WHEEL GAME',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.2,
                            color: GameTheme.softLilac,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Player Profile Box (Black & Purple Glass)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: GameTheme.purpleGlassBox(),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _showAvatarPicker,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(_selectedColorValue),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(_selectedColorValue).withValues(alpha: 0.6),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(_selectedEmoji, style: const TextStyle(fontSize: 28)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, size: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'YOUR NICKNAME',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: GameTheme.textSecondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _nameController,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(color: GameTheme.primaryPurple),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: GameTheme.neonLavender, width: 2),
                                ),
                                hintText: 'Enter nickname...',
                                hintStyle: TextStyle(color: Colors.white30),
                              ),
                              onSubmitted: (_) => _updateProfile(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Exciting Action Buttons (Purple & Black)
                NeonButton(
                  text: 'Create Party Room',
                  icon: Icons.add_circle_outline_rounded,
                  primaryColor: GameTheme.royalPurple,
                  secondaryColor: GameTheme.primaryPurple,
                  isLoading: _isLoading,
                  onPressed: _createRoom,
                ),

                const SizedBox(height: 12),

                NeonButton(
                  text: 'Join Room with Code',
                  icon: Icons.meeting_room_outlined,
                  primaryColor: const Color(0xFF1F173B),
                  secondaryColor: const Color(0xFF2E2256),
                  isLoading: _isLoading,
                  onPressed: _showJoinRoomDialog,
                ),

                const SizedBox(height: 24),

                // Clean Mini Features Overview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GameTheme.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      _buildFeatureItem(
                        '🎡 Synchronized Roulette Wheel',
                        'Real-time physical spin synchronized across everyone\'s phones.',
                      ),
                      const Divider(color: Colors.white10, height: 18),
                      _buildFeatureItem(
                        '🔥 150+ Truths & Dares',
                        'Curated party prompts from Mild icebreakers to Wild challenges.',
                      ),
                      const Divider(color: Colors.white10, height: 18),
                      _buildFeatureItem(
                        '⚡ Forfeit Strikes & Live Scores',
                        'Friendly party competition with instant round celebrations.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: GameTheme.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
