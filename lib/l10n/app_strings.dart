import '../models/tracker_models.dart';

class AppStrings {
  final AppLanguage language;

  const AppStrings(this.language);

  bool get isId => language == AppLanguage.id;

  // App Identity
  String get appTitle => 'Live Tracker';
  String get appSubtitle => isId ? 'PANTAUAN TAKTIS' : 'TACTICAL OVERWATCH';
  String get createdBy => 'CREATED BY KADHAFIINL';

  // Navigation & Map Header
  String get roomLabel => 'ROOM: ';
  String get roomCodeCopied => isId ? 'Kode Room disalin!' : 'Room code copied!';
  String roomCodeCopiedDetail(String code) =>
      isId ? 'Kode Room $code disalin ke clipboard!' : 'Room code $code copied to clipboard!';
  String shareRoomInvite(String code) => isId
      ? 'Gabung room konvoi Live Tracker saya! Kode: $code'
      : 'Join my Live Tracker convoy room! Code: $code';
  String get shareRoomSubject =>
      isId ? 'Undangan Room Konvoi Live Tracker' : 'Live Tracker Convoy Invitation';
  String get tapToAutoFollow =>
      isId ? 'Ketuk untuk ikuti lokasi otomatis' : 'Tap to auto-follow location';
  String get waitingGps =>
      isId ? 'Menunggu sinyal GPS...' : 'Waiting for GPS signal...';
  String get gpsErrorDefault =>
      isId ? 'GPS tidak aktif atau izin ditolak' : 'GPS inactive or permission denied';
  String get retry => isId ? 'COBA LAGI' : 'RETRY';
  String get reconnect => isId ? 'HUBUNGKAN ULANG' : 'RECONNECT';
  String get reconnectingText =>
      isId ? 'Sinyal terputus • Menghubungkan ulang ke konvoi...' : 'Signal lost • Reconnecting to convoy...';
  String get offlineModeText =>
      isId ? 'Mode Konvoi Terputus (Offline)' : 'Convoy Disconnected (Offline)';
  String offlineQueueText(int count) => isId
      ? 'Menyimpan $count koordinat offline • Siap auto-sync'
      : 'Storing $count offline coordinates • Ready to auto-sync';

  // Dashboard & Telemetry Dock
  String get speedLabel => isId ? 'KECEPATAN' : 'SPEED';
  String get autoPaused => isId ? 'TERJEDA OTOMATIS' : 'AUTO PAUSED';
  String get groupTelemetry => isId ? 'TELEMETRI KELOMPOK' : 'GROUP TELEMETRY';
  String membersActive(int count) => isId ? '$count Anggota Aktif' : '$count Members Active';
  String get noMembersInRoom => isId
      ? 'Belum ada anggota di room. Buat atau gabung room untuk sinkronisasi.'
      : 'No group members in room. Create or join a room to sync.';
  String get startTracking => isId ? 'MULAI TRACKING' : 'START TRACKING';
  String get pause => isId ? 'JEDA' : 'PAUSE';
  String get finish => isId ? 'SELESAI' : 'FINISH';
  String get resume => isId ? 'LANJUTKAN' : 'RESUME';
  String get routeSaved => isId ? 'Rute tersimpan di riwayat!' : 'Route saved to history!';
  String get routeTooShort =>
      isId ? 'Rute terlalu pendek untuk disimpan (<10m).' : 'Route too short to save (<10m).';

  // Alerts & Hazards
  String emergencySosFrom(String user) =>
      isId ? '🚨 SOS DARURAT DARI $user' : '🚨 EMERGENCY SOS FROM $user';
  String tacticalPingFrom(String user) =>
      isId ? 'PESAN TAKTIS: $user' : 'TACTICAL PING: $user';
  String hazardWarningAhead(String dist) =>
      isId ? 'PERINGATAN BAHAYA DI DEPAN ($dist)' : 'HAZARD WARNING AHEAD ($dist)';
  String separatedFromConvoy(String dist) =>
      isId ? 'Terpisah dari konvoi (~$dist m)' : 'Separated from convoy (~$dist m)';
  String backtrackRemaining(String dist) =>
      isId ? 'BACKTRACK KE AWAL • SISA: $dist' : 'BACKTRACK TO START • LEFT: $dist';
  String offTrailRemaining(String dev, String dist) =>
      isId ? 'KELUAR JALUR (${dev}m) • SISA: $dist' : 'OFF-TRAIL (${dev}m) • LEFT: $dist';
  String targetVector(String label, String dist) => 'TARGET: $label • $dist';

