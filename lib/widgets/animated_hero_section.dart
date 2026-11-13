import 'package:flutter/material.dart';

/// Cinematic Hero Section featuring:
/// - Two-line heading ("A calmer way to run" in white, "your campus." in lavender)
/// - Subtitle description with staggered fade/slide
/// - Subtle light sweep effect behind the heading
class AnimatedHeroSection extends StatelessWidget {
  final double eyebrowProgress; // 0.0 to 1.0
  final double headingLine1Progress; // 0.0 to 1.0
  final double headingLine2Progress; // 0.0 to 1.0
  final double descriptionProgress; // 0.0 to 1.0
  final double sweepProgress; // 0.0 to 1.0 for continuous background light sweep

  const AnimatedHeroSection({
    super.key,
    required this.eyebrowProgress,
    required this.headingLine1Progress,
    required this.headingLine2Progress,
    required this.descriptionProgress,
    this.sweepProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hero Heading Line 1 ("A calmer way to run")
        _buildHeadingLine(
          text: 'A calmer way to run',
          color: Colors.white,
          progress: headingLine1Progress,
        ),

        const SizedBox(height: 2),

        // Hero Heading Line 2 ("your campus.")
        _buildHeadingLine(
          text: 'your campus.',
          color: const Color(0xFFC7D2FE), // Soft Lavender Indigo
          progress: headingLine2Progress,
        ),

        const SizedBox(height: 24),

        // Description
        _buildDescription(),
      ],
    );
  }

  Widget _buildHeadingLine({
    required String text,
    required Color color,
    required double progress,
  }) {
    final t = progress.clamp(0.0, 1.0);
    final curve = Curves.easeOutCubic.transform(t);
    final scale = 0.94 + (0.06 * curve);

    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1.0 - curve) * 26.0),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 38,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              fontFamily: '-apple-system',
              shadows: [
                Shadow(
                  color: const Color(0xFF4338CA).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescription() {
    final t = descriptionProgress.clamp(0.0, 1.0);
    final curve = Curves.easeOutCubic.transform(t);

    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1.0 - curve) * 16.0),
        child: const Text(
          'Vriyda Portal unifies admissions, attendance, fees, exams, HR, and parent communication for K–12 and higher-ed institutions. Built for school staff who spend their day in this product.',
          style: TextStyle(
            color: Color(0xFFCBD5E1), // Crisp slate/lavender
            fontSize: 14.5,
            height: 1.55,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.15,
          ),
        ),
      ),
    );
  }
}
