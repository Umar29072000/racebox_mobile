import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;

  late AnimationController _rpmController;
  late Animation<double> _rpmAnimation;

  int _stepIndex = 0;
  Timer? _stepTimer;
  Timer? _navTimer;

  final List<String> _diagnosticSteps = [
    'MEMERIKSA SENSOR IMU 100Hz (AKSELEROMETER & GYRO)...',
    'MENGHUBUNGKAN GNSS HIGH-RATE SATELLITE ENGINE...',
    'MEMUAT PROFIL BALAP: VARIO 160 BORE-UP...',
    'SISTEM ANTI-GETAR MESIN AKTIF (4.0G DEFAULT)...',
    'MIWAR 205 RACING TELEMETRY SIAP GAS! ⚡',
  ];

  @override
  void initState() {
    super.initState();

    // 1. Logo scale & fade animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _logoScaleAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );
    _logoFadeAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );

    // 2. Tachometer RPM sweep (0 -> 13,500 RPM)
    _rpmController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _rpmAnimation = Tween<double>(begin: 0.0, end: 13500.0).animate(
      CurvedAnimation(parent: _rpmController, curve: Curves.easeInOutCubic),
    );

    _logoController.forward();
    _rpmController.forward();

    // 3. Telemetry Diagnostic Steps
    _stepTimer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
      if (mounted) {
        setState(() {
          if (_stepIndex < _diagnosticSteps.length - 1) {
            _stepIndex++;
          }
        });
      }
    });

    // 4. Auto navigate to Main Navigation after 2.6 seconds
    _navTimer = Timer(const Duration(milliseconds: 2600), _navigateToMain);
  }

  void _navigateToMain() {
    if (!mounted) return;
    _stepTimer?.cancel();
    _navTimer?.cancel();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: const MainNavigationScreen(),
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _navTimer?.cancel();
    _logoController.dispose();
    _rpmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateToMain, // Tap anywhere to skip
        child: Stack(
          children: [
            // Ambient Radial Background Glow
            Positioned(
              top: MediaQuery.of(context).size.height * 0.15,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan.withValues(alpha: 0.12),
                        blurRadius: 90.0,
                        spreadRadius: 30.0,
                      ),
                      BoxShadow(
                        color: AppColors.orange.withValues(alpha: 0.08),
                        blurRadius: 120.0,
                        spreadRadius: 40.0,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Bar: System Chip & Skip Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt, color: AppColors.cyan, size: 14.0),
                              SizedBox(width: 4.0),
                              Text(
                                'TELEMETRY V1.0',
                                style: TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _navigateToMain,
                          child: const Text(
                            'LEWATI ❯',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Center: Racing Logo & Title
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _logoScaleAnimation,
                          child: FadeTransition(
                            opacity: _logoFadeAnimation,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.85,
                              height: 110.0,
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.speed, size: 70.0, color: AppColors.cyan),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        const Text(
                          'RACEBOX MOBILE',
                          style: TextStyle(
                            fontSize: 26.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.0,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        const Text(
                          '100Hz Sensor Fusion • Offline-First GPS Drag Timer',
                          style: TextStyle(
                            fontSize: 11.0,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    // Bottom: Animated RPM Tachometer & Diagnostics
                    Column(
                      children: [
                        // Animated Tachometer Gauge Bar
                        AnimatedBuilder(
                          animation: _rpmAnimation,
                          builder: (context, _) {
                            final rpm = _rpmAnimation.value;
                            final progress = (rpm / 14000.0).clamp(0.0, 1.0);
                            final isRedline = rpm >= 10500;

                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'TACHOMETER ENGINE',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '${rpm.toInt()} ',
                                          style: TextStyle(
                                            color: isRedline ? AppColors.red : AppColors.cyan,
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        Text(
                                          'RPM',
                                          style: TextStyle(
                                            color: isRedline ? AppColors.red : AppColors.textSecondary,
                                            fontSize: 10.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8.0),
                                // Multi-segment Tachometer Strip
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6.0),
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 8.0,
                                        color: AppColors.surface,
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: progress,
                                        child: Container(
                                          height: 8.0,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.green,
                                                AppColors.cyan,
                                                AppColors.yellow,
                                                AppColors.red,
                                              ],
                                              stops: const [0.0, 0.5, 0.75, 1.0],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (isRedline ? AppColors.red : AppColors.cyan).withValues(alpha: 0.6),
                                                blurRadius: 8.0,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 14.0),

                        // Diagnostics Text Console Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 14.0,
                                height: 14.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: _stepIndex == _diagnosticSteps.length - 1
                                      ? AppColors.green
                                      : AppColors.cyan,
                                ),
                              ),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: Text(
                                  _diagnosticSteps[_stepIndex],
                                  style: TextStyle(
                                    color: _stepIndex == _diagnosticSteps.length - 1
                                        ? AppColors.green
                                        : AppColors.textSecondary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