  // Topbar Controls & Tooltips
  String get mapStyleAndEngine => isId ? 'Gaya & Engine Peta' : 'Map Style & Engine';
  String get speedHeatmapActive =>
      isId ? 'Mode Speed Heatmap Aktif' : 'Speed Heatmap Mode Active';
  String get solidPolylineActive =>
      isId ? 'Mode Solid Neon Polyline Aktif' : 'Solid Neon Polyline Mode Active';
  String get backtrackActive =>
      isId ? 'Navigasi Backtrack Aktif!' : 'Backtrack Navigation Active!';
  String get backtrackDeactivated =>
      isId ? 'Navigasi Backtrack Dinonaktifkan' : 'Backtrack Navigation Deactivated';
  String get leaveRoomTitle => isId ? 'Keluar dari Room?' : 'Leave Room?';
  String get leaveRoomDesc => isId
      ? 'Anda akan berhenti berbagi lokasi real-time dengan anggota room ini.'
      : 'You will stop sharing your real-time location with room members.';
  String get cancel => isId ? 'BATAL' : 'CANCEL';
  String get leaveRoomConfirm => isId ? 'KELUAR ROOM' : 'LEAVE ROOM';
  String get leftRoomSuccess =>
      isId ? 'Berhasil keluar dari room' : 'Successfully left the room';
  String get heatmapToggleLabel => 'HEATMAP';

  // Settings
  String get preferencesTitle => isId ? 'Pengaturan' : 'Preferences';
  String get callsignLabel => isId ? 'Nama / Callsign Anda' : 'Your Name / Callsign';
  String get callsignHint => isId ? 'Misal: Eagle 1, Alpha...' : 'e.g. Eagle 1, Alpha...';
  String get saveCallsignTooltip => isId ? 'Simpan Callsign' : 'Save Callsign';
  String callsignSaved(String name) =>
      isId ? 'Callsign tersimpan: $name' : 'Callsign saved: $name';
  String get callsignDisabled =>
      isId ? 'Callsign dinonaktifkan (default ID)' : 'Callsign disabled (default ID)';
  String get appLanguageLabel => isId ? 'Bahasa Aplikasi' : 'App Language';
  String get testAndConnectTooltip => isId ? 'Uji & Sambungkan' : 'Test & Connect';
  String get testingServer => isId ? 'Menguji koneksi server...' : 'Testing server connection...';
  String get serverOnline =>
      isId ? 'Server Online! Berhasil terhubung.' : 'Server Online! Connected successfully.';
  String get serverOffline => isId
      ? 'Server Offline/Tidak terjangkau. Masuk Mode Solo.'
      : 'Server Offline/Unreachable. Entering Solo Mode.';
  String get saveApiKeyTooltip => isId ? 'Simpan API Key' : 'Save API Key';
  String get googleMapsKeySaved =>
      isId ? 'Google Maps API Key tersimpan!' : 'Google Maps API Key saved!';
  String get googleMapsKeyDisabled => isId
      ? 'Google Maps dinonaktifkan (default OSM/CartoDB).'
      : 'Google Maps disabled (default OSM/CartoDB).';
  String get cartoKeySaved =>
      isId ? 'CartoDB API Key tersimpan!' : 'CartoDB API Key saved!';
  String get cartoKeyDisabled => isId
      ? 'CartoDB dinonaktifkan (default Esri/OSM).'
      : 'CartoDB disabled (default Esri/OSM).';
  String get darkMapThemeTitle => isId ? 'Tema Peta Gelap' : 'Dark Map Theme';
  String get darkMapThemeSubtitle =>
      isId ? 'Gunakan ubin peta gelap kontras tinggi' : 'Use high-contrast dark map tiles';
  String get highAccuracyTitle => isId ? 'Pelacakan Akurasi Tinggi' : 'High Accuracy Tracking';
  String get highAccuracySubtitle => isId
      ? 'Konsumsi lebih banyak baterai demi rute presisi'
      : 'Consume more battery for precise routes';
  String get backgroundServiceTitle => isId ? 'Layanan Latar Belakang' : 'Background Service';
  String get backgroundServiceSubtitle =>
      isId ? 'Tetap melacak saat aplikasi diminimalkan' : 'Keep tracking when app is closed';
  String get soundAlertsTitle => isId ? 'Peringatan Suara Akustik' : 'Acoustic Sound Alerts';
  String get soundAlertsSubtitle => isId
      ? 'Bunyikan sirene saat SOS dan peringatan jarak'
      : 'Play siren on SOS and separation warning';
  String get hapticAlertsTitle => isId ? 'Getaran Taktis Haptik' : 'Haptic Tactical Vibration';
  String get hapticAlertsSubtitle => isId
      ? 'Getarkan perangkat saat peringatan darurat'
      : 'Vibrate device on emergency alerts';
  String get smartAutoPauseTitle => isId ? 'Jeda Otomatis Pintar (Touring)' : 'Smart Auto-Pause (Touring)';
  String get smartAutoPauseSubtitle => isId
      ? 'Jeda timer durasi secara otomatis saat berhenti'
      : 'Pause duration timer automatically when stopped';
  String get lowBandwidthTitle => isId ? 'Mode Hemat Data (Low-Bandwidth)' : 'Low-Bandwidth Mode';
  String get lowBandwidthSubtitle => isId
      ? 'Perlambat interval siaran ke 5 detik untuk hemat daya'
      : 'Throttle broadcast to 5s interval to save battery';
  String get hazardWatchdogTitle => isId ? 'Deteksi Bahaya Jalan (150m)' : 'Hazard Proximity Watchdog (150m)';
  String get hazardWatchdogSubtitle => isId
      ? 'Bunyikan sirene saat mendekati titik bahaya jalan'
      : 'Play siren and flash alert when approaching marked road hazards';
  String get broadcastSosButton => isId ? 'SIARKAN SINYAL DARURAT (SOS)' : 'BROADCAST EMERGENCY SIGNAL (SOS)';
  String get openTacticalGuide => isId ? 'Buka Panduan Taktis Konvoi' : 'Open Tactical Convoy Guide';
  String get done => isId ? 'SELESAI' : 'DONE';
  String get smartBatteryGuardTriggered => isId
      ? '⚡ Smart Battery Guard: Baterai <= 20%, mode hemat data aktif otomatis!'
      : '⚡ Smart Battery Guard: Battery <= 20%, low-bandwidth mode activated automatically!';

