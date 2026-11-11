import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Immersive animated background with slow-moving ambient radial gradients,
/// floating glowing orbs, and breathing lighting effect.
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, child) {
        final t = _ambientController.value;
        final wobble1 = math.sin(t * 2 * math.pi);
        final wobble2 = math.cos(t * 2 * math.pi);

        return Stack(
          children: [
            // Base deep royal purple canvas
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF14173E), // Deepest indigo midnight
                    Color(0xFF1B1B4D), // Mid royal purple
                    Color(0xFF222361), // Vibrant violet base
                    Color(0xFF161842), // Deep base
                  ],
                  stops: [0.0, 0.4, 0.75, 1.0],
                ),
              ),
            ),

            // Top-left ambient soft blue-purple glowing orb
            Positioned(
              top: -80 + (wobble1 * 25),
              left: -70 + (wobble2 * 20),
              child: IgnorePointer(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF4F46E5).withValues(alpha: 0.38 + (wobble1 * 0.08)),
                        const Color(0xFF6366F1).withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Center-right floating violet orb
            Positioned(
              top: 180 + (wobble2 * 30),
              right: -90 + (wobble1 * 25),
              child: IgnorePointer(
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7C3AED).withValues(alpha: 0.28 + (wobble2 * 0.06)),
                        const Color(0xFF9333EA).withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom-left deep ambient glow
            Positioned(
              bottom: -60 - (wobble1 * 20),
              left: -40 + (wobble2 * 25),
              child: IgnorePointer(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF4338CA).withValues(alpha: 0.35 + (wobble1 * 0.07)),
                        const Color(0xFF3730A3).withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Center-bottom soft backlight
            Positioned(
              bottom: 120 + (wobble2 * 15),
              right: 20 - (wobble1 * 20),
              child: IgnorePointer(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6366F1).withValues(alpha: 0.18 + (wobble2 * 0.05)),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Foreground child content
            widget.child,
          ],
        );
      },
    );
  }
}
