import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

class NeonButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color primaryColor;
  final Color? secondaryColor;
  final Color? textColor;
  final bool isFullWidth;
  final double height;
  final bool isLoading;
  final bool isOutline;

  const NeonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.primaryColor = const Color(0xFF9D84F6),
    this.secondaryColor,
    this.textColor,
    this.isFullWidth = true,
    this.height = 52,
    this.isLoading = false,
    this.isOutline = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final effectiveTextColor = widget.textColor ??
        (widget.isOutline
            ? Colors.white
            : (widget.primaryColor == GameTheme.primaryPurple ||
                    widget.primaryColor == GameTheme.neonGreen
                ? const Color(0xFF161320)
                : Colors.black87));

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => _controller.forward() : null,
        onTapUp: isEnabled
            ? (_) {
                _controller.reverse();
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: isEnabled ? () => _controller.reverse() : null,
        child: Container(
          height: widget.height,
          width: widget.isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: isEnabled
                ? (widget.isOutline ? GameTheme.surface : widget.primaryColor)
                : Colors.grey.shade900,
            borderRadius: BorderRadius.circular(30),
            border: widget.isOutline
                ? Border.all(color: Colors.white24, width: 1.2)
                : Border.all(
                    color: isEnabled
                        ? widget.primaryColor
                        : Colors.transparent,
                    width: 1,
                  ),
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: effectiveTextColor, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: effectiveTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
