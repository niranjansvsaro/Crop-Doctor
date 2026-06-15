import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';


class SeverityBadge extends StatelessWidget {
  final int severity;
  final bool animate;

  const SeverityBadge({
    super.key,
    required this.severity,
    this.animate = true,
  });

  Color _getColor() {
    if (severity <= 2) return const Color(0xFF66BB6A); // Light Green (Mild)
    if (severity == 3) return const Color(0xFFFF9800); // Orange (Moderate)
    return const Color(0xFFEF5350); // Red (Severe)
  }

  String _getLabel() {
    if (severity <= 2) return "Mild (L$severity)";
    if (severity == 3) return "Moderate (L$severity)";
    return "Severe (L$severity)";
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final label = _getLabel();

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(60),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    if (animate) {
      // Pulse animation using flutter_animate
      return badge
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(delay: 2000.ms, duration: 1500.ms, color: color.withAlpha(80))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.03, 1.03),
            duration: 1200.ms,
            curve: Curves.easeInOut,
          );
    }

    return badge;
  }
}
