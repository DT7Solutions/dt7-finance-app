import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_logo.dart';
import '02_login_screen.dart';
import '03_dashboard_screen.dart';
import '06_employee_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _introController;
  late AnimationController _pulseController;

  // Staggered Animations
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoFadeAnim;
  late Animation<Offset> _heroSlideAnim;
  late Animation<double> _heroScaleAnim;
  late Animation<double> _heroFadeAnim;
  late Animation<Offset> _textSlideAnim;
  late Animation<double> _textFadeAnim;
  late Animation<double> _buttonScaleAnim;
  late Animation<double> _buttonFadeAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;

  bool _navigated = false;
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();

    // 1. Initial Cinematic Intro Controller
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    // 2. Continuous Floating & Breathing Controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Logo Animations (0% -> 40%)
    _logoScaleAnim = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _logoFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    // Hero Illustration Animations (20% -> 65%)
    _heroSlideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.2, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _heroScaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.2, 0.65, curve: Curves.easeOutBack),
      ),
    );
    _heroFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.2, 0.55, curve: Curves.easeIn),
      ),
    );

    // Text & Tagline Animations (45% -> 80%)
    _textSlideAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.45, 0.80, curve: Curves.easeOutCubic),
      ),
    );
    _textFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.45, 0.75, curve: Curves.easeIn),
      ),
    );

    // Button & Indicators Animations (65% -> 100%)
    _buttonScaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _buttonFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.65, 0.95, curve: Curves.easeIn),
      ),
    );

    // Continuous Floating animations
    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
    _pulseAnim = Tween<double>(begin: 0.12, end: 0.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _introController.forward();

    _sessionTimer = Timer(const Duration(milliseconds: 1400), () {
      _checkExistingSession();
    });
  }

  Future<void> _checkExistingSession() async {
    if (!mounted || _navigated) return;

    final isAuth = await AuthService.isAuthenticated();
    final username = await AuthService.getCurrentUsername();

    if (isAuth && username.isNotEmpty && mounted && !_navigated) {
      _navigated = true;
      final role = await AuthService.getUserRole();
      if (!mounted) return;
      if (role == 'FOUNDER' || role == 'ADMIN') {
        Navigator.pushReplacement(
          context,
          _createSmoothRoute(const FounderDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          _createSmoothRoute(const EmployeeDashboardScreen()),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/founder_avatar.png'), context);
    precacheImage(const AssetImage('assets/images/dt7_logo.png'), context);
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _introController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Route _createSmoothRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnim = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curvedAnim,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  Future<void> _navigateToNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    final isAuth = await AuthService.isAuthenticated();
    final username = await AuthService.getCurrentUsername();

    if (isAuth && username.isNotEmpty && mounted) {
      final role = await AuthService.getUserRole();
      if (!mounted) return;
      if (role == 'FOUNDER' || role == 'ADMIN') {
        Navigator.pushReplacement(
          context,
          _createSmoothRoute(const FounderDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          _createSmoothRoute(const EmployeeDashboardScreen()),
        );
      }
    } else if (mounted) {
      Navigator.pushReplacement(
        context,
        _createSmoothRoute(const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: GestureDetector(
        onTap: _navigateToNext,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // 1. Ambient Pulsing Background Glow Orbs
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned(
                      top: -60,
                      right: -60,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFF5000).withValues(alpha: _pulseAnim.value),
                              const Color(0xFFFF8B52).withValues(alpha: _pulseAnim.value * 0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -80,
                      left: -80,
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFF6D00).withValues(alpha: _pulseAnim.value * 0.9),
                              const Color(0xFFFFB38A).withValues(alpha: _pulseAnim.value * 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // 2. Animated Splash Content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final heroHeight = (constraints.maxHeight * 0.28).clamp(130.0, 210.0);
                  final logoHeight = (constraints.maxHeight * 0.16).clamp(80.0, 125.0);

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 8),

                              // Animated Centered DT7 Logo
                              FadeTransition(
                                opacity: _logoFadeAnim,
                                child: ScaleTransition(
                                  scale: _logoScaleAnim,
                                  child: AppLogo(height: logoHeight),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Animated 3D Hero Illustration with Continuous Float
                              FadeTransition(
                                opacity: _heroFadeAnim,
                                child: SlideTransition(
                                  position: _heroSlideAnim,
                                  child: ScaleTransition(
                                    scale: _heroScaleAnim,
                                    child: AnimatedBuilder(
                                      animation: _floatAnim,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(0, _floatAnim.value),
                                          child: child,
                                        );
                                      },
                                      child: _buildCenteredHero(heroHeight),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Animated Headline Title & Tagline
                              FadeTransition(
                                opacity: _textFadeAnim,
                                child: SlideTransition(
                                  position: _textSlideAnim,
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Finance Management\nApp',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1E1E1E),
                                          height: 1.25,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF5000).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'Manage. Track. Grow.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFFF5000),
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Animated Pagination & Button
                              FadeTransition(
                                opacity: _buttonFadeAnim,
                                child: ScaleTransition(
                                  scale: _buttonScaleAnim,
                                  child: Column(
                                    children: [
                                      _buildPaginationIndicator(),
                                      const SizedBox(height: 18),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFFF5000), Color(0xFFFF7000)],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFF5000).withValues(alpha: 0.38),
                                                blurRadius: 18,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _navigateToNext,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                const Center(
                                                  child: Text(
                                                    'Get Started',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  right: 14,
                                                  child: Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.22),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.arrow_forward_rounded,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                  ),
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

                              const SizedBox(height: 8),
                            ],
                          ),
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

  Widget _buildCenteredHero([double height = 210.0]) {
    return Center(
      child: Image.asset(
        'assets/images/splash_hero.png',
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => SizedBox(
          height: height,
          width: height * 1.3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: height * 1.1,
                height: height * 0.7,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              Positioned(
                right: height * 0.24,
                bottom: height * 0.2,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBar(14, height * 0.18, const Color(0xFFFFD5C0)),
                    const SizedBox(width: 6),
                    _buildBar(14, height * 0.26, const Color(0xFFFFB38A)),
                    const SizedBox(width: 6),
                    _buildBar(14, height * 0.35, const Color(0xFFFF8B52)),
                  ],
                ),
              ),
              Positioned(
                right: height * 0.18,
                top: height * 0.1,
                width: height * 0.65,
                height: height * 0.42,
                child: CustomPaint(
                  painter: GrowthArrowPainter(),
                ),
              ),
              Positioned(
                left: height * 0.13,
                bottom: height * 0.18,
                child: SizedBox(
                  width: 50,
                  height: 70,
                  child: Stack(
                    children: [
                      Positioned(bottom: 0, child: _buildCoin()),
                      Positioned(bottom: 12, child: _buildCoin()),
                      Positioned(bottom: 24, child: _buildCoin()),
                      Positioned(bottom: 36, child: _buildCoin()),
                    ],
                  ),
                ),
              ),
              Positioned(
                child: Container(
                  width: height * 0.68,
                  height: height * 0.45,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6D00), Color(0xFFE64A19)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5000).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 15,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      Positioned(
                        right: 25,
                        top: 36,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD54F),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF8F00),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: height * 0.14,
                bottom: height * 0.14,
                child: Container(
                  width: height * 0.24,
                  height: height * 0.24,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6D00), Color(0xFFFF5000)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: Center(
                    child: Text(
                      '₹',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: (height * 0.11).clamp(16.0, 24.0),
                      ),
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

  Widget _buildBar(double width, double height, Color color) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildCoin() {
    return Container(
      width: 44,
      height: 18,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFFFE082), width: 1.5),
      ),
    );
  }

  Widget _buildPaginationIndicator() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 7,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5000),
              borderRadius: BorderRadius.circular(3.5),
            ),
          ),
          const SizedBox(width: 6),
          _buildDot(),
          const SizedBox(width: 6),
          _buildDot(),
          const SizedBox(width: 6),
          _buildDot(),
        ],
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: Color(0xFFFFCCA6),
        shape: BoxShape.circle,
      ),
    );
  }
}

class GrowthArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF5000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.85);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.75,
      size.width * 0.85,
      size.height * 0.15,
    );

    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..color = const Color(0xFFFF5000)
      ..style = PaintingStyle.fill;

    final arrowPath = Path();
    arrowPath.moveTo(size.width * 0.85, size.height * 0.15);
    arrowPath.lineTo(size.width * 0.68, size.height * 0.22);
    arrowPath.lineTo(size.width * 0.82, size.height * 0.38);
    arrowPath.close();

    canvas.drawPath(arrowPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