  // Tactical Chat
  String get tacticalChatTitle => isId ? 'OBROLAN TAKTIS ROOM' : 'TACTICAL ROOM CHAT';
  String roomChatSubtitle(String roomCode, int count) =>
      isId ? 'Room $roomCode • $count pesan' : 'Room $roomCode • $count messages';
  String get soloModeChatSubtitle => isId
      ? 'Mode Solo (Masuk room untuk berkirim pesan)'
      : 'Solo Mode (Join a room to send messages)';
  String get noChatYet => isId ? 'Belum ada obrolan konvoi.' : 'No convoy messages yet.';
  String get tapPhrasePrompt => isId
      ? 'Ketik pesan atau ketuk frasa taktis di atas.'
      : 'Type a message or tap a tactical phrase above.';
  String get typeTacticalMessage => isId ? 'Ketik pesan taktis...' : 'Type a tactical message...';

  // Trip History & Detail
  String get tripHistoryTitle => isId ? 'Riwayat Rute' : 'Trip History';
  String get clearAllHistoryTitle => isId ? 'Hapus semua riwayat?' : 'Clear all history?';
  String get clearAllHistoryDesc => isId
      ? 'Seluruh rekaman rute akan dihapus permanen dari perangkat.'
      : 'All saved trips will be permanently deleted from this device.';
  String get deleteAllConfirm => isId ? 'HAPUS SEMUA' : 'DELETE ALL';
  String get allHistoryCleared => isId ? 'Semua riwayat berhasil dihapus' : 'All history cleared';
  String get lifetimeTotals => isId ? 'TOTAL KESELURUHAN' : 'LIFETIME TOTALS';
  String get distanceShort => isId ? 'JARAK' : 'DISTANCE';
  String get durationShort => isId ? 'DURASI' : 'DURATION';
  String get sessionsShort => isId ? 'SESI' : 'TRIPS';
  String get sortBy => isId ? 'URUTKAN: ' : 'SORT BY: ';
  String get sortNewest => isId ? 'TERBARU' : 'NEWEST';
  String get sortDistance => isId ? 'JARAK' : 'DISTANCE';
  String get sortDuration => isId ? 'DURASI' : 'DURATION';
  String get noTripsYet => isId ? 'Belum ada riwayat rute.' : 'No recorded trips yet.';
  String get startRidingPrompt => isId
      ? 'Mulai perjalanan Anda untuk merekam rute GPS.'
      : 'Start your journey to record GPS routes.';

