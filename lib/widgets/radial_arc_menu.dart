import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ArcMenuItem {
  final String id;
  final String label;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isFilled;

  const ArcMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    this.isFilled = false,
  });
}

class _AngleSample {
  final double angle;
  final DateTime time;
  _AngleSample(this.angle, this.time);
}

/// Interactive Rotating Radial / Arc Menu
/// Elevated with:
/// - Exact 9 Chairman options matching top horizontal scrolling bar
/// - Direct pointer Listener with zero-latency 60fps/120fps rotational drag
/// - Physics-based momentum inertia deceleration and tactile snap-to-item
/// - Tap-to-center on secondary items and tap-to-select on active item
/// - Dashed circular orbit track CustomPainter
/// - Active focal item enlarged with glowing double neon ring
/// - Role status capsule ("• • CHAIRMAN") and count capsule ("⟲ 9 Modules • Swipe arc ⟳")
/// - Pinned bottom-right FAB with white border and morphing close icon (X)
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
    with TickerProviderStateMixin {
  late final AnimationController _openCloseAnim;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _fadeAnimation;

  // Inertia and rotational physics controller
  late final AnimationController _inertiaAnimController;
  double _snapStartAngle = 0.0;
  double _snapEndAngle = 0.0;

  // Geometry constants
  // Total items dynamically matching the options list
  int get _totalItems => _items.length;
  // Natural spacing between items along the arc (≈ 21.8 deg)
  static const double _stepAngle = 0.38;
  double get _period => _items.length * _stepAngle;
  static const double _focalAngle = -3 * math.pi / 4; // -135 deg (up-left from FAB center)
  static const double _orbitRadius = 260.0; // Radius of circular track

  // Initial angle places item 0 ("Overview") directly at the focal center
  double _currentRotationAngle = _focalAngle;

  // Gesture tracking with raw pointer events
  double _lastTouchAngle = 0.0;
  double _totalDragDistance = 0.0;
  final List<_AngleSample> _recentSamples = [];
  int _lastActiveIndex = 0;

  // 9 Chairman Options matching top horizontal tabs
  final List<ArcMenuItem> _items = const [
    ArcMenuItem(
      id: 'view-overview',
      label: 'Overview',
      icon: Icons.dashboard_rounded,
      primaryColor: Color(0xFF7C3AED),
      secondaryColor: Color(0xFF6D28D9),
      isFilled: true,
    ),
    ArcMenuItem(
      id: 'view-branches',
      label: 'Branch Tree',
      icon: Icons.account_tree_rounded,
      primaryColor: Color(0xFF8B5CF6),
      secondaryColor: Color(0xFF7C3AED),
      isFilled: false,
    ),
    ArcMenuItem(
      id: 'view-users',
      label: 'Users',
      icon: Icons.people_alt_rounded,
      primaryColor: Color(0xFF3B82F6),
      secondaryColor: Color(0xFF2563EB),
      isFilled: false,
    ),
    ArcMenuItem(
      id: 'view-attendance',
      label: 'Attendance',
      icon: Icons.fact_check_rounded,
      primaryColor: Color(0xFF06B6D4),
      secondaryColor: Color(0xFF0891B2),
      isFilled: false,
    ),
    ArcMenuItem(
      id: 'view-lookup',
      label: 'Student Lookup',
      icon: Icons.person_search_rounded,
      primaryColor: Color(0xFF06B6D4),
      secondaryColor: Color(0xFF0891B2),
      isFilled: false,
    ),
    ArcMenuItem(
      id: 'view-finance',
      label: 'Finance & Fees',
      icon: Icons.account_balance_wallet_rounded,
      primaryColor: Color(0xFF10B981),
      secondaryColor: Color(0xFF059669),
      isFilled: false,
    ),
    ArcMenuItem(
      id: 'view-academics',
      label: 'Academics',
      icon: Icons.school_rounded,
      primaryColor: Color(0xFFF59E0B),
      secondaryColor: Color(0xFFD97706),
      isFilled: false,
    ),
    ArcMenuItem(
      id: 'view-operations',
      label: 'People & Ops',
      icon: Icons.business_center_rounded,
      primaryColor: Color(0xFF4F46E5),
      secondaryColor: Color(0xFF3730A3),
      isFilled: true,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _openCloseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _expandAnimation = CurvedAnimation(
      parent: _openCloseAnim,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _openCloseAnim,
      curve: Curves.easeInOut,
    );

    _inertiaAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _inertiaAnimController.addListener(() {
      final curve = CurvedAnimation(
        parent: _inertiaAnimController,
        curve: Curves.easeOutCubic,
      );
      setState(() {
        _currentRotationAngle =
            _snapStartAngle + (_snapEndAngle - _snapStartAngle) * curve.value;
      });
      _checkActiveHaptic();
    });

    if (widget.isOpen) {
      _openCloseAnim.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant RadialArcMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _openCloseAnim.forward();
      } else {
        _openCloseAnim.reverse();
      }
    }
  }

  @override
  void dispose() {
    _openCloseAnim.dispose();
    _inertiaAnimController.dispose();
    super.dispose();
  }

  /// Calculates the angle of item [index] closest to [_focalAngle]
  double _getItemAngle(int index, double rotationAngle) {
    final baseAngle = index * _stepAngle + rotationAngle;
    final k = ((_focalAngle - baseAngle) / _period).round();
    return baseAngle + k * _period;
  }

  void _checkActiveHaptic() {
    final activeIndex = _getActiveItemIndex();
    if (activeIndex != _lastActiveIndex) {
      _lastActiveIndex = activeIndex;
      HapticFeedback.selectionClick();
    }
  }

  int _getActiveItemIndex() {
    int bestIndex = 0;
    double smallestDiff = 999.0;

    for (int i = 0; i < _items.length; i++) {
      final angle = _getItemAngle(i, _currentRotationAngle);
      double diff = (angle - _focalAngle).abs();
      if (diff < smallestDiff) {
        smallestDiff = diff;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  double _calculateSnapAngleForTarget(double targetAngle) {
    final k = ((_focalAngle - targetAngle) / _stepAngle).round();
    return _focalAngle - k * _stepAngle;
  }

  void _snapToNearest() {
    _snapStartAngle = _currentRotationAngle;
    _snapEndAngle = _calculateSnapAngleForTarget(_currentRotationAngle);

    _inertiaAnimController.duration = const Duration(milliseconds: 320);
    _inertiaAnimController.forward(from: 0.0);
  }

  void _rotateToItem(int itemIndex) {
    HapticFeedback.selectionClick();
    final currentItemAngle = _getItemAngle(itemIndex, _currentRotationAngle);
    final delta = _focalAngle - currentItemAngle;

    _snapStartAngle = _currentRotationAngle;
    _snapEndAngle = _currentRotationAngle + delta;

    _inertiaAnimController.duration = const Duration(milliseconds: 360);
    _inertiaAnimController.forward(from: 0.0);
  }

  void _onPointerDown(PointerDownEvent event, Offset fabCenter) {
    _inertiaAnimController.stop();
    _totalDragDistance = 0.0;

    final startAngle = math.atan2(
      event.localPosition.dy - fabCenter.dy,
      event.localPosition.dx - fabCenter.dx,
    );
    _lastTouchAngle = startAngle;
    _recentSamples.clear();
    _recentSamples.add(_AngleSample(startAngle, DateTime.now()));
  }

  void _onPointerMove(PointerMoveEvent event, Offset fabCenter) {
    _totalDragDistance += (event.delta).distance;

    final currentAngle = math.atan2(
      event.localPosition.dy - fabCenter.dy,
      event.localPosition.dx - fabCenter.dx,
    );

    double delta = currentAngle - _lastTouchAngle;
    while (delta > math.pi) {
      delta -= 2 * math.pi;
    }
    while (delta < -math.pi) {
      delta += 2 * math.pi;
    }

    setState(() {
      _currentRotationAngle += delta;
    });

    _lastTouchAngle = currentAngle;
    final now = DateTime.now();
    _recentSamples.add(_AngleSample(currentAngle, now));
    _recentSamples.removeWhere(
      (s) => now.difference(s.time).inMilliseconds > 120,
    );

    _checkActiveHaptic();
  }

  void _onPointerUp(PointerUpEvent event, Offset fabCenter) {
    // 1. If total movement was tiny, process as a TAP
    if (_totalDragDistance < 14.0) {
      final tapPos = event.localPosition;

      // Check if tap was on the FAB
      if ((tapPos - fabCenter).distance <= 38.0) {
        HapticFeedback.lightImpact();
        widget.onToggle();
        return;
      }

      // Check if tap was on any visible orbital item
      for (int i = 0; i < _items.length; i++) {
        final angle = _getItemAngle(i, _currentRotationAngle);
        if (angle < -3.35 || angle > -1.35) continue;

        final itemCenter = Offset(
          fabCenter.dx + _orbitRadius * math.cos(angle),
          fabCenter.dy + _orbitRadius * math.sin(angle),
        );

        final dist = (tapPos - itemCenter).distance;
        final pillRect = Rect.fromCenter(
          center: Offset(itemCenter.dx, itemCenter.dy + 38),
          width: 120,
          height: 36,
        );

        if (dist <= 42.0 || pillRect.contains(tapPos)) {
          final isFocal = (angle - _focalAngle).abs() < (_stepAngle * 0.45);
          if (isFocal) {
            HapticFeedback.mediumImpact();
            widget.onItemSelected(_items[i].id);
            widget.onToggle();
          } else {
            _rotateToItem(i);
          }
          return;
        }
      }

      // Tap on empty backdrop closes menu
      widget.onToggle();
      return;
    }

    // 2. Otherwise process as a DRAG with inertial momentum
    if (_recentSamples.length < 2) {
      _snapToNearest();
      return;
    }

    final first = _recentSamples.first;
    final last = _recentSamples.last;
    final dt = (last.time.difference(first.time).inMicroseconds) / 1000000.0;

    double velocity = 0.0;
    if (dt > 0.005) {
      double dAngle = last.angle - first.angle;
      while (dAngle > math.pi) {
        dAngle -= 2 * math.pi;
      }
      while (dAngle < -math.pi) {
        dAngle += 2 * math.pi;
      }
      velocity = dAngle / dt;
    }

    velocity = velocity.clamp(-14.0, 14.0);

    if (velocity.abs() < 0.4) {
      _snapToNearest();
      return;
    }

    // Physics momentum deceleration
    final momentum = velocity * 0.22;
    final targetAngle = _currentRotationAngle + momentum;
    final snapTarget = _calculateSnapAngleForTarget(targetAngle);

    _snapStartAngle = _currentRotationAngle;
    _snapEndAngle = snapTarget;

    final durationMs = (350 + (velocity.abs() * 40).clamp(0, 450)).toInt();
    _inertiaAnimController.duration = Duration(milliseconds: durationMs);
    _inertiaAnimController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackWidth = constraints.maxWidth;
        final stackHeight = constraints.maxHeight;
        // FAB center at right: 20, bottom: 20 with 62x62 size
        final fabCenter = Offset(stackWidth - 20 - 31, stackHeight - 20 - 31);

        return AnimatedBuilder(
          animation: _openCloseAnim,
          builder: (context, _) {
            final progress = _openCloseAnim.value;
            final isCompletelyClosed = !widget.isOpen && progress == 0.0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Only render interactive overlay when open or animating
                if (!isCompletelyClosed)
                  Positioned.fill(
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: (e) => _onPointerDown(e, fabCenter),
                      onPointerMove: (e) => _onPointerMove(e, fabCenter),
                      onPointerUp: (e) => _onPointerUp(e, fabCenter),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 1. Frosted Glass Backdrop
                          Positioned.fill(
                            child: Opacity(
                              opacity: _fadeAnimation.value,
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.68),
                                ),
                              ),
                            ),
                          ),

                          // 2. Dashed Circular Orbit Track
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: progress.clamp(0.0, 1.0),
                                child: CustomPaint(
                                  painter: _DashedOrbitPainter(
                                    center: fabCenter,
                                    radius: _orbitRadius,
                                    startAngle: -3.10,
                                    sweepAngle: 1.65,
                                    dashColor: Colors.white.withValues(alpha: 0.35),
                                    dashLength: 7.0,
                                    dashGap: 6.0,
                                    strokeWidth: 1.8,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 3. Role Indicator Pill ("• • CHAIRMAN")
                          if (progress > 0.25)
                            Positioned(
                              bottom: 96,
                              right: 86,
                              child: Opacity(
                                opacity: ((progress - 0.25) * 1.33).clamp(0.0, 1.0),
                                child: IgnorePointer(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4F46E5),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4F46E5).withValues(alpha: 0.5),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.circle, color: Colors.white, size: 5),
                                        SizedBox(width: 4),
                                        Icon(Icons.circle, color: Colors.white, size: 5),
                                        SizedBox(width: 6),
                                        Text(
                                          'CHAIRMAN',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // 4. Bottom Capsule Pill ("⟲ 9 Modules • Swipe arc ⟳")
                          if (progress > 0.35)
                            Positioned(
                              bottom: 12,
                              right: 90,
                              child: Opacity(
                                opacity: ((progress - 0.35) * 1.54).clamp(0.0, 1.0),
                                child: IgnorePointer(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF101528).withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.16),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.45),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          '⟲',
                                          style: TextStyle(
                                            color: Color(0xFF818CF8),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${_items.length} Modules • Swipe arc',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          '⟳',
                                          style: TextStyle(
                                            color: Color(0xFF818CF8),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // 5. Dynamic Orbital Items Along Arc
                          ..._buildOrbitalItems(fabCenter, progress),
                        ],
                      ),
                    ),
                  ),

                // 6. Floating Action Button (FAB) Pinned at Bottom Right
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: _buildTriggerFab(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> _buildOrbitalItems(Offset fabCenter, double openProgress) {
    final widgets = <Widget>[];

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];

      // Calculate angle along the circular path
      final angle = _getItemAngle(i, _currentRotationAngle);

      // Visibility filter: only render items near the visible arc quadrant
      if (angle < -3.35 || angle > -1.35) continue;

      // Calculate distance to focal angle (-3*pi/4)
      final diff = (angle - _focalAngle).abs();
      final focalFactor = (1.0 - (diff / (_stepAngle * 0.90))).clamp(0.0, 1.0);
      final isFocal = diff < (_stepAngle * 0.45);

      // Edge fade out so items smoothly slide onto screen
      double edgeFade = 1.0;
      if (angle < -3.05) {
        edgeFade = ((angle - (-3.35)) / 0.30).clamp(0.0, 1.0);
      } else if (angle > -1.55) {
        edgeFade = (((-1.35) - angle) / 0.20).clamp(0.0, 1.0);
      }

      // Radius with smooth entrance scale
      final currentRadius = _orbitRadius * (0.4 + 0.6 * _expandAnimation.value);
      final itemCenter = Offset(
        fabCenter.dx + currentRadius * math.cos(angle),
        fabCenter.dy + currentRadius * math.sin(angle),
      );

      // Sizes
      final baseSize = isFocal ? 76.0 : 50.0;
      final outerRingSize = isFocal ? 94.0 : 50.0;

      widgets.add(
        Positioned(
          left: itemCenter.dx - 65, // 130 wide centered container
          top: itemCenter.dy - (outerRingSize / 2),
          child: IgnorePointer(
            // Pointer events are processed centrally in the parent Listener for 100% smooth dragging
            child: Opacity(
              opacity: (openProgress * edgeFade).clamp(0.0, 1.0),
              child: SizedBox(
                width: 130,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Outer Ring & Bubble Container
                    SizedBox(
                      width: outerRingSize,
                      height: outerRingSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Double Neon Glow Ring (for active focal item)
                          if (isFocal)
                            Container(
                              width: outerRingSize,
                              height: outerRingSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(
                                    alpha: 0.45 * focalFactor,
                                  ),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: item.primaryColor.withValues(
                                      alpha: 0.45 * focalFactor,
                                    ),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),

                          // Inner Circle Icon Button
                          Container(
                            width: baseSize,
                            height: baseSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: (isFocal || item.isFilled)
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        item.primaryColor,
                                        item.secondaryColor,
                                      ],
                                    )
                                  : const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white,
                                        Color(0xFFF8FAFC),
                                      ],
                                    ),
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha: isFocal ? 1.0 : 0.85,
                                ),
                                width: isFocal ? 3.5 : 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isFocal
                                      ? item.primaryColor.withValues(alpha: 0.65)
                                      : Colors.black.withValues(alpha: 0.22),
                                  blurRadius: isFocal ? 18 : 8,
                                  offset: isFocal ? Offset.zero : const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                item.icon,
                                color: (isFocal || item.isFilled)
                                    ? Colors.white
                                    : item.primaryColor,
                                size: isFocal ? 34 : 23,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Attached Dark Title Capsule Pill
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isFocal ? 14 : 9,
                        vertical: isFocal ? 5 : 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101528).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isFocal
                              ? Colors.white.withValues(alpha: 0.28)
                              : Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isFocal ? 12.0 : 9.8,
                          fontWeight: isFocal ? FontWeight.w800 : FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildTriggerFab() {
    final isOpen = widget.isOpen;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onToggle();
      },
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF555AF6), // Royal Indigo-Blue from reference
              Color(0xFF6B58F7),
            ],
          ),
          border: Border.all(
            color: Colors.white,
            width: 3.5, // Crisp thick white ring from screenshot
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF555AF6).withValues(alpha: 0.55),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: AnimatedRotation(
            turns: isOpen ? 0.25 : 0.0,
            duration: const Duration(milliseconds: 280),
            child: Icon(
              isOpen ? Icons.close_rounded : Icons.menu_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for drawing a dashed circular arc
class _DashedOrbitPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double startAngle;
  final double sweepAngle;
  final Color dashColor;
  final double dashLength;
  final double dashGap;
  final double strokeWidth;

  _DashedOrbitPainter({
    required this.center,
    required this.radius,
    required this.startAngle,
    required this.sweepAngle,
    required this.dashColor,
    required this.dashLength,
    required this.dashGap,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dashColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arcLength = radius * sweepAngle.abs();
    final stepLength = dashLength + dashGap;
    final count = (arcLength / stepLength).floor();
    final dAngle = sweepAngle / count;
    final dashAngle = dAngle * (dashLength / stepLength);

    final rect = Rect.fromCircle(center: center, radius: radius);

    for (int i = 0; i < count; i++) {
      final currentStart = startAngle + i * dAngle;
      canvas.drawArc(rect, currentStart, dashAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedOrbitPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.radius != radius ||
        oldDelegate.startAngle != startAngle ||
        oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.dashColor != dashColor;
  }
}
