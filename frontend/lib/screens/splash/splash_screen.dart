import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  final Duration delay;
  final VoidCallback? onFinished;

  const SplashScreen({
    super.key,
    this.delay = const Duration(milliseconds: 1800),
    this.onFinished,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) {
        if (widget.onFinished != null) {
          widget.onFinished!();
        } else {
          context.go(AppRoutes.dashboard);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.primary,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. ScamShield Logo (White Shield Icon with Checkmark)
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(24),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(50),
                    width: 2,
                  ),
                ),
                child: const ShieldLogoIcon(
                  size: 56,
                  shieldColor: Colors.white,
                  checkColor: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // 2. ScamShield Name
              const Text(
                'ScamShield',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              // 3. "AI + Blockchain Security"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withAlpha(60),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'AI + Blockchain Security',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 4. Tagline
              const Text(
                'Stay Safe, Stay Secure',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFC3D4FB),
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 54),

              // 5. Minimalistic Loading Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(index == 1 ? 255 : 120),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
