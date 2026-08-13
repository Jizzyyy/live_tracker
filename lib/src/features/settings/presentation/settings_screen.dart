import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../../room/providers/room_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ref.read(settingsProvider));
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Server WebSocket URL',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              hintText: 'ws://192.168.x.x:8080',
              border: OutlineInputBorder(),
              helperText: 'Restart koneksi setelah mengubah URL',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final newUrl = _urlController.text.trim();
              if (newUrl.isNotEmpty) {
                ref.read(settingsProvider.notifier).updateServerUrl(newUrl);
                // Safe reconnect: leave room first if connected
                ref.read(roomProvider.notifier).reconnect(newUrl);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL tersimpan. Menghubungkan ulang...')),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Simpan & Hubungkan'),
          ),
        ],
      ),
    );
  }
}
