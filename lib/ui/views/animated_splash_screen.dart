import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/language_provider.dart';
import 'home_dashboard_screen.dart';

/// Modern Animated Splash Screen for JC Digital Soil AI Analyzer
/// Displays animated branding logo, breathing glow effect, and dynamic system initialization status
class AnimatedSplashScreen extends StatefulWidget {
  final Duration displayDuration;
  final Widget? nextScreen;

  const AnimatedSplashScreen({
    super.key,
    this.displayDuration = const Duration(milliseconds: 2600),
    this.nextScreen,
  });

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _spinController;
  late AnimationController _fadeController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Timer? _statusTimer;
  Timer? _navigationTimer;
  int _statusStep = 0;

  static const List<String> _statusKeys = [
    'splashConnecting',
    'splashLoadingAi',
    'splashReady',
  ];

  @override
  void initState() {
    super.initState();

    // 1. Logo Breathing / Pulsing animation (Looping)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 6.0, end: 24.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 2. Futuristic Arc Ring Rotation (Looping)
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    // 3. Entrance Fade & Slide
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    // Dynamic status text update
    _statusTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted) {
        setState(() {
          _statusStep = (_statusStep + 1) % _statusKeys.length;
        });
      }
    });

    // Auto navigation to HomeDashboardScreen
    _navigationTimer = Timer(widget.displayDuration, _navigateToNextScreen);
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.nextScreen ?? const HomeDashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 650),
      ),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _navigationTimer?.cancel();
    _pulseController.dispose();
    _spinController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    LanguageProvider? lang;
    try {
      lang = Provider.of<LanguageProvider>(context);
    } catch (_) {
      lang = null;
    }
    final statusMessage = lang?.t(_statusKeys[_statusStep]) ??
        (_statusStep == 0
            ? 'กำลังเชื่อมต่อและเตรียมระบบเซนเซอร์...'
            : _statusStep == 1
                ? 'กำลังโหลดโมเดลปัญญาประดิษฐ์ JC-SoilNet PINN...'
                : 'เตรียมพร้อมวิเคราะห์คุณภาพดิน 8 พารามิเตอร์...');
    final subtitleText = lang?.t('splashSubtitle') ?? '8-in-1 Soil Telemetry & Analyzer';
    final labText = lang?.t('splashLab') ?? 'RBRU Digital Agriphysics Research Lab';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Ambient Background Glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.15),
                  radius: 0.85,
                  colors: [
                    Color(0xFF0F2B48), // Deep tech navy
                    Color(0xFF0B192A), // Dark slate
                    Color(0xFF070D14), // Pure deep dark background
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // 2. Central Animated Brand Card
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Logo with Pulsing Glow & Rotating Ring
                      AnimatedBuilder(
                        animation: Listenable.merge([_pulseController, _spinController]),
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer Rotating Cyber Ring
                              RotationTransition(
                                turns: _spinController,
                                child: Container(
                                  width: 172,
                                  height: 172,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const SweepGradient(
                                      colors: [
                                        Colors.transparent,
                                        Color(0xFF00E676), // Green accent
                                        Color(0xFF29B6F6), // Cyan accent
                                        Colors.transparent,
                                      ],
                                      stops: [0.0, 0.45, 0.75, 1.0],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF29B6F6).withValues(alpha: 0.25),
                                        blurRadius: _glowAnimation.value,
                                        spreadRadius: 1.0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Inner Pulsing Glow Backdrop
                              Container(
                                width: 148,
                                height: 148,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E676).withValues(alpha: 0.35),
                                      blurRadius: _glowAnimation.value * 1.3,
                                      spreadRadius: 2.0,
                                    ),
                                  ],
                                ),
                              ),

                              // Logo Container with Smooth Scale Animation
                              Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF80D8FF).withValues(alpha: 0.85),
                                      width: 2.5,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black54,
                                        blurRadius: 16,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/jc_digital_soil_ai_logo.jpg',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        // Fallback icon if logo image fails to load
                                        return Container(
                                          color: const Color(0xFF1565C0),
                                          child: const Icon(
                                            Icons.psychology_alt_rounded,
                                            size: 72,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // App Title Branding
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Colors.white,
                            Color(0xFFE0F7FA),
                            Color(0xFF80DEEA),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'JC DIGITAL SOIL AI',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.2,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF00E676).withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'EDGE PINN AI',
                              style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              subtitleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFB0BEC5),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // Futuristic Circular & Linear Progress Indicator
                      SizedBox(
                        width: 240,
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: const LinearProgressIndicator(
                                minHeight: 3.5,
                                backgroundColor: Color(0xFF1E293B),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF00E676),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Dynamic Status Message
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                statusMessage,
                                key: ValueKey<String>(statusMessage),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF90A4AE),
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Footer Research Attribution
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  labText,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF546E7A),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Physics-Informed Neural Network Calibration v2.2',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF37474F),
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
