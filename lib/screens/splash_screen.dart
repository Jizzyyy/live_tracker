import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tracker_providers.dart';
import '../utils/app_theme.dart';
import 'live_tracker_screen.dart';
import 'url_setup_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _pulseAnimation;

  String _statusText = 'Menginisialisasi subsistem GPS...';
  double _loadProgress = 0.25;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _runStartupSequence();
  }

  void _runStartupSequence() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _statusText = 'Memeriksa protokol koneksi konvoi...';
      _loadProgress = 0.65;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _statusText = 'Radar taktis aktif • Memuat peta...';
      _loadProgress = 1.0;
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final serverUrl = ref.read(appSettingsProvider).serverUrl;
    final Widget nextScreen = (serverUrl.isNotEmpty && (serverUrl.startsWith('ws://') || serverUrl.startsWith('wss://')))
        ? const LiveTrackerScreen()
        : const UrlSetupScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => nextScreen,
        transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCanvas,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo with animated glowing radar pulse
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryCyan.withValues(alpha: 0.25),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  );
                },
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 96,
                  height: 96,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.track_changes,
                    size: 96,
                    color: AppTheme.primaryCyan,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'LIVE TRACKER',
                style: GoogleFonts.shareTechMono(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'TACTICAL OVERWATCH',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: AppTheme.primaryCyan.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 36),

              // Tactical Loading Progress Bar
              Container(
                width: 200,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: _loadProgress),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, val, _) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: val,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryCyan,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryCyan.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Animated Stepper Status Text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _statusText,
                  key: ValueKey(_statusText),
                  style: GoogleFonts.shareTechMono(
                    fontSize: 11,
                    letterSpacing: 0.8,
                    color: Colors.white60,
                  ),
                ),
              ),

              const SizedBox(height: 48),
              Text(
                'CREATED BY KADHAFIINL',
                style: GoogleFonts.shareTechMono(
                  fontSize: 10,
                  letterSpacing: 3,
                  color: Colors.white30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
