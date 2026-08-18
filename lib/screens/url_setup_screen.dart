import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tracker_providers.dart';
import '../utils/ui_helpers.dart';
import 'live_tracker_screen.dart';

class UrlSetupScreen extends ConsumerStatefulWidget {
  const UrlSetupScreen({super.key});

  @override
  ConsumerState<UrlSetupScreen> createState() => _UrlSetupScreenState();
}

class _UrlSetupScreenState extends ConsumerState<UrlSetupScreen> {
  late final TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: ref.read(appSettingsProvider).serverUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: PremiumGlass(
              padding: const EdgeInsets.all(32),
              borderRadius: BorderRadius.circular(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.1)
                          : const Color(0xFF0284C7).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.satellite_alt, 
                      size: 48, 
                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'SERVER UPLINK',
                    style: GoogleFonts.shareTechMono(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: isDark ? Colors.white : const Color(0xFF0D1117),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Masukkan URL Ngrok atau server cloud Anda untuk menginisialisasi sistem pelacakan.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white60 : const Color(0xFF64748B), 
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _urlCtrl,
                    style: GoogleFonts.jetBrainsMono(
                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'WebSocket URL',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      hintText: 'wss://xxxx.ngrok.app',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.black38 : const Color(0xFFF1F5F9),
                      prefixIcon: Icon(
                        Icons.link, 
                        color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                        foregroundColor: isDark ? Colors.black : Colors.white,
                      ),
                      onPressed: () {
                        final url = _urlCtrl.text.trim();
                        if (url.isNotEmpty) {
                          final settings = ref.read(appSettingsProvider);
                          ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(serverUrl: url));
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LiveTrackerScreen()),
                          );
                        }
                      },
                      child: Text(
                        'INITIALIZE CONNECTION',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
