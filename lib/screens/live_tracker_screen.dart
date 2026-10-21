import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../src/core/constants.dart';
import '../providers/tracker_providers.dart';
import '../models/tracker_models.dart';
import '../utils/trail_backtracker.dart';
import '../widgets/top_header_hub.dart';
import '../widgets/telemetry_dock.dart';
import '../widgets/custom_user_marker.dart';
import '../widgets/auto_center_button.dart';
import '../widgets/map_compass_control.dart';
import '../utils/ui_helpers.dart';
import '../utils/sound_manager.dart';
import '../utils/custom_snackbar.dart';
import '../utils/app_theme.dart';
import '../utils/geo_bearing_helper.dart';
import '../src/core/services/battery_service.dart';
import '../widgets/modals/add_poi_sheet.dart';
import '../widgets/modals/poi_detail_sheet.dart';
import '../widgets/modals/member_inspection_sheet.dart';
import '../widgets/sos_beacon_marker.dart';
import '../widgets/convoy_overview_button.dart';

class LiveTrackerScreen extends ConsumerStatefulWidget {
  const LiveTrackerScreen({super.key});

  @override
  ConsumerState<LiveTrackerScreen> createState() => _LiveTrackerScreenState();
}

class _LiveTrackerScreenState extends ConsumerState<LiveTrackerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _mapController = MapController();
  bool _initialCentered = false;
  bool _isMapReady = false;
  int _lastBatteryCheckMs = 0;
  int? _cachedBatteryLevel;
  LatLng? _lastGpsPos;
  double _currentHeading = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    BatteryService.getBatteryLevel().then((b) {
      if (mounted) _cachedBatteryLevel = b;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(locationStreamProvider);
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!_isMapReady) return; // Prevent early camera movements before binding
    
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    final animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) controller.dispose();
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final mapStyle = ref.watch(mapStyleProvider);
    final s = ref.watch(appStringsProvider);
    
    // Auto-centering on first fix and auto-follow camera navigation
    ref.listen(locationStreamProvider, (prev, next) {
      if (!next.hasValue) return;
      final pos = next.value!;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastBatteryCheckMs > 30000 || _lastBatteryCheckMs == 0) {
        _lastBatteryCheckMs = now;
        BatteryService.getBatteryLevel().then((battery) {
          if (mounted) {
            _cachedBatteryLevel = battery;
            // Smart Battery Guard: auto-activate low-bandwidth mode below 20%
            if (battery != null && battery <= 20) {
              final currentSettings = ref.read(appSettingsProvider);
              if (!currentSettings.lowBandwidthMode) {
                ref.read(appSettingsProvider.notifier).updateSettings(
                  currentSettings.copyWith(lowBandwidthMode: true),
                );
                if (context.mounted) {
                  CustomSnackbar.show(
                    context,
                    message: s.smartBatteryGuardTriggered,
                    type: SnackbarType.warning,
                  );
                }
              }
            }
          }
        });
      }

      final currentPos = LatLng(pos.latitude, pos.longitude);
      if (_lastGpsPos != null) {
        final d = const Distance().as(LengthUnit.Meter, _lastGpsPos!, currentPos);
        // Compute Course-Over-Ground (COG) bearing if movement >= 1.5m (filters stationary GPS jitter)
        if (d >= 1.5) {
          _currentHeading = GeoBearingHelper.calculateBearing(_lastGpsPos!, currentPos);
          _lastGpsPos = currentPos;
        } else if (pos.heading > 0.0 && (pos.speed * 3.6) > 2.0) {
          _currentHeading = pos.heading;
        }
        // When stationary (< 1.5m), _currentHeading is retained so arrow does NOT snap to North!
      } else {
        _lastGpsPos = currentPos;
        if (pos.heading > 0.0) _currentHeading = pos.heading;
      }

      ref.read(roomProvider.notifier).sendPosition(
        pos,
        batteryPercent: _cachedBatteryLevel ?? BatteryService.cachedLevel,
        heading: _currentHeading,
      );

      final isAutoFollow = ref.read(autoFollowProvider);

      if (!_initialCentered) {
        _animatedMapMove(LatLng(pos.latitude, pos.longitude), MapDefaults.focusedZoom);
        _initialCentered = true;
      } else if (isAutoFollow) {
        // Auto-follow live user movement smoothly
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          _mapController.camera.zoom,
        );
      }
    });

    // Fly-to animation when selecting member from sheet/island
    ref.listen(focusedMemberProvider, (prev, next) {
      if (next != null) {
        _animatedMapMove(LatLng(next.latitude, next.longitude), 16.5);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) ref.read(focusedMemberProvider.notifier).state = null;
        });
      }
    });

    // Sound & Haptic Trigger on Emergency SOS
    ref.listen(roomProvider.select((r) => r.activeSos), (prev, next) {
      if (next != null && (prev == null || prev.timestamp != next.timestamp)) {
        final settings = ref.read(appSettingsProvider);
        SoundManager.playEmergencyAlarm(
          soundEnabled: settings.soundAlertsEnabled,
          hapticEnabled: settings.hapticAlertsEnabled,
        );
        if (next.latitude != null && next.longitude != null) {
          _animatedMapMove(LatLng(next.latitude!, next.longitude!), 17.0);
        }
      }
    });

    // Sound & Haptic Trigger on Tactical Cue Ping
    ref.listen(roomProvider.select((r) => r.activePing), (prev, next) {
      if (next != null && (prev == null || prev.id != next.id)) {
        final settings = ref.read(appSettingsProvider);
        SoundManager.playTacticalCue(
          next.cue,
          soundEnabled: settings.soundAlertsEnabled,
          hapticEnabled: settings.hapticAlertsEnabled,
        );
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted && ref.read(roomProvider).activePing?.id == next.id) {
            ref.read(roomProvider.notifier).clearActivePing();
          }
        });
      }
    });

    // Sound & Haptic Trigger on Convoy Separation
    ref.listen(convoySeparationProvider.select((s) => s.isSeparated), (prev, next) {
      if (next == true && prev != true) {
        final settings = ref.read(appSettingsProvider);
        SoundManager.playWarningBeep(
          soundEnabled: settings.soundAlertsEnabled,
          hapticEnabled: settings.hapticAlertsEnabled,
        );
      }
    });

    // Sound & Haptic Trigger on Hazard Proximity Geofence (150m)
    ref.listen(hazardProximityProvider.select((h) => h.isApproaching), (prev, next) {
      if (next == true && prev != true) {
        final settings = ref.read(appSettingsProvider);
        if (settings.hazardProximityAlert) {
          SoundManager.playHazardProximityAlert(
            soundEnabled: settings.soundAlertsEnabled,
            hapticEnabled: settings.hapticAlertsEnabled,
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.darkCanvas,
      body: Stack(
        children: [
          // 1. High-Performance Map Viewport with Caching
          RepaintBoundary(
            child: FlutterMap(
              mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-6.2, 106.8),
              initialZoom: 13,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              onMapReady: () {
                setState(() {
                  _isMapReady = true;
                });
              },
              onPositionChanged: (pos, hasGesture) {
                // If user manually drags/gestures on the map, disable auto-follow
                if (hasGesture && ref.read(autoFollowProvider)) {
                  ref.read(autoFollowProvider.notifier).state = false;
                }
              },
              onLongPress: (tapPosition, point) {
                HapticFeedback.mediumImpact();
                _showAddPoiSheet(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: mapStyle.urlTemplate,
                subdomains: mapStyle.subdomains,
                userAgentPackageName: 'VellumLiveTracker/1.0 (contact: kadhafiinl@github)',
                maxZoom: 19,
                keepBuffer: 2,
                panBuffer: 1,
                tileUpdateTransformer: TileUpdateTransformers.throttle(const Duration(milliseconds: 250)),
              ),

              // Active Route Polyline (Throttled & Downsampled with RDP)
              Consumer(
                builder: (context, ref, _) {
                  final sessionState = ref.watch(tripSessionProvider.select((s) => s.state));
                  if (sessionState == TripSessionState.inactive) {
                    return const SizedBox.shrink();
                  }

                  // Watch simplified downsampled points for GPU fill-rate protection
                  final routePoints = ref.watch(
                    tripSessionProvider.notifier.select((n) => n.simplifiedRoute),
                  );

                  if (routePoints.length < 2) return const SizedBox.shrink();

                  return RepaintBoundary(
                    child: PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          strokeWidth: 4.5,
                          color: AppTheme.primaryCyan.withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Target Vector Line to Selected POI or Member
              Consumer(
                builder: (context, ref, _) {
                  final target = ref.watch(navigationTargetProvider);
                  final posAsync = ref.watch(locationStreamProvider);
                  if (target == null || !posAsync.hasValue) return const SizedBox.shrink();

                  final myPos = posAsync.value!;
                  return RepaintBoundary(
                    child: PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [LatLng(myPos.latitude, myPos.longitude), target],
                          strokeWidth: 2.8,
                          color: AppTheme.warningAmber.withValues(alpha: 0.85),
                          pattern: StrokePattern.dashed(segments: const [10, 6]),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Inverted Trail Backtrack Guide Polyline Layer
              Consumer(
                builder: (context, ref, _) {
                  final backtrack = ref.watch(backtrackProvider);
                  if (!backtrack.isBacktrackActive || backtrack.reversePath.length < 2) {
                    return const SizedBox.shrink();
                  }

                  return RepaintBoundary(
                    child: PolylineLayer(
                      polylines: [
                        Polyline(
                          points: backtrack.reversePath,
                          strokeWidth: 4.2,
                          color: AppTheme.accentOrange.withValues(alpha: 0.9),
                          pattern: StrokePattern.dashed(segments: const [12, 6]),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Active Trip Starting Point Flag Marker
              Consumer(
                builder: (context, ref, _) {
                  final isTracking = ref.watch(tripSessionProvider.select((s) => s.state != TripSessionState.inactive));
                  if (!isTracking) return const SizedBox.shrink();

                  final startPoint = ref.watch(
                    tripSessionProvider.notifier.select((n) => n.routeBuffer.isNotEmpty ? n.routeBuffer.first : null),
                  );

                  if (startPoint == null) return const SizedBox.shrink();

                  return MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(startPoint.latitude, startPoint.longitude),
                        width: 38,
                        height: 38,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.secondaryGreen, width: 2.2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secondaryGreen.withValues(alpha: 0.45),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.flag_rounded,
                            color: AppTheme.secondaryGreen,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Member Markers Layer (Isolated RepaintBoundary)
              Consumer(
                builder: (context, ref, _) {
                  final members = ref.watch(roomProvider.select((r) => r.members.values.toList()));
                  if (members.isEmpty) return const SizedBox.shrink();

                  return RepaintBoundary(
                    child: MarkerLayer(
                      markers: members.map((m) {
                        return Marker(
                          point: LatLng(m.latitude, m.longitude),
                          width: 56,
                          height: 56,
                          rotate: true,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _showMemberInspectionSheet(m);
                            },
                            child: CustomUserMarker(
                              location: m,
                              color: _getColorForId(m.id),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),

              // Shared Tactical POI Layer
              Consumer(
                builder: (context, ref, _) {
                  final pois = ref.watch(roomProvider.select((r) => r.pois.values.toList()));
                  if (pois.isEmpty) return const SizedBox.shrink();

                  return RepaintBoundary(
                    child: MarkerLayer(
                      markers: pois.map((poi) {
                        final categoryConfig = switch (poi.category) {
                          PoiCategory.rendezvous => (icon: Icons.flag_rounded, color: AppTheme.primaryCyan),
                          PoiCategory.fuel => (icon: Icons.local_gas_station_rounded, color: AppTheme.warningAmber),
                          PoiCategory.hazard => (icon: Icons.warning_amber_rounded, color: AppTheme.dangerRed),
                          PoiCategory.rest => (icon: Icons.hotel_rounded, color: AppTheme.secondaryGreen),
                        };

                        return Marker(
                          point: LatLng(poi.latitude, poi.longitude),
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _showPoiDetailSheet(poi);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.darkSurface,
                                shape: BoxShape.circle,
                                border: Border.all(color: categoryConfig.color, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: categoryConfig.color.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(categoryConfig.icon, color: categoryConfig.color, size: 20),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),

              // Active SOS Distress Beacon Layer
              Consumer(
                builder: (context, ref, _) {
                  final activeSos = ref.watch(roomProvider.select((r) => r.activeSos));
                  if (activeSos == null || activeSos.latitude == null || activeSos.longitude == null) {
                    return const SizedBox.shrink();
                  }

                  return RepaintBoundary(
                    child: MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(activeSos.latitude!, activeSos.longitude!),
                          width: 68,
                          height: 68,
                          child: SosBeaconMarker(
                            alert: activeSos,
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              _animatedMapMove(LatLng(activeSos.latitude!, activeSos.longitude!), 17.5);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Local User Marker Layer (Consumer-isolated to avoid full-screen rebuilds on GPS ticks)
              Consumer(
                builder: (context, ref, _) {
                  final posAsync = ref.watch(locationStreamProvider);
                  if (!posAsync.hasValue) return const SizedBox.shrink();
                  final pos = posAsync.value!;

                  return RepaintBoundary(
                    child: MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(pos.latitude, pos.longitude),
                          width: 56,
                          height: 56,
                          rotate: true,
                          child: CustomUserMarker(
                            isLocalUser: true,
                            location: MemberLocation(
                              id: 'YOU',
                              latitude: pos.latitude,
                              longitude: pos.longitude,
                              lastUpdated: pos.timestamp,
                              heading: _currentHeading,
                              speedKmh: pos.speed * 3.6,
                              isIdle: (pos.speed * 3.6) < 1.0,
                            ),
                            color: AppTheme.primaryCyan,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
          
          // 2. Floating Top Header Capsule
          const Align(
            alignment: Alignment.topCenter,
            child: TopHeaderHub(),
          ),

          // 2a. Adaptive Collision-Free Alert & Status Stack
          Positioned(
            top: MediaQuery.of(context).padding.top + 76.0,
            left: 16,
            right: 16,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.42,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // GPS Status & Permission Warning Banner
                Consumer(
                  builder: (context, ref, _) {
                    final posAsync = ref.watch(locationStreamProvider);
                    if (!posAsync.hasError) return const SizedBox.shrink();

                    final err = posAsync.error.toString().replaceAll('Exception: ', '');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_off_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                err.isNotEmpty ? err : s.gpsErrorDefault,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.white24,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                ref.invalidate(locationStreamProvider);
                              },
                              child: Text(s.retry, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Offline Convoy Reconnecting Warning Banner
                Consumer(
                  builder: (context, ref, _) {
                    final inRoom = ref.watch(roomProvider.select((r) => r.roomCode != null));
                    final status = ref.watch(roomProvider.select((r) => r.status));
                    if (!inRoom || status == TrackingConnectionStatus.connected) return const SizedBox.shrink();

                    final isReconnecting = status == TrackingConnectionStatus.reconnecting;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD97706).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isReconnecting ? Icons.sync_problem_rounded : Icons.cloud_off_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isReconnecting
                                    ? s.reconnectingText
                                    : s.offlineModeText,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (!isReconnecting)
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.white24,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  ref.read(roomProvider.notifier).reconnect();
                                },
                                child: Text(s.reconnect, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Offline Queue Buffer Sync Progress Indicator
                Consumer(
                  builder: (context, ref, _) {
                    final queueCount = ref.watch(roomProvider.select((r) => r.offlineQueueCount));
                    if (queueCount <= 0) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.6), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primaryCyan),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              s.offlineQueueText(queueCount),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryCyan,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Emergency SOS Alert Banner
                Consumer(
                  builder: (context, ref, _) {
                    final activeSos = ref.watch(roomProvider.select((r) => r.activeSos));
                    if (activeSos == null) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          if (activeSos.latitude != null && activeSos.longitude != null) {
                            _animatedMapMove(LatLng(activeSos.latitude!, activeSos.longitude!), 17.5);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerRed.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.dangerRed.withValues(alpha: 0.4),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    s.emergencySosFrom(activeSos.userId.toUpperCase()),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                    Text(
                                      activeSos.note,
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                                onPressed: () {
                                  ref.read(roomProvider.notifier).dismissSos();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Tactical Quick Ping Banner Overlay
                Consumer(
                  builder: (context, ref, _) {
                    final activePing = ref.watch(roomProvider.select((r) => r.activePing));
                    if (activePing == null || activePing.isExpired) return const SizedBox.shrink();

                    final cueColor = switch (activePing.cue) {
                      TacticalCueType.hazard => AppTheme.dangerRed,
                      TacticalCueType.regroup => AppTheme.primaryCyan,
                      TacticalCueType.fuel => AppTheme.warningAmber,
                      TacticalCueType.turnLeft || TacticalCueType.turnRight => const Color(0xFF69F0AE),
                      TacticalCueType.rest => AppTheme.accentOrange,
                    };

                    final cueIcon = switch (activePing.cue) {
                      TacticalCueType.hazard => Icons.warning_amber_rounded,
                      TacticalCueType.regroup => Icons.groups_rounded,
                      TacticalCueType.fuel => Icons.local_gas_station_rounded,
                      TacticalCueType.turnLeft => Icons.turn_left_rounded,
                      TacticalCueType.turnRight => Icons.turn_right_rounded,
                      TacticalCueType.rest => Icons.coffee_rounded,
                    };

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          if (activePing.latitude != null && activePing.longitude != null) {
                            _animatedMapMove(LatLng(activePing.latitude!, activePing.longitude!), 17.0);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurface.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: cueColor, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: cueColor.withValues(alpha: 0.35),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: cueColor.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(cueIcon, color: cueColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          s.tacticalPingFrom(activePing.callerDisplayName.toUpperCase()),
                                          style: GoogleFonts.inter(
                                            color: cueColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      activePing.cue.label,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white60, size: 18),
                                onPressed: () {
                                  ref.read(roomProvider.notifier).clearActivePing();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Hazard Proximity Approaching Warning Banner
                Consumer(
                  builder: (context, ref, _) {
                    final hazard = ref.watch(hazardProximityProvider);
                    final isAlertEnabled = ref.watch(appSettingsProvider.select((s) => s.hazardProximityAlert));
                    if (!isAlertEnabled || !hazard.isApproaching || hazard.hazardPoi == null) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          _animatedMapMove(LatLng(hazard.hazardPoi!.latitude, hazard.hazardPoi!.longitude), 17.5);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white70, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      s.hazardWarningAhead(hazard.formattedDistance),
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      hazard.hazardPoi!.title,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.my_location_rounded, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Convoy Separation Watchdog Warning
                Consumer(
                  builder: (context, ref, _) {
                    final separation = ref.watch(convoySeparationProvider);
                    final inRoom = ref.watch(roomProvider.select((r) => r.roomCode != null));
                    if (!inRoom || !separation.isSeparated) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fmd_bad_outlined, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              s.separatedFromConvoy(separation.distanceMeters.toStringAsFixed(0)),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Horizontal Tactical Navigation HUD Bar (Backtrack, Target Vector)
                Consumer(
                  builder: (context, ref, _) {
                    final backtrack = ref.watch(backtrackProvider);
                    final target = ref.watch(navigationTargetProvider);
                    final targetLabel = ref.watch(navigationTargetLabelProvider);
                    final posAsync = ref.watch(locationStreamProvider);

                    final hasBacktrack = backtrack.isBacktrackActive;
                    final hasTarget = target != null;

                    if (!hasBacktrack && !hasTarget) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      alignment: Alignment.center,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasBacktrack) ...[
                              _buildBacktrackPill(backtrack, ref),
                              if (hasTarget) const SizedBox(width: 8),
                            ],
                            if (hasTarget) ...[
                              _buildTargetPill(target, targetLabel, posAsync.valueOrNull, ref),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Re-center Floating Hint Pill when user panned away
                Consumer(
                  builder: (context, ref, _) {
                    final isAutoFollow = ref.watch(autoFollowProvider);
                    final isTracking = ref.watch(tripSessionProvider.select((s) => s.state == TripSessionState.active));
                    if (isAutoFollow || !isTracking) return const SizedBox.shrink();

                    return Container(
                      alignment: Alignment.center,
                      child: PremiumGlass(
                        borderRadius: BorderRadius.circular(20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onTap: () {
                          final pos = ref.read(locationStreamProvider).valueOrNull;
                          if (pos != null) {
                            _animatedMapMove(LatLng(pos.latitude, pos.longitude), MapDefaults.focusedZoom);
                            ref.read(autoFollowProvider.notifier).state = true;
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.gps_fixed, size: 14, color: AppTheme.primaryCyan),
                            const SizedBox(width: 8),
                            Text(
                              s.tapToAutoFollow,
                              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
          
          // 3. Floating Micro-Controls Stack
          Consumer(
            builder: (context, ref, _) {
              final dockExpanded = ref.watch(telemetryExpandedProvider);
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                right: 16,
                bottom: dockExpanded ? 380 : 240,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MapCompassControl(mapController: _mapController),
                    const SizedBox(height: 12),
                    ConvoyOverviewButton(mapController: _mapController),
                    const SizedBox(height: 12),
                    AutoCenterButton(mapController: _mapController),
                  ],
                ),
              );
            },
          ),
          
          // 4. Floating Telemetry Dock
          const Align(
            alignment: Alignment.bottomCenter,
            child: TelemetryBottomDock(),
          ),
        ],
      ),
    );
  }

  Widget _buildBacktrackPill(BacktrackState backtrack, WidgetRef ref) {
    final isOffTrail = backtrack.isOffTrail;
    final pillColor = isOffTrail ? AppTheme.dangerRed : AppTheme.accentOrange;
    final s = ref.watch(appStringsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pillColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: pillColor.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.undo_rounded, color: pillColor, size: 16),
          const SizedBox(width: 8),
          Text(
            isOffTrail
                ? s.offTrailRemaining(backtrack.crossTrackDeviationMeters.toStringAsFixed(0), backtrack.formattedDistanceToOrigin)
                : s.backtrackRemaining(backtrack.formattedDistanceToOrigin),
            style: GoogleFonts.inter(
              color: pillColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(backtrackActiveProvider.notifier).state = false;
            },
            child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetPill(LatLng target, String? label, Position? myPos, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    String distStr = '';
    if (myPos != null) {
      final d = const Distance().as(
        LengthUnit.Meter,
        LatLng(myPos.latitude, myPos.longitude),
        target,
      );
      distStr = d < 1000 ? '${d.toStringAsFixed(0)} m' : '${(d / 1000).toStringAsFixed(2)} km';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warningAmber, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warningAmber.withValues(alpha: 0.25),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.navigation_rounded, color: AppTheme.warningAmber, size: 16),
          const SizedBox(width: 8),
          Text(
            s.targetVector(label ?? "POI", distStr),
            style: GoogleFonts.inter(
              color: AppTheme.warningAmber,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              ref.read(navigationTargetProvider.notifier).state = null;
              ref.read(navigationTargetLabelProvider.notifier).state = null;
            },
            child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
          ),
        ],
      ),
    );
  }

  void _showAddPoiSheet(LatLng point) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddPoiSheet(point: point),
    );
  }

  void _showPoiDetailSheet(SharedPoi poi) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => PoiDetailSheet(poi: poi),
    );
  }

  void _showMemberInspectionSheet(MemberLocation member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MemberInspectionSheet(member: member),
    );
  }

  Color _getColorForId(String id) {
    const colors = [
      Color(0xFFFF1744), Color(0xFF00E676), Color(0xFFFFD600),
      Color(0xFFAA00FF), Color(0xFF00BCD4), Color(0xFFFF6D00),
    ];
    return colors[id.codeUnits.fold<int>(0, (p, c) => p + c) % colors.length];
  }
}
