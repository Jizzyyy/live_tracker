import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/models/tracker_models.dart';
import 'package:live_tracker/l10n/app_strings.dart';

void main() {
  group('AppStrings & AppLanguage Tests', () {
    test('AppLanguage enum has correct labels and flags', () {
      expect(AppLanguage.id.label, 'Bahasa Indonesia');
      expect(AppLanguage.id.flag, '🇮🇩');
      expect(AppLanguage.en.label, 'English');
      expect(AppLanguage.en.flag, '🇬🇧');
    });

    test('Both ID and EN provide valid non-empty strings for UI keys', () {
      for (final lang in AppLanguage.values) {
        final s = AppStrings(lang);
        expect(s.appTitle.isNotEmpty, isTrue);
        expect(s.appSubtitle.isNotEmpty, isTrue);
        expect(s.speedLabel.isNotEmpty, isTrue);
        expect(s.autoPaused.isNotEmpty, isTrue);
        expect(s.groupTelemetry.isNotEmpty, isTrue);
        expect(s.startTracking.isNotEmpty, isTrue);
        expect(s.pause.isNotEmpty, isTrue);
        expect(s.finish.isNotEmpty, isTrue);
        expect(s.resume.isNotEmpty, isTrue);
        expect(s.routeSaved.isNotEmpty, isTrue);
        expect(s.preferencesTitle.isNotEmpty, isTrue);
        expect(s.callsignLabel.isNotEmpty, isTrue);
        expect(s.appLanguageLabel.isNotEmpty, isTrue);
        expect(s.broadcastSosButton.isNotEmpty, isTrue);
        expect(s.openTacticalGuide.isNotEmpty, isTrue);
        expect(s.tripHistoryTitle.isNotEmpty, isTrue);
        expect(s.tripMetricsTitle.isNotEmpty, isTrue);
        expect(s.metricDistance.isNotEmpty, isTrue);
        expect(s.tacticalChatTitle.isNotEmpty, isTrue);
        expect(s.tacticalGuideTitle.isNotEmpty, isTrue);
        expect(s.iUnderstand.isNotEmpty, isTrue);
        expect(s.activeGroupTitle.isNotEmpty, isTrue);
        expect(s.leaveRoomButton.isNotEmpty, isTrue);
        expect(s.joinCreateRoomTitle.isNotEmpty, isTrue);
        expect(s.createNewRoomButton.isNotEmpty, isTrue);
        expect(s.joinRoomButton.isNotEmpty, isTrue);
        expect(s.tacticalPingsTitle.isNotEmpty, isTrue);
        expect(s.sharedTacticalPoi.isNotEmpty, isTrue);
        expect(s.emergencySosTitle.isNotEmpty, isTrue);
      }
    });

    test('Dynamic parametrized methods format correctly in both languages', () {
      final sId = AppStrings(AppLanguage.id);
      final sEn = AppStrings(AppLanguage.en);

      expect(sId.roomCodeCopiedDetail('ABC123'), contains('ABC123'));
      expect(sEn.roomCodeCopiedDetail('ABC123'), contains('ABC123'));

      expect(sId.emergencySosFrom('ALPHA'), contains('ALPHA'));
      expect(sEn.emergencySosFrom('ALPHA'), contains('ALPHA'));

      expect(sId.hazardWarningAhead('150m'), contains('150m'));
      expect(sEn.hazardWarningAhead('150m'), contains('150m'));

      expect(sId.separatedFromConvoy('250'), contains('250'));
      expect(sEn.separatedFromConvoy('250'), contains('250'));

      expect(sId.membersActive(4), contains('4'));
      expect(sEn.membersActive(4), contains('4'));

      expect(sId.offlineQueueText(5), contains('5'));
      expect(sEn.offlineQueueText(5), contains('5'));
    });

    test('AppSettings handles language copyWith and default', () {
      const settings = AppSettings();
      expect(settings.language, AppLanguage.id);

      final updated = settings.copyWith(language: AppLanguage.en);
      expect(updated.language, AppLanguage.en);

      final copyAgain = updated.copyWith(userName: 'Falcon');
      expect(copyAgain.language, AppLanguage.en);
      expect(copyAgain.userName, 'Falcon');
    });
  });
}