  // Trip Detail Metrics
  String get renameRouteTitle => isId ? 'Ubah Nama Rute' : 'Rename Route';
  String get renameRouteHint =>
      isId ? 'Misal: Touring Puncak, Morning Ride...' : 'e.g. Mountain Tour, Morning Ride...';
  String get save => isId ? 'SIMPAN' : 'SAVE';
  String get routeRenamed => isId ? 'Nama rute diperbarui!' : 'Route title updated!';
  String get deleteRouteTitle => isId ? 'Hapus rute ini?' : 'Delete this route?';
  String get deleteRouteDesc => isId
      ? 'Rekaman rute ini akan dihapus permanen dari perangkat.'
      : 'This route recording will be permanently deleted from device.';
  String get deleteRouteTooltip => isId ? 'Hapus Rute' : 'Delete Route';
  String get renameRouteTooltip => isId ? 'Ubah Nama' : 'Rename Route';
  String get shareCardTooltip => isId ? 'Bagikan Kartu' : 'Share Card';
  String get exportGisTooltip => isId ? 'Ekspor Data GIS' : 'Export GIS Data';
  String exportFailed(String format, String err) =>
      isId ? 'Gagal mengekspor ${format.toUpperCase()}: $err' : 'Failed to export ${format.toUpperCase()}: $err';
  String get preparingShareCard => isId ? 'Menyiapkan kartu rute...' : 'Preparing route card...';
  String get cardThemeLabel => isId ? 'TEMA KARTU:' : 'CARD THEME:';
  String get close => isId ? 'TUTUP' : 'CLOSE';
  String get shareImageButton => isId ? 'BAGIKAN GAMBAR' : 'SHARE IMAGE';
  String get tripMetricsTitle => isId ? 'METRIK RUTE' : 'TRIP METRICS';
  String get metricDistance => isId ? 'JARAK' : 'DISTANCE';
  String get metricTotalDuration => isId ? 'TOTAL DURASI' : 'TOTAL DURATION';
  String get metricMovingTime => isId ? 'WAKTU BERGERAK' : 'MOVING TIME';
  String get metricStoppedTime => isId ? 'WAKTU BERHENTI' : 'STOPPED TIME';
  String get metricAvgPace => isId ? 'AVG PACE' : 'AVG PACE';
  String get metricAvgSpeed => isId ? 'AVG KECEPATAN' : 'AVG SPEED';
  String get metricTopSpeed => isId ? 'TOP SPEED' : 'TOP SPEED';
  String get metricMaxGradient => isId ? 'MAX GRADIENT' : 'MAX GRADIENT';
  String get elevationProfile => isId ? 'PROFIL ELEVASI' : 'ELEVATION PROFILE';
  String get noElevationData => isId
      ? 'Data profil elevasi tidak tersedia untuk rute ini'
      : 'Elevation profile data not available for this route';
  String get kmSplitsTitle => isId ? 'SPLIT KILOMETER' : 'KILOMETER SPLITS';
  String get speedSpectrumTitle => isId ? 'SPEKTRUM KECEPATAN' : 'SPEED SPECTRUM';
  String get gain => isId ? 'ELEVASI NAIK' : 'ELEV GAIN';
  String get loss => isId ? 'ELEVASI TURUN' : 'ELEV LOSS';

  // Tactical Guide
  String get tacticalGuideTitle => isId ? 'PANDUAN TAKTIS KONVOI' : 'TACTICAL CONVOY GUIDE';
  String get tacticalGuideSubtitle => isId
      ? 'Instruksi lengkap navigasi, grup, dan keselamatan'
      : 'Complete guide for navigation, groups, and safety';
  String get iUnderstand => isId ? 'SAYA MENGERTI' : 'I UNDERSTAND';

  // Room & Groups
  String get activeGroupTitle => isId ? 'Anggota Aktif' : 'Active Group';
  String activeOnline(int count) => isId ? '$count Online' : '$count Online';
  String get youAreOnlyMember =>
      isId ? 'Anda satu-satunya anggota di room ini.' : 'You are the only member in this room.';
  String get leaveRoomButton => isId ? 'KELUAR DARI ROOM' : 'LEAVE ROOM';
  String get joinCreateRoomTitle => isId ? 'Konvoi Kelompok' : 'Convoy Group';
  String get joinCreateRoomSubtitle => isId
      ? 'Buat room baru atau gabung room rekan Anda'
      : 'Create a new room or join your peers';
  String get createNewRoomButton => isId ? 'BUAT ROOM BARU' : 'CREATE NEW ROOM';
  String get orEnterCode => isId ? 'ATAU MASUKKAN KODE' : 'OR ENTER CODE';
  String get joinRoomButton => isId ? 'GABUNG KE ROOM' : 'JOIN ROOM';
  String get roomCodeFieldLabel => isId ? 'Kode Room' : 'Room Code';
  String get roomCodeFieldHint => isId ? 'Misal: X8G9PQ' : 'e.g. X8G9PQ';
  String get roomCodeLengthError =>
      isId ? 'Kode room harus 6 karakter' : 'Room code must be 6 characters';
  String enteredRoomSuccess(String code) =>
      isId ? 'Berhasil masuk ke Room $code' : 'Successfully joined Room $code';

