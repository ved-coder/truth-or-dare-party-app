import 'package:flutter/material.dart';

class NeonButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color primaryColor;
  final Color? secondaryColor;
  final bool isFullWidth;
  final double height;
  final bool isLoading;

  const NeonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.primaryColor = const Color(0xFF8B5CF6),
    this.secondaryColor,
    this.isFullWidth = true,
    this.height = 54,
    this.isLoading = false,
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSecondary = widget.secondaryColor ?? widget.primaryColor.withValues(alpha: 0.8);
    final isEnabled = widget.onPressed != null && !widget.isLoading;

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
            gradient: LinearGradient(
              colors: isEnabled
                  ? [widget.primaryColor, effectiveSecondary]
                  : [Colors.grey.shade800, Colors.grey.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: widget.primaryColor.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
            border: Border.all(
              color: isEnabled
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white10,
              width: 1.2,
            ),
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
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
