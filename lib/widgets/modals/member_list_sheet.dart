import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/tracker_models.dart';
import '../../providers/tracker_providers.dart';
import '../../utils/ui_helpers.dart';
import '../../utils/custom_snackbar.dart';

class MemberListSheet extends ConsumerWidget {
  const MemberListSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomProvider);
    final members = roomState.members.values.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: PremiumGlass(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white30 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Group', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${members.length + 1} Online',
                      style: GoogleFonts.inter(color: const Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (roomState.roomCode != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E232D) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.meeting_room_outlined, size: 18, color: isDark ? const Color(0xFF00E5FF) : colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'ROOM: ',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        roomState.roomCode!,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF00E5FF) : colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        tooltip: 'Salin Kode',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Clipboard.setData(ClipboardData(text: roomState.roomCode!));
                          CustomSnackbar.show(context, message: 'Kode Room ${roomState.roomCode} disalin!', type: SnackbarType.success);
                        },
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.share_rounded, size: 16),
                        tooltip: 'Bagikan Kode',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          SharePlus.instance.share(
                            ShareParams(
                              text: 'Gabung room Live Tracker saya dengan kode: ${roomState.roomCode}',
                              subject: 'Undangan Room Live Tracker',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              if (members.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('You are the only member in this room.')),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: members.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Colors.white12),
                    itemBuilder: (context, index) {
                      final m = members[index];
                      final secondsAgo = DateTime.now().difference(m.lastUpdated).inSeconds;
                      final isFresh = secondsAgo < 10;
                      final batteryIcon = m.batteryPercent != null
                          ? (m.batteryPercent! > 75
                              ? Icons.battery_full
                              : m.batteryPercent! > 30
                                  ? Icons.battery_5_bar
                                  : Icons.battery_alert)
                          : null;

                      final myPos = ref.watch(locationStreamProvider).valueOrNull;
                      String? distStr;
                      if (myPos != null) {
                        final d = const Distance().as(
                          LengthUnit.Meter,
                          LatLng(myPos.latitude, myPos.longitude),
                          LatLng(m.latitude, m.longitude),
                        );
                        distStr = d < 1000 ? '${d.toStringAsFixed(0)} m' : '${(d / 1000).toStringAsFixed(1)} km';
                      }

                      final displayName = (m.name != null && m.name!.trim().isNotEmpty) ? m.name!.trim() : 'User ${m.id}';
                      final initialLetter = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: isDark ? const Color(0xFF12151B) : colorScheme.primaryContainer,
                          child: Text(
                            initialLetter,
                            style: GoogleFonts.jetBrainsMono(
                              color: isDark ? const Color(0xFF00E5FF) : colorScheme.primary, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            if (m.role != ConvoyRole.member) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: (switch (m.role) {
                                    ConvoyRole.leader => const Color(0xFFFFD700),
                                    ConvoyRole.sweeper => const Color(0xFF00E5FF),
                                    ConvoyRole.scout => const Color(0xFF76FF03),
                                    ConvoyRole.member => Colors.grey,
                                  }).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (switch (m.role) {
                                      ConvoyRole.leader => const Color(0xFFFFD700),
                                      ConvoyRole.sweeper => const Color(0xFF00E5FF),
                                      ConvoyRole.scout => const Color(0xFF76FF03),
                                      ConvoyRole.member => Colors.grey,
                                    }).withValues(alpha: 0.6),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  m.role.badgeText,
                                  style: GoogleFonts.shareTechMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: switch (m.role) {
                                      ConvoyRole.leader => const Color(0xFFFFD700),
                                      ConvoyRole.sweeper => const Color(0xFF00E5FF),
                                      ConvoyRole.scout => const Color(0xFF76FF03),
                                      ConvoyRole.member => Colors.grey,
                                    },
                                  ),
                                ),
                              ),
                            ],
                            Expanded(
                              child: Text(
                                displayName,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFresh ? const Color(0xFF00E676) : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isFresh ? 'LIVE' : '${secondsAgo}s',
                              style: GoogleFonts.shareTechMono(
                                fontSize: 10,
                                color: isFresh ? const Color(0xFF00E676) : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            const Icon(Icons.speed, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${(m.speedKmh ?? 0).toStringAsFixed(1)} km/h', style: GoogleFonts.jetBrainsMono(color: Colors.grey, fontSize: 12)),
                            if (distStr != null) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.near_me_outlined, size: 12, color: Colors.grey),
                              const SizedBox(width: 2),
                              Text(distStr, style: GoogleFonts.jetBrainsMono(color: isDark ? const Color(0xFF00E5FF) : colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                            if (batteryIcon != null && m.batteryPercent != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                batteryIcon,
                                size: 13,
                                color: m.batteryPercent! < 20 ? const Color(0xFFFF1744) : Colors.grey,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${m.batteryPercent}%',
                                style: GoogleFonts.jetBrainsMono(
                                  color: m.batteryPercent! < 20 ? const Color(0xFFFF1744) : Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: IconButton.filledTonal(
                          icon: const Icon(Icons.my_location, size: 18),
                          onPressed: () {
                            ref.read(focusedMemberProvider.notifier).state = m;
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
                
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF1744).withValues(alpha: 0.15),
                  foregroundColor: const Color(0xFFFF1744),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  ref.read(roomProvider.notifier).leaveRoom();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.exit_to_app),
                label: Text('LEAVE ROOM', style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
