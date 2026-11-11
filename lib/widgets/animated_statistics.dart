import 'package:flutter/material.dart';

/// Animated statistics row displaying:
/// - 11 ROLES (animated 0 -> 11)
/// - 41 MODULES (animated 0 -> 41)
/// - 185 SCREENS (animated 0 -> 185)
/// - AA WCAG (fade and scale entrance)
/// - Vertical dividing separators with scale transition
class AnimatedStatistics extends StatelessWidget {
  final double progress; // Overall progress for stats (0.0 to 1.0)

  const AnimatedStatistics({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    // Stagger progress for each statistic column
    final stat1Progress = _subProgress(progress, 0.0, 0.6);
    final stat2Progress = _subProgress(progress, 0.15, 0.75);
    final stat3Progress = _subProgress(progress, 0.3, 0.9);
    final stat4Progress = _subProgress(progress, 0.45, 1.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildCounterStat(
          targetValue: 11,
          label: 'ROLES',
          progress: stat1Progress,
        ),
        _buildDivider(progress: stat1Progress),
        _buildCounterStat(
          targetValue: 41,
          label: 'MODULES',
          progress: stat2Progress,
        ),
        _buildDivider(progress: stat2Progress),
        _buildCounterStat(
          targetValue: 185,
          label: 'SCREENS',
          progress: stat3Progress,
        ),
        _buildDivider(progress: stat3Progress),
        _buildBadgeStat(
          title: 'AA',
          label: 'WCAG',
          progress: stat4Progress,
        ),
      ],
    );
  }

  double _subProgress(double t, double begin, double end) {
    if (t <= begin) return 0.0;
    if (t >= end) return 1.0;
    return (t - begin) / (end - begin);
  }

  Widget _buildCounterStat({
    required int targetValue,
    required String label,
    required double progress,
  }) {
    final curve = Curves.easeOutCubic.transform(progress);
    final currentValue = (targetValue * curve).round();

    // Label reveals after value reaches ~40%
    final labelOpacity = _subProgress(progress, 0.4, 1.0);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: progress.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1.0 - curve) * 12.0),
              child: Text(
                '$currentValue',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  fontFamily: '-apple-system',
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Opacity(
            opacity: labelOpacity,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8), // Muted metallic slate
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeStat({
    required String title,
    required String label,
    required double progress,
  }) {
    final curve = Curves.easeOutBack.transform(progress);
    final scale = 0.8 + (0.2 * curve);
    final labelOpacity = _subProgress(progress, 0.4, 1.0);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: progress.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale.clamp(0.0, 1.2),
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  fontFamily: '-apple-system',
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Opacity(
            opacity: labelOpacity,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider({required double progress}) {
    final scaleY = Curves.easeOutCubic.transform(progress);

    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      child: Transform.scale(
        scaleY: scaleY,
        child: Container(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}
