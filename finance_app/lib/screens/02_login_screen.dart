import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '03_dashboard_screen.dart';
import '06_employee_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _rememberMe = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  // OTP Login State
  bool _isOtpMode = false;
  bool _otpSent = false;
  String _maskedEmail = '';
  int _resendCountdown = 60;
  Timer? _resendTimer;

  late AnimationController _loginAnimController;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoFadeAnim;
  late Animation<Offset> _formSlideAnim;
  late Animation<double> _formFadeAnim;
  late Animation<double> _buttonScaleAnim;

  @override
  void initState() {
    super.initState();
    _loginAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _loginAnimController, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );
    _logoFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loginAnimController, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    _formSlideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _loginAnimController, curve: const Interval(0.25, 0.8, curve: Curves.easeOutCubic)),
    );
    _formFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loginAnimController, curve: const Interval(0.25, 0.7, curve: Curves.easeIn)),
    );

    _buttonScaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _loginAnimController, curve: const Interval(0.55, 1.0, curve: Curves.easeOutBack)),
    );

    _loginAnimController.forward();
    _checkExistingSession();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _loginAnimController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 60;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkExistingSession() async {
    final isAuth = await AuthService.isAuthenticated();
    final username = await AuthService.getCurrentUsername();
    if (isAuth && username.isNotEmpty && mounted) {
      final role = await AuthService.getUserRole();
      if (!mounted) return;
      if (role == 'FOUNDER' || role == 'ADMIN') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FounderDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EmployeeDashboardScreen()),
        );
      }
    }
  }

  Future<void> _handlePasswordLogin() async {
    final input = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email/username and password';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final role = await AuthService.authenticateUser(input, password);

    setState(() {
      _isLoading = false;
    });

    if (role != null && mounted) {
      if (role == 'FOUNDER' || role == 'ADMIN') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FounderDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EmployeeDashboardScreen()),
        );
      }
    } else if (mounted) {
      setState(() {
        _errorMessage = 'Invalid email/username or password. Access Denied.';
      });
    }
  }

  Future<void> _handleSendOtp() async {
    final input = _emailController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email or username to receive OTP';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await AuthService.sendOtp(input);

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      setState(() {
        _otpSent = true;
        _maskedEmail = result['email'] ?? input;
        _successMessage = result['message'] ?? 'OTP has been sent to your email';
        _errorMessage = null;
      });
      _startResendCountdown();
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to send OTP. Please check your credentials.';
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final input = _emailController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length < 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit OTP';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final role = await AuthService.verifyOtpAndLogin(input, otp);

    setState(() {
      _isLoading = false;
    });

    if (role != null && mounted) {
      if (role == 'FOUNDER' || role == 'ADMIN') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FounderDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EmployeeDashboardScreen()),
        );
      }
    } else if (mounted) {
      setState(() {
        _errorMessage = 'Invalid or expired OTP. Please check the code and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: Stack(
        children: [
          // 1. Dynamic Fintech & Security Ambient Background
          Positioned.fill(
            child: CustomPaint(
              painter: _FintechBackgroundPainter(),
            ),
          ),

          // Glowing ambient orbs
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF5000).withValues(alpha: 0.16),
                    const Color(0xFFFF8A52).withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -70,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6D00).withValues(alpha: 0.13),
                    const Color(0xFFFFB38A).withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Centered Login Interface (Full Width, No Card Container)
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40,
                    ),
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 390),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. Prominent DT7 Brand Logo (Enlarged) with Entry Scale & Fade
                            FadeTransition(
                              opacity: _logoFadeAnim,
                              child: ScaleTransition(
                                scale: _logoScaleAnim,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF5000).withValues(alpha: 0.08),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const AppLogo(height: 100),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 2. Heading Titles & Form Fields with Staggered Slide & Fade
                            FadeTransition(
                              opacity: _formFadeAnim,
                              child: SlideTransition(
                                position: _formSlideAnim,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isOtpMode ? 'OTP Verification' : 'Welcome Back!',
                                      style: const TextStyle(
                                        fontSize: 27,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1F2937),
                                        letterSpacing: -0.6,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _isOtpMode
                                          ? (_otpSent
                                              ? 'Enter the 6-digit OTP code sent to your email'
                                              : 'Sign in instantly using a one-time email code')
                                          : 'Sign in to access your DT7 finance portal',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),

                                    // 3. Login Mode Toggle Pills (Password vs OTP)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.grey.shade300, width: 1),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _isOtpMode = false;
                                                  _errorMessage = null;
                                                  _successMessage = null;
                                                });
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                padding: const EdgeInsets.symmetric(vertical: 9),
                                                decoration: BoxDecoration(
                                                  color: !_isOtpMode ? Colors.white : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(10),
                                                  boxShadow: !_isOtpMode
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.black.withValues(alpha: 0.08),
                                                            blurRadius: 6,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ]
                                                      : [],
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.key_rounded,
                                                      size: 16,
                                                      color: !_isOtpMode ? const Color(0xFFFF5000) : Colors.grey.shade600,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        'Password',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: !_isOtpMode ? FontWeight.bold : FontWeight.w600,
                                                          color: !_isOtpMode ? const Color(0xFF1F2937) : Colors.grey.shade600,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _isOtpMode = true;
                                                  _errorMessage = null;
                                                  _successMessage = null;
                                                });
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                padding: const EdgeInsets.symmetric(vertical: 9),
                                                decoration: BoxDecoration(
                                                  color: _isOtpMode ? Colors.white : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(10),
                                                  boxShadow: _isOtpMode
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.black.withValues(alpha: 0.08),
                                                            blurRadius: 6,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ]
                                                      : [],
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.mark_email_read_rounded,
                                                      size: 16,
                                                      color: _isOtpMode ? const Color(0xFFFF5000) : Colors.grey.shade600,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        'Email OTP',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: _isOtpMode ? FontWeight.bold : FontWeight.w600,
                                                          color: _isOtpMode ? const Color(0xFF1F2937) : Colors.grey.shade600,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
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
                                    const SizedBox(height: 20),

                                    // 4. Success Banner (if any)
                                    if (_successMessage != null) ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0FDF4),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: const Color(0xFFBBF7D0)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _successMessage!,
                                                style: const TextStyle(
                                                  color: Color(0xFF15803D),
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // 5. Error Banner (if any)
                                    if (_errorMessage != null) ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: const Color(0xFFFECACA)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _errorMessage!,
                                                style: const TextStyle(
                                                  color: Color(0xFFDC2626),
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // 6. Dynamic Form Inputs based on Mode
                                    if (!_isOtpMode) ...[
                                      // PASSWORD LOGIN MODE
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Email or Username',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: Color(0xFF374151),
                                            ),
                                          ),
                                          const SizedBox(height: 7),
                                          TextFormField(
                                            controller: _emailController,
                                            keyboardType: TextInputType.emailAddress,
                                            style: const TextStyle(fontSize: 14.5, color: Color(0xFF1F2937), fontWeight: FontWeight.w500),
                                            decoration: InputDecoration(
                                              hintText: 'Enter your username or email',
                                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                                              filled: true,
                                              fillColor: Colors.white,
                                              prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFFFF5000), size: 19),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: const BorderSide(color: Color(0xFFFF5000), width: 1.8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),

                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Password',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: Color(0xFF374151),
                                            ),
                                          ),
                                          const SizedBox(height: 7),
                                          TextFormField(
                                            controller: _passwordController,
                                            obscureText: _obscurePassword,
                                            style: const TextStyle(fontSize: 14.5, color: Color(0xFF1F2937), fontWeight: FontWeight.w500),
                                            decoration: InputDecoration(
                                              hintText: 'Enter your password',
                                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                                              filled: true,
                                              fillColor: Colors.white,
                                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFFF5000), size: 19),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                  color: Colors.grey.shade500,
                                                  size: 20,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _obscurePassword = !_obscurePassword;
                                                  });
                                                },
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: const BorderSide(color: Color(0xFFFF5000), width: 1.8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),

                                      // Remember Me & Forgot Password
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: InkWell(
                                              onTap: () => setState(() => _rememberMe = !_rememberMe),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child: Checkbox(
                                                        value: _rememberMe,
                                                        activeColor: AppColors.primary,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                                        onChanged: (val) => setState(() => _rememberMe = val ?? true),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        'Remember me',
                                                        style: TextStyle(
                                                          fontSize: 12.5,
                                                          fontWeight: FontWeight.w500,
                                                          color: Colors.grey.shade700,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _isOtpMode = true;
                                              });
                                            },
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: const Text(
                                              'Forgot Password?',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else if (!_otpSent) ...[
                                      // OTP REQUEST STEP
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Registered Email or Username',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: Color(0xFF374151),
                                            ),
                                          ),
                                          const SizedBox(height: 7),
                                          TextFormField(
                                            controller: _emailController,
                                            keyboardType: TextInputType.emailAddress,
                                            style: const TextStyle(fontSize: 14.5, color: Color(0xFF1F2937), fontWeight: FontWeight.w500),
                                            decoration: InputDecoration(
                                              hintText: 'Enter Your E-mail',
                                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                                              filled: true,
                                              fillColor: Colors.white,
                                              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFF5000), size: 20),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: const BorderSide(color: Color(0xFFFF5000), width: 1.8),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'We will send a 6-digit OTP code to your registered email address.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      // OTP CODE VERIFICATION STEP
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF7ED),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFFFEDD5)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.mark_email_read_outlined, color: Color(0xFFFF5000), size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Code sent to $_maskedEmail',
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF9A3412),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _otpSent = false;
                                                  _otpController.clear();
                                                  _errorMessage = null;
                                                  _successMessage = null;
                                                });
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                child: Text(
                                                  'Edit',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFFF5000),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '6-Digit OTP Code',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: Color(0xFF374151),
                                            ),
                                          ),
                                          const SizedBox(height: 7),
                                          TextFormField(
                                            controller: _otpController,
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly,
                                              LengthLimitingTextInputFormatter(6),
                                            ],
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 10,
                                              color: Color(0xFF1F2937),
                                            ),
                                            decoration: InputDecoration(
                                              hintText: '------',
                                              hintStyle: TextStyle(
                                                color: Colors.grey.shade300,
                                                letterSpacing: 10,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w900,
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              prefixIcon: const Icon(Icons.pin_rounded, color: Color(0xFFFF5000), size: 20),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: const BorderSide(color: Color(0xFFFF5000), width: 1.8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Resend OTP Row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              _resendCountdown > 0
                                                  ? 'Resend code in ${_resendCountdown}s'
                                                  : 'Didn\'t receive code?',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: (_resendCountdown == 0 && !_isLoading) ? _handleSendOtp : null,
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text(
                                              'Resend OTP',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _resendCountdown == 0 ? const Color(0xFFFF5000) : Colors.grey.shade400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 7. Vibrant Primary Action Button with Scale Entry
                            ScaleTransition(
                              scale: _buttonScaleAnim,
                              child: SizedBox(
                                width: double.infinity,
                                height: 54,
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
                                        color: const Color(0xFFFF5000).withValues(alpha: 0.35),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : (!_isOtpMode
                                            ? _handlePasswordLogin
                                            : (!_otpSent ? _handleSendOtp : _handleVerifyOtp)),
                                    child: _isLoading
                                        ? const Center(
                                            child: SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                            ),
                                          )
                                        : Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Center(
                                                child: Text(
                                                  !_isOtpMode
                                                      ? 'Sign In'
                                                      : (!_otpSent ? 'Send OTP Code' : 'Verify & Sign In'),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                right: 12,
                                                child: Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.22),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    !_isOtpMode
                                                        ? Icons.arrow_forward_rounded
                                                        : (!_otpSent ? Icons.send_rounded : Icons.check_rounded),
                                                    color: Colors.white,
                                                    size: 17,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),

                            // 8. Security Trust Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shield_outlined, size: 14, color: Colors.grey.shade400),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '256-bit Secure Encryption • DT7 Finance',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
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
    );
  }
}

/// Custom Background Painter for Fintech theme with subtle financial curves & grid pattern
class _FintechBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFFFF5000).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 1. Subtle financial wave line 1
    final path1 = Path();
    path1.moveTo(0, size.height * 0.22);
    path1.cubicTo(
      size.width * 0.35,
      size.height * 0.18,
      size.width * 0.65,
      size.height * 0.26,
      size.width,
      size.height * 0.19,
    );
    canvas.drawPath(path1, paintLine);

    // 2. Subtle financial wave line 2
    final path2 = Path();
    path2.moveTo(0, size.height * 0.78);
    path2.cubicTo(
      size.width * 0.3,
      size.height * 0.84,
      size.width * 0.7,
      size.height * 0.72,
      size.width,
      size.height * 0.79,
    );
    canvas.drawPath(path2, paintLine);

    // 3. Subtle grid dots in top-left & bottom-right
    final dotPaint = Paint()
      ..color = const Color(0xFFFF5000).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    const int cols = 5;
    const int rows = 5;
    const double spacing = 18.0;

    // Top-left dot cluster
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawCircle(Offset(20.0 + c * spacing, 60.0 + r * spacing), 1.5, dotPaint);
      }
    }

    // Bottom-right dot cluster
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawCircle(
          Offset(size.width - 20.0 - (cols - 1 - c) * spacing, size.height - 80.0 - (rows - 1 - r) * spacing),
          1.5,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
