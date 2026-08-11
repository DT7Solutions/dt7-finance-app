import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '02_login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/founder_avatar.png'), context);
    precacheImage(const AssetImage('assets/images/dt7_logo.png'), context);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: GestureDetector(
        onTap: _navigateToLogin,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SizedBox.expand(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Centered Official DT7 AGENCY Logo
                    _buildCenteredLogo(),

                    const Spacer(flex: 2),

                    // Centered 3D Hero Illustration (Transparent Background)
                    _buildCenteredHero(),

                    const Spacer(flex: 2),

                    // Headline Title
                    const Text(
                      'Finance Management\nApp',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1E1E),
                        height: 1.25,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tagline Subtitle
                    const Text(
                      'Manage. Track. Grow.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF5000),
                        letterSpacing: 0.2,
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Pagination Indicators
                    _buildPaginationIndicator(),

                    const SizedBox(height: 24),

                    // Get Started Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _navigateToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5000),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: const Color(0xFFFF5000).withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Stack(
                          alignment: Alignment.center,
                          children: [
                            Center(
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
                              right: 16,
                              child: Icon(Icons.arrow_forward_rounded, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredLogo() {
    return const AppLogo(height: 135);
  }

  Widget _buildCenteredHero() {
    return Center(
      child: Image.asset(
        'assets/images/splash_hero.png',
        height: 230,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => SizedBox(
          height: 220,
          width: 290,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 250,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              Positioned(
                right: 55,
                bottom: 45,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBar(14, 38, const Color(0xFFFFD5C0)),
                    const SizedBox(width: 6),
                    _buildBar(14, 56, const Color(0xFFFFB38A)),
                    const SizedBox(width: 6),
                    _buildBar(14, 76, const Color(0xFFFF8B52)),
                  ],
                ),
              ),
              Positioned(
                right: 40,
                top: 20,
                width: 140,
                height: 90,
                child: CustomPaint(
                  painter: GrowthArrowPainter(),
                ),
              ),
              Positioned(
                left: 30,
                bottom: 40,
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
                  width: 150,
                  height: 100,
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
                right: 32,
                bottom: 30,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6D00), Color(0xFFFF5000)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: const Center(
                    child: Text(
                      '₹',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
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
