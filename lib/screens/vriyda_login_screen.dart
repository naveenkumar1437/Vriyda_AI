import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../widgets/animated_background.dart';
import '../widgets/animated_grid.dart';
import '../widgets/floating_particles.dart';
import '../widgets/forgot_password_dialog.dart';
import 'chairman_dashboard_screen.dart';
import 'change_password_screen.dart';
import 'principal_dashboard_screen.dart';

/// Pixel-perfect Flutter replica of the Stitch role-based web/mobile login screen
/// connected to real Vriyda Mobile API (Part A - Login, Refresh, Profile, Forgot Password, Change Password).
class VriydaLoginScreen extends StatefulWidget {
  const VriydaLoginScreen({super.key});

  @override
  State<VriydaLoginScreen> createState() => _VriydaLoginScreenState();
}

class _VriydaLoginScreenState extends State<VriydaLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _rememberDevice = false;
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _cardEntranceController;
  late final Animation<double> _cardScaleAnimation;
  late final Animation<double> _cardFadeAnimation;
  late final Animation<Offset> _cardSlideAnimation;

  @override
  void initState() {
    super.initState();
    _cardEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _cardFadeAnimation = CurvedAnimation(
      parent: _cardEntranceController,
      curve: Curves.easeOut,
    );

    _cardScaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardEntranceController,
        curve: Curves.easeOutBack,
      ),
    );

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cardEntranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _cardEntranceController.forward();
  }

  @override
  void dispose() {
    _cardEntranceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email/username and password');
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await AuthService.login(
      email: email,
      password: password,
      rememberMe: _rememberDevice,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success && res.data != null) {
      final user = res.data!;

      // Check if role is owner, chairman, or principal
      if (!user.isOwner && !user.isPrincipal) {
        await SessionManager.clear();
        if (!mounted) return;
        _showRoleUnderDevelopmentDialog();
        return;
      }

      // Check if user must change password first
      if (user.mustChangePassword) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChangePasswordScreen(user: user),
          ),
        );
        return;
      }

      // Route by role
      if (user.isPrincipal) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PrincipalDashboardScreen(user: user),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChairmanDashboardScreen(user: user),
          ),
        );
      }
      return;
    } else {
      setState(() => _errorMessage = res.message);
    }
  }

  void _showRoleUnderDevelopmentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 26.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  color: Color(0xFFF59E0B),
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Role Under Development',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Urbanist',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This role is under development. Please use the web portal to login.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  height: 1.45,
                  fontFamily: 'Urbanist',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openForgotPassword() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (_) => ForgotPasswordDialog(
        initialEmail: _emailController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12163B),
      body: AnimatedBackground(
        child: Stack(
          children: [
            const Positioned.fill(child: VriydaAnimatedGrid(opacity: 0.7)),
            const Positioned.fill(child: FloatingParticles(count: 22)),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top App Header (Previous header texts & branding)
                        _buildTopHeader(),

                        const SizedBox(height: 24),

                        // Main Authentication Card (Glossy / Glassy type middle card)
                        FadeTransition(
                          opacity: _cardFadeAnimation,
                          child: SlideTransition(
                            position: _cardSlideAnimation,
                            child: ScaleTransition(
                              scale: _cardScaleAnimation,
                              child: _buildLoginCard(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Footer (Previous footer texts & copyright)
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Pill Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 1,
                ),
              ),
              child: const Text(
                'Version 1.0',
                style: TextStyle(
                  color: Color(0xFFC7D2FE),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // Brand Logo & Identity
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    Color(0xFF4F46E5),
                    Color(0xFF818CF8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.home_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Vriyda Portal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'A calmer way to run your campus',
                  style: TextStyle(
                    color: Color(0xFFA5B4FC),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    const cardRadius = 32.0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          // Soft cyan glow on top-left side
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(-3, -3),
          ),
          // Soft purple glow on bottom-right side
          BoxShadow(
            color: const Color(0xFFA855F7).withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(3, 6),
          ),
          // Subtle outer shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        foregroundPainter: const _GradientBorderPainter(
          strokeWidth: 1.2,
          radius: cardRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF38BDF8), // luminous cyan on top-left
              Color(0xFF818CF8), // periwinkle
              Color(0xFFC084FC), // light violet
              Color(0xFFA855F7), // purple on bottom-right
            ],
            stops: [0.0, 0.35, 0.70, 1.0],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.10), // ultra-subtle transparent navy tint (~90% transparent)
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.08), // subtle specular glass sheen at top-left
                    Colors.white.withValues(alpha: 0.02),
                    const Color(0xFF0F172A).withValues(alpha: 0.12),
                  ],
                  stops: const [0.0, 0.40, 1.0],
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.22), // small inner white highlight along border
                    width: 1.0,
                  ),
                  left: BorderSide(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 0.8,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Text
                    const Text(
                      'UNIVERSAL PORTAL',
                      style: TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Welcome back.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFF87171), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFFCA5A5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),

                    // Username Capsule Pill Field
                    ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: const Color(0xFF818CF8).withValues(alpha: 0.28),
                              width: 1.0,
                            ),
                          ),
                          child: Center(
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Username',
                                hintStyle: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14),
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    color: Color(0xFFCBD5E1),
                                    size: 21,
                                  ),
                                ),
                                prefixIconConstraints: BoxConstraints(minWidth: 48, minHeight: 48),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Password Capsule Pill Field with Visibility Toggle
                    ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: const Color(0xFF818CF8).withValues(alpha: 0.28),
                              width: 1.0,
                            ),
                          ),
                          child: Center(
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleSignIn(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14),
                                  child: Icon(
                                    Icons.lock_outline_rounded,
                                    color: Color(0xFFCBD5E1),
                                    size: 21,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: const Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                                prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Forgot password link (Right-aligned under password)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _openForgotPassword,
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: Color(0xFF818CF8),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Keep me signed in
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() => _rememberDevice = !_rememberDevice);
                          },
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _rememberDevice ? Colors.white : Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: _rememberDevice ? Colors.white : Colors.white.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                            ),
                            child: _rememberDevice
                                ? const Icon(Icons.check, color: Color(0xFF6366F1), size: 13.5)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 9),
                        GestureDetector(
                          onTap: () {
                            setState(() => _rememberDevice = !_rememberDevice);
                          },
                          child: const Text(
                            'Keep me signed in on this device',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Sign in CTA (Radiant Stadium Capsule Gradient Button)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFFD946EF), // vivid magenta
                              Color(0xFF9333EA), // vibrant purple
                              Color(0xFF3B82F6), // electric blue
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9333EA).withValues(alpha: 0.40),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignIn,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'Sign in',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Need help? ',
              style: TextStyle(
                color: Color(0xFFA5B4FC),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Contact support',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF818CF8),
                decorationThickness: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.only(top: 14),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
          ),
          child: const Center(
            child: Text(
              '© 2026 Vriyda Portal',
              style: TextStyle(
                color: Color(0xFF818CF8),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double strokeWidth;
  final double radius;
  final Gradient gradient;

  const _GradientBorderPainter({
    required this.strokeWidth,
    required this.radius,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = gradient.createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) => false;
}

