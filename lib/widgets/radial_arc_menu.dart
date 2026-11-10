import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ArcMenuItem {
  final String id;
  final String label;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isFeatured;

  const ArcMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    this.isFeatured = false,
  });
}

/// Interactive Rotating Radial / Arc Menu
/// Inspired by the Stitch Chairman design with:
/// - Floating bottom-right trigger FAB with morphing icon (Menu <-> Close)
/// - Dimmed ambient backdrop with tap to close
/// - Radial arc軌道 with glowing interactive orbital item buttons
/// - Swipe / drag gesture to rotate the wheel
/// - Tactile haptic feedback and label badge
class RadialArcMenu extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final Function(String id) onItemSelected;

  const RadialArcMenu({
    super.key,
    required this.isOpen,
    required this.onToggle,
    required this.onItemSelected,
  });

  @override
  State<RadialArcMenu> createState() => _RadialArcMenuState();
}

class _RadialArcMenuState extends State<RadialArcMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _fadeAnimation;

  double _wheelRotationAngle = 0.0; // In radians
  double _dragStartAngle = 0.0;
  double _dragStartRotation = 0.0;

  final List<ArcMenuItem> _items = const [
    ArcMenuItem(
      id: 'view-overview',
      label: 'Overview',
      icon: Icons.dashboard_rounded,
      primaryColor: Color(0xFF6366F1),
      secondaryColor: Color(0xFF818CF8),
    ),
    ArcMenuItem(
      id: 'view-branches',
      label: 'Branch Tree',
      icon: Icons.account_tree_rounded,
      primaryColor: Color(0xFF8B5CF6),
      secondaryColor: Color(0xFFA78BFA),
    ),
    ArcMenuItem(
      id: 'view-users',
      label: 'Users',
      icon: Icons.group_rounded,
      primaryColor: Color(0xFF3B82F6),
      secondaryColor: Color(0xFF60A5FA),
    ),
    ArcMenuItem(
      id: 'view-lookup',
      label: 'Student 360',
      icon: Icons.person_search_rounded,
      primaryColor: Color(0xFF06B6D4),
      secondaryColor: Color(0xFF22D3EE),
    ),
    ArcMenuItem(
      id: 'view-finance',
      label: 'Finance & Fees',
      icon: Icons.account_balance_wallet_rounded,
      primaryColor: Color(0xFF10B981),
      secondaryColor: Color(0xFF34D399),
    ),
    ArcMenuItem(
      id: 'view-growth',
      label: 'Admissions',
      icon: Icons.trending_up_rounded,
      primaryColor: Color(0xFFA855F7),
      secondaryColor: Color(0xFFC084FC),
    ),
    ArcMenuItem(
      id: 'view-academics',
      label: 'Academics',
      icon: Icons.school_rounded,
      primaryColor: Color(0xFF7C3AED),
      secondaryColor: Color(0xFF9333EA),
    ),
    ArcMenuItem(
      id: 'view-operations',
      label: 'People & Ops',
      icon: Icons.business_center_rounded,
      primaryColor: Color(0xFF4F46E5),
      secondaryColor: Color(0xFF3B82F6),
      isFeatured: true,
    ),
    ArcMenuItem(
      id: 'view-marketing',
      label: 'Marketing',
      icon: Icons.campaign_rounded,
      primaryColor: Color(0xFFEC4899),
      secondaryColor: Color(0xFFF472B6),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    if (widget.isOpen) {
      _animController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant RadialArcMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _rotateByStep(bool forward) {
    HapticFeedback.selectionClick();
    setState(() {
      _wheelRotationAngle += (forward ? 0.35 : -0.35);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final progress = _animController.value;
        if (progress <= 0.0 && !widget.isOpen) {
          return _buildFabButton();
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Dark Frosted Backdrop
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onToggle,
                child: Opacity(
                  opacity: _fadeAnimation.value * 0.72,
                  child: Container(
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),

            // Concentric Orbit Guide Arcs
            Positioned(
              bottom: 24,
              right: 24,
              child: CustomPaint(
                size: const Size(400, 400),
                painter: _OrbitGuidePainter(progress: progress),
              ),
            ),

            // Rotary Wheel Items
            Positioned(
              bottom: 24,
              right: 24,
              child: Transform.scale(
                scale: 0.4 + (0.6 * _expandAnimation.value),
                alignment: Alignment.bottomRight,
                child: Opacity(
                  opacity: progress.clamp(0.0, 1.0),
                  child: GestureDetector(
                    onPanStart: (details) {
                      _dragStartAngle = math.atan2(
                        details.localPosition.dy,
                        details.localPosition.dx,
                      );
                      _dragStartRotation = _wheelRotationAngle;
                    },
                    onPanUpdate: (details) {
                      final currentAngle = math.atan2(
                        details.localPosition.dy,
                        details.localPosition.dx,
                      );
                      setState(() {
                        _wheelRotationAngle =
                            _dragStartRotation + (currentAngle - _dragStartAngle);
                      });
                    },
                    child: SizedBox(
                      width: 480,
                      height: 480,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: _buildOrbitalItems(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Swipe to Rotate Hint Badge
            if (progress > 0.5)
              Positioned(
                bottom: 110,
                right: 90,
                child: Opacity(
                  opacity: ((progress - 0.5) * 2).clamp(0.0, 1.0),
                  child: GestureDetector(
                    onTap: () => _rotateByStep(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF818CF8).withValues(alpha: 0.4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.chevron_left_rounded, color: Color(0xFF818CF8), size: 16),
                          SizedBox(width: 2),
                          Text(
                            'Swipe to rotate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, color: Color(0xFF818CF8), size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // The Bottom-Right Trigger FAB
            Positioned(
              bottom: 24,
              right: 24,
              child: _buildFabButton(),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildOrbitalItems() {
    const double radius = 230.0; // Distance from center
    // Arc distribution between ~100 deg and ~200 deg (top-left quadrant)
    const double arcSpan = math.pi * 0.70;
    const double baseOffset = math.pi;

    return List.generate(_items.length, (index) {
      final item = _items[index];
      final itemAngle = baseOffset +
          (index / (_items.length - 1)) * arcSpan +
          _wheelRotationAngle;

      final dx = radius * math.cos(itemAngle);
      final dy = radius * math.sin(itemAngle);

      final isCenterFeatured = item.isFeatured;
      final size = isCenterFeatured ? 72.0 : 54.0;

      return Positioned(
        right: -dx - (size / 2) + 24,
        bottom: -dy - (size / 2) + 24,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onItemSelected(item.id);
            widget.onToggle();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Bubble
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.3),
                    colors: [
                      item.secondaryColor,
                      item.primaryColor,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: item.primaryColor.withValues(alpha: 0.6),
                      blurRadius: isCenterFeatured ? 24 : 14,
                      spreadRadius: isCenterFeatured ? 2 : 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isCenterFeatured ? 0.95 : 0.75),
                    width: isCenterFeatured ? 3.0 : 2.0,
                  ),
                ),
                child: Icon(
                  item.icon,
                  color: Colors.white,
                  size: isCenterFeatured ? 32 : 24,
                ),
              ),
              const SizedBox(height: 5),

              // Title Capsule
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCenterFeatured ? 10 : 7,
                  vertical: isCenterFeatured ? 4 : 2.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF181D2F).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: item.primaryColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCenterFeatured ? 11.5 : 9.5,
                    fontWeight: isCenterFeatured ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFabButton() {
    final isOpen = widget.isOpen;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onToggle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isOpen
                ? [
                    const Color(0xFFF43F5E), // Coral close state
                    const Color(0xFFE11D48),
                  ]
                : [
                    const Color(0xFF6366F1), // Royal purple menu state
                    const Color(0xFF7C3AED),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: (isOpen ? const Color(0xFFE11D48) : const Color(0xFF7C3AED))
                  .withValues(alpha: 0.55),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: AnimatedRotation(
            turns: isOpen ? 0.25 : 0.0,
            duration: const Duration(milliseconds: 280),
            child: Icon(
              isOpen ? Icons.close_rounded : Icons.menu_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitGuidePainter extends CustomPainter {
  final double progress;

  _OrbitGuidePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final center = Offset(size.width, size.height);

    final guidePaint = Paint()
      ..color = const Color(0xFF818CF8).withValues(alpha: 0.18 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Draw concentric arc tracks
    canvas.drawCircle(center, 230, guidePaint);
    canvas.drawCircle(center, 290, guidePaint);
    canvas.drawCircle(center, 170, guidePaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitGuidePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
