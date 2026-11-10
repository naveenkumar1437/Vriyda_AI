import 'package:flutter/material.dart';

/// Minimal, elegant animated footer
class AnimatedFooter extends StatelessWidget {
  final double progress; // 0.0 to 1.0

  const AnimatedFooter({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final curve = Curves.easeOut.transform(t);

    return Opacity(
      opacity: curve,
      child: Transform.translate(
        offset: Offset(0, (1.0 - curve) * 8.0),
        child: const Text(
          '© 2026 Vriyda Portal',
          style: TextStyle(
            color: Color(0xFF64748B), // Soft muted slate
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
