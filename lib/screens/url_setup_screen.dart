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
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
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
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.satellite_alt, size: 48, color: Color(0xFF00E5FF)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'SERVER UPLINK',
                    style: GoogleFonts.shareTechMono(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Masukkan URL Ngrok atau server cloud Anda untuk menginisialisasi sistem pelacakan.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _urlCtrl,
                    style: GoogleFonts.jetBrainsMono(color: const Color(0xFF00E5FF)),
                    decoration: InputDecoration(
                      labelText: 'WebSocket URL',
                      labelStyle: const TextStyle(color: Colors.grey),
                      hintText: 'wss://xxxx.ngrok.app',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                      ),
                      filled: true,
                      fillColor: Colors.black45,
                      prefixIcon: const Icon(Icons.link, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        final url = _urlCtrl.text.trim();
                        if (url.isNotEmpty) {
                          final settings = ref.read(appSettingsProvider);
                          // Simpan URL ke SharedPreferences
                          ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(serverUrl: url));
                          
                          // Lanjut ke Map Screen (Provider RoomNotifier akan otomatis membaca URL baru ini saat diinisialisasi di MapScreen)
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