  // Tactical Pings
  String get tacticalPingsTitle => isId ? 'PESAN TAKTIS CEPAT' : 'TACTICAL QUICK PINGS';
  String get tacticalPingsSubtitleRoom => isId
      ? 'Kirim instruksi taktis instan ke seluruh konvoi'
      : 'Send instant tactical cues to entire convoy';
  String get tacticalPingsSubtitleSolo => isId
      ? 'Masuk room konvoi untuk menyiarkan pesan ke rekan'
      : 'Join a convoy room to broadcast cues to peers';
  String tacticalPingBroadcasted(String title) =>
      isId ? 'Pesan taktis "$title" disiarkan ke konvoi!' : 'Tactical cue "$title" broadcast to convoy!';
  String tacticalPingActivatedSolo(String title) =>
      isId ? 'Pesan taktis "$title" diaktifkan (Mode Solo).' : 'Tactical cue "$title" activated (Solo Mode).';

  // POIs
  String get sharedTacticalPoi => isId ? 'TITIK TAKTIS (POI)' : 'SHARED TACTICAL POI';
  String get poiCategoryLabel => isId ? 'KATEGORI TITIK' : 'POINT CATEGORY';
  String get poiNameLabel => isId ? 'NAMA / DESKRIPSI TITIK' : 'POINT NAME / DESCRIPTION';
  String get poiNameHint => isId ? 'Misal: Titik Kumpul SPBU KM 57...' : 'e.g. Gas Station Rendezvous...';
  String get poiNameEmptyError => isId ? 'Nama titik tidak boleh kosong' : 'Point name cannot be empty';
  String get dropPinButton => isId ? 'PASANG PIN KE GRUP' : 'DROP PIN TO GROUP';
  String poiPlacedSuccess(String title) => isId ? 'Pin "$title" berhasil dipasang!' : 'Pin "$title" placed!';
  String get coordinatesLabel => isId ? 'KOORDINAT' : 'COORDINATES';
  String get distanceLabel => isId ? 'JARAK' : 'DISTANCE';
  String get bearingLabel => isId ? 'BEARING / ARAH' : 'BEARING / DIRECTION';
  String get etaLabel => isId ? 'ESTIMASI TIBA (ETA)' : 'ESTIMATED ARRIVAL (ETA)';
  String get lockTargetVectorButton => isId ? 'KUNCI TARGET VEKTOR PETA' : 'LOCK TARGET VECTOR ON MAP';
  String get deletePoiButton => isId ? 'HAPUS PIN TANDANGAN INI' : 'DELETE THIS PIN';

  // SOS Sheet
  String get emergencySosTitle => isId ? 'SINYAL DARURAT SOS' : 'EMERGENCY SOS BEACON';
  String get emergencySosSubtitleRoom =>
      isId ? 'Siarkan sinyal darurat ke seluruh anggota room' : 'Broadcast emergency distress beacon to room';
  String get emergencySosSubtitleSolo =>
      isId ? 'Siaran darurat mandiri / lokal' : 'Local emergency distress alert';
  String get dismissSosButton => isId ? 'CABUT / MATIKAN SINYAL SOS' : 'DISMISS / CANCEL SOS BEACON';
  String get selectEmergencyCategory => isId ? 'PILIH KATEGORI DARURAT' : 'SELECT EMERGENCY CATEGORY';
  String get sosActiveWarningTitle => isId ? 'SINYAL SOS SEDANG AKTIF' : 'SOS BEACON IS ACTIVE';
  String get sosActiveWarningDesc => isId
      ? 'Lokasi Anda disiarkan terus menerus ke rekan konvoi'
      : 'Your location is broadcasting continuously to convoy';
  String get additionalNotesOptional => isId ? 'Catatan Tambahan (Opsional)' : 'Additional Notes (Optional)';
  String get sendSosButton => isId ? 'KIRIM SINYAL SOS KE GRUP' : 'SEND SOS SIGNAL TO GROUP';
}
