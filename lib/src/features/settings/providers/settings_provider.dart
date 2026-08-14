import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kServerUrlKey = 'server_url';
// Default to the user's actual LAN IP for easier testing on physical device
const _kDefaultUrl = 'ws://192.168.18.13:8080';

class SettingsNotifier extends StateNotifier<String> {
  SettingsNotifier(this._prefs) : super(_prefs.getString(_kServerUrlKey) ?? _kDefaultUrl);

  final SharedPreferences _prefs;

  Future<void> updateServerUrl(String url) async {
    state = url;
    await _prefs.setString(_kServerUrlKey, url);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
