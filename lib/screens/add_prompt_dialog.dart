import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/prompt_model.dart';
import '../theme/game_theme.dart';
import '../widgets/neon_button.dart';

class AddPromptDialog extends StatefulWidget {
  final String playerName;
  final Function(PromptItem prompt) onPromptCreated;

  const AddPromptDialog({
    super.key,
    required this.playerName,
    required this.onPromptCreated,
  });

  static Future<void> show(
    BuildContext context, {
    required String playerName,
    required Function(PromptItem prompt) onPromptCreated,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AddPromptDialog(
        playerName: playerName,
        onPromptCreated: onPromptCreated,
      ),
    );
  }

  @override
  State<AddPromptDialog> createState() => _AddPromptDialogState();
}

class _AddPromptDialogState extends State<AddPromptDialog> {
  final TextEditingController _textController = TextEditingController();
  PromptType _selectedType = PromptType.truth;
  IntensityLevel _selectedIntensity = IntensityLevel.spicy;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final prompt = PromptItem(
      id: const Uuid().v4().substring(0, 8),
      text: text,
      type: _selectedType,
      intensity: _selectedIntensity,
      category: 'Custom Prompt',
      submittedByPlayerName: widget.playerName,
    );

    widget.onPromptCreated(prompt);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GameTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: GameTheme.neonPurple, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: GameTheme.neonAmber, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Add Custom Card',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Type Selector (Truth vs Dare)
            Row(
              children: [
                Expanded(
                  child: _buildChoiceChip(
                    label: 'TRUTH 💭',
                    selected: _selectedType == PromptType.truth,
                    color: GameTheme.neonCyan,
                    onTap: () => setState(() => _selectedType = PromptType.truth),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildChoiceChip(
                    label: 'DARE 🔥',
                    selected: _selectedType == PromptType.dare,
                    color: GameTheme.neonPink,
                    onTap: () => setState(() => _selectedType = PromptType.dare),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Intensity Selector
            const Text(
              'Spiciness Level:',
              style: TextStyle(fontSize: 13, color: GameTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildIntensityChip('Mild 😇', IntensityLevel.mild, GameTheme.neonGreen),
                const SizedBox(width: 8),
                _buildIntensityChip('Spicy 🌶️', IntensityLevel.spicy, GameTheme.neonAmber),
                const SizedBox(width: 8),
                _buildIntensityChip('Wild ⚡', IntensityLevel.extreme, GameTheme.neonPink),
              ],
            ),
            const SizedBox(height: 16),

            // Text input
            TextField(
              controller: _textController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _selectedType == PromptType.truth
                    ? 'Enter juicy truth question...'
                    : 'Enter an outrageous challenge...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: GameTheme.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _selectedType == PromptType.truth
                        ? GameTheme.neonCyan
                        : GameTheme.neonPink,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            NeonButton(
              text: 'Add to Room Deck',
              icon: Icons.add_circle_outline,
              onPressed: _submit,
              primaryColor: _selectedType == PromptType.truth
                  ? GameTheme.neonCyan
                  : GameTheme.neonPink,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.25) : GameTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
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
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntensityChip(String label, IntensityLevel level, Color color) {
    final selected = _selectedIntensity == level;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIntensity = level),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.2) : GameTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Colors.white10,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
