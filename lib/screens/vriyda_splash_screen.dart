import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/animated_background.dart';
import '../widgets/animated_grid.dart';
import '../widgets/floating_particles.dart';
import '../widgets/animated_brand_header.dart';
import '../widgets/animated_hero_section.dart';
import '../widgets/animated_statistics.dart';
import '../widgets/animated_footer.dart';
import 'vriyda_login_screen.dart';

/// Premium Animated Splash Screen for Vriyda Portal.
///
/// Animation Sequence (~3000ms entrance):
/// - 0–400ms: Background ambient lighting and grid appear.
/// - 300–800ms: Logo icon container and brand name reveal with rotating shimmer & stroke drawing.
/// - 800–1300ms: Eyebrow and hero heading lines appear with staggered upward motion.
/// - 1300–1800ms: Description reveals smoothly.
/// - 1800–2500ms: Statistics animate (0->11 roles, 0->41 modules, 0->185 screens, AA WCAG).
/// - 2500–3000ms: Footer fades in and all elements settle.
///
/// After 3 seconds (or slight settle at ~3.4s), smoothly transitions to the Vriyda Login Screen.
class VriydaSplashScreen extends StatefulWidget {
  final bool autoNavigate;
  const VriydaSplashScreen({super.key, this.autoNavigate = true});

  @override
  State<VriydaSplashScreen> createState() => _VriydaSplashScreenState();
}

class _VriydaSplashScreenState extends State<VriydaSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _controller.forward();

    if (widget.autoNavigate) {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed && !_hasNavigated) {
          // Allow the complete animated splash screen with counters & particles to be fully enjoyed
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (mounted && !_hasNavigated) {
              _navigateToLogin();
            }
          });
        }
      });
    }
  }

  void _navigateToLogin() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 750),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const VriydaLoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(fadeAnimation);

          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // System UI styling for dark immersive screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF14173E),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF14173E),
      body: AnimatedBackground(
        child: Stack(
          children: [
            // Dynamic Grid Layer
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                // 0 - 400ms: Grid and ambient lighting fade in
                final gridOpacity = Interval(
                  0.0,
                  0.15,
                  curve: Curves.easeOut,
                ).transform(_controller.value);

                return Positioned.fill(
                  child: VriydaAnimatedGrid(opacity: gridOpacity),
                );
              },
            ),

            // Floating micro-particles layer
            const Positioned.fill(
              child: FloatingParticles(count: 26),
            ),

            // Foreground Content Layout
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28.0,
                          vertical: 24.0,
                        ),
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            final progress = _controller.value;

                            // 1. Logo & Brand: 300ms - 800ms (0.09 - 0.25)
                            final brandProgress = const Interval(
                              0.09,
                              0.25,
                              curve: Curves.easeOut,
                            ).transform(progress);

                            // 2. Eyebrow: 800ms - 1050ms (0.25 - 0.33)
                            final eyebrowProgress = const Interval(
                              0.25,
                              0.33,
                              curve: Curves.easeOut,
                            ).transform(progress);

                            // 3. Heading Line 1: 900ms - 1200ms (0.28 - 0.38)
                            final heading1Progress = const Interval(
                              0.28,
                              0.38,
                              curve: Curves.easeOut,
                            ).transform(progress);

                            // 4. Heading Line 2: 1050ms - 1350ms (0.33 - 0.42)
                            final heading2Progress = const Interval(
                              0.33,
                              0.42,
                              curve: Curves.easeOut,
                            ).transform(progress);

                            // 5. Description: 1300ms - 1800ms (0.41 - 0.56)
                            final descriptionProgress = const Interval(
                              0.41,
                              0.56,
                              curve: Curves.easeOut,
                            ).transform(progress);

                            // 6. Statistics: 1800ms - 2500ms (0.56 - 0.78)
                            final statsProgress = const Interval(
                              0.56,
                              0.78,
                              curve: Curves.easeOut,
                            ).transform(progress);

                            // 7. Footer: 2500ms - 3000ms (0.78 - 0.94)
                            final footerProgress = const Interval(
                              0.78,
                              0.94,
                              curve: Curves.easeOut,
                            ).transform(progress);

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Brand Header at the top
                                AnimatedBrandHeader(
                                  animationProgress: brandProgress,
                                ),

                                // Central Hero + Statistics Cluster
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 36.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedHeroSection(
                                        eyebrowProgress: eyebrowProgress,
                                        headingLine1Progress: heading1Progress,
                                        headingLine2Progress: heading2Progress,
                                        descriptionProgress: descriptionProgress,
                                      ),
                                      const SizedBox(height: 42),
                                      AnimatedStatistics(
                                        progress: statsProgress,
                                      ),
                                    ],
                                  ),
                                ),

                                // Footer at bottom with Get Started / Sign In link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    AnimatedFooter(
                                      progress: footerProgress,
                                    ),
                                    Opacity(
                                      opacity: footerProgress,
                                      child: GestureDetector(
                                        onTap: _navigateToLogin,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: const Color(0xFF818CF8).withValues(alpha: 0.5),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Text(
                                                'Sign in',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
