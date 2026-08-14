import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'url_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const UrlSetupScreen(),
            transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo image with fallback
              Image.asset(
                'assets/images/app_logo.png',
                width: 100,
                height: 100,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.track_changes, 
                  size: 100, 
                  color: Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'LIVE TRACKER',
                style: GoogleFonts.shareTechMono(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'TACTICAL OVERWATCH',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  letterSpacing: 6,
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 60), // Spacer untuk mendorong watermark agak ke bawah
              Text(
                'FORGED BY KADHAFIINL',
                style: GoogleFonts.shareTechMono(
                  fontSize: 10,
                  letterSpacing: 3,
                  color: Colors.white.withValues(alpha: 0.3), // Halus, tidak mencolok
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
