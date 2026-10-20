import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/tracker_models.dart';
import '../providers/tracker_providers.dart';
import '../utils/ui_helpers.dart';
import '../screens/history/trip_history_screen.dart';
import 'modals/member_list_sheet.dart';
import 'modals/settings_sheet.dart';
import 'modals/join_create_room_sheet.dart';
import 'modals/quick_ping_sheet.dart';
import 'modals/tactical_chat_sheet.dart';
import 'modals/tactical_guide_sheet.dart';
import '../utils/custom_snackbar.dart';
import '../utils/app_theme.dart';

class TopHeaderHub extends ConsumerStatefulWidget {
  const TopHeaderHub({super.key});

  @override
  ConsumerState<TopHeaderHub> createState() => _TopHeaderHubState();
}

class _TopHeaderHubState extends ConsumerState<TopHeaderHub> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(roomProvider.select((r) => r.status));
    final roomCode = ref.watch(roomProvider.select((r) => r.roomCode));
    final membersCount = ref.watch(roomProvider.select((r) => r.members.length));
    final unreadChat = ref.watch(roomProvider.select((r) => r.unreadChatCount));
    final s = ref.watch(appStringsProvider);
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: FocusScope(
            child: Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus && _isExpanded) {
                  setState(() => _isExpanded = false);
                }
              },
              child: PremiumGlass(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                borderRadius: BorderRadius.circular(32),
                enableBlur: false, // Solid lightweight surface for high performance
                child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: _isExpanded
                      ? Row(
                          key: const ValueKey('expanded_hub'),
                          children: [
                            _PulseDot(status: status),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: [
                                    _ActionButton(
                                      icon: Icons.map_outlined,
                                      onTap: () {
                                        setState(() => _isExpanded = false);
                                        _showMapStyleSheet(context, ref);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionButton(
                                      icon: Icons.campaign_rounded,
                                      iconColor: AppTheme.primaryCyan,
                                      backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.15),
                                      onTap: () {
                                        setState(() => _isExpanded = false);
                                        _showQuickPingSheet(context);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionButton(
                                      icon: Icons.forum_outlined,
                                      iconColor: AppTheme.primaryCyan,
                                      badgeCount: unreadChat > 0 ? unreadChat : null,
                                      onTap: () {
                                        setState(() => _isExpanded = false);
                                        _showChatSheet(context);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionButton(
                                      icon: Icons.group_outlined,
                                      badgeCount: membersCount,
                                      onTap: () {
                                        setState(() => _isExpanded = false);
                                        if (roomCode == null) {
                                          showModalBottomSheet(
                                            context: context,
                                            backgroundColor: Colors.transparent,
                                            isScrollControlled: true,
                                            builder: (_) => const JoinCreateRoomSheet(),
                                          );
                                        } else {
                                          _showMemberSheet(context);
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionButton(
                                      icon: Icons.history,
                                      onTap: () {
                                        setState(() => _isExpanded = false);
                                        _showHistorySheet(context);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionButton(
                                      icon: Icons.undo_rounded,
                                      iconColor: AppTheme.accentOrange,
                                      backgroundColor: ref.watch(backtrackActiveProvider)
                                          ? AppTheme.accentOrange.withValues(alpha: 0.25)
                                          : null,
                                      onTap: () {
                                        setState(() => _isExpanded = false);
                                        final isAct = ref.read(backtrackActiveProvider);
                                        ref.read(backtrackActiveProvider.notifier).state = !isAct;
                                        CustomSnackbar.show(
                                          context,
                                          message: !isAct ? s.backtrackActive : s.backtrackDeactivated,
                                          type: SnackbarType.info,
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionButton(
                                      icon: Icons.settings_outlined,
                                      onTap: () {
                                        setState(() => _isExpanded = false);
                                        _showSettingsSheet(context);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionButton(
                                      icon: Icons.menu_book_rounded,
                                      iconColor: AppTheme.primaryCyan,
                                      onTap: () {
                                        setState(() => _isExpanded = false);
                                        _showGuideSheet(context);
                                      },
                                    ),
                                    if (roomCode != null) ...[
                                      const SizedBox(width: 8),
                                      _ActionButton(
                                        icon: Icons.share_rounded,
                                        iconColor: const Color(0xFF69F0AE),
                                        onTap: () {
                                          setState(() => _isExpanded = false);
                                          HapticFeedback.lightImpact();
                                          Clipboard.setData(ClipboardData(text: roomCode));
                                          SharePlus.instance.share(
                                            ShareParams(
                                              text: s.shareRoomInvite(roomCode),
                                              subject: s.shareRoomSubject,
                                            ),
                                          );
                                          CustomSnackbar.show(
                                            context,
                                            message: s.roomCodeCopiedDetail(roomCode),
                                            type: SnackbarType.success,
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      _ActionButton(
                                        icon: Icons.logout_rounded,
                                        iconColor: Colors.redAccent,
                                        onTap: () {
                                          setState(() => _isExpanded = false);
                                          HapticFeedback.lightImpact();
                                          _confirmLeaveRoom(context);
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _ActionButton(
                              icon: Icons.close_rounded,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _isExpanded = false);
                              },
                            ),
                          ],
                        )
                      : Row(
                          key: const ValueKey('collapsed_hub'),
                          children: [
                            _PulseDot(status: status),
                            const SizedBox(width: 10),
                            Expanded(
                              child: roomCode != null
                                  ? InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        Clipboard.setData(ClipboardData(text: roomCode));
                                        CustomSnackbar.show(
                                          context,
                                          message: s.roomCodeCopied,
                                          type: SnackbarType.success,
                                        );
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.meeting_room_outlined, size: 16, color: AppTheme.primaryCyan),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              roomCode,
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.5,
                                                color: theme.colorScheme.onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(Icons.copy_rounded, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                        ],
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset(
                                            'assets/images/app_logo.png',
                                            height: 24,
                                            width: 24,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Icon(Icons.track_changes, size: 24, color: theme.colorScheme.primary),
                                          ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Live Tracker',
                                            style: GoogleFonts.inter(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            const SizedBox(width: 6),
                            if (roomCode != null) ...[
                              _ActionButton(
                                icon: Icons.campaign_rounded,
                                iconColor: AppTheme.primaryCyan,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _showQuickPingSheet(context);
                                },
                              ),
                              const SizedBox(width: 4),
                              _ActionButton(
                                icon: Icons.forum_outlined,
                                iconColor: AppTheme.primaryCyan,
                                badgeCount: unreadChat > 0 ? unreadChat : null,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _showChatSheet(context);
                                },
                              ),
                              const SizedBox(width: 4),
                            ],
                            _ActionButton(
                              icon: Icons.more_vert_rounded,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _isExpanded = true);
                              },
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  void _showMapStyleSheet(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mapStyles = ref.watch(mapStyleListProvider);
    final currentStyleId = ref.watch(mapStyleProvider.select((s) => s.id));
    final s = ref.read(appStringsProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          child: PremiumGlass(
            borderRadius: AppTheme.borderRadiusSheet,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.layers_outlined, color: AppTheme.primaryCyan, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.mapStyleAndEngine,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                const SizedBox(height: 4),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: mapStyles.length,
                    separatorBuilder: (_, _) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                    itemBuilder: (context, index) {
                      final style = mapStyles[index];
                      final isSelected = currentStyleId == style.id;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        title: Text(
                          style.name,
                          style: GoogleFonts.inter(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppTheme.primaryCyan : theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          style.attribution,
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryCyan, size: 22)
                            : null,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(mapStyleProvider.notifier).state = style;
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLeaveRoom(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.read(appStringsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          s.leaveRoomTitle,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textDark),
        ),
        content: Text(
          s.leaveRoomDesc,
          style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF4A5568)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(roomProvider.notifier).leaveRoom();
              CustomSnackbar.show(context, message: s.leftRoomSuccess, type: SnackbarType.info);
            },
            child: Text(s.leaveRoomConfirm, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showQuickPingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const QuickPingSelectorSheet(),
    );
  }

  void _showChatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const TacticalChatSheet(),
    );
  }

  void _showMemberSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const MemberListSheet(),
    );
  }

  void _showHistorySheet(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TripHistoryScreen()));
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SettingsSheet(),
    );
  }

  void _showGuideSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const TacticalGuideSheet(),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final TrackingConnectionStatus status;
  const _PulseDot({required this.status});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _updateAnimation();
  }

  @override
  void didUpdateWidget(_PulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.status == TrackingConnectionStatus.disconnected) {
      _ctrl.stop();
      _ctrl.value = 0.0;
    } else {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() { 
    _ctrl.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (widget.status) {
      TrackingConnectionStatus.connected => Colors.greenAccent,
      TrackingConnectionStatus.reconnecting => Colors.amberAccent,
      TrackingConnectionStatus.disconnected => theme.colorScheme.error,
    };
    
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.2 + 0.4 * _ctrl.value), blurRadius: 8, spreadRadius: 2)
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;
  final Color? iconColor;
  final Color? backgroundColor;

  static const double buttonSize = 44.0;
  static const double iconSize = 22.0;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.badgeCount,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.colorScheme.surface.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: iconSize, color: iconColor ?? theme.colorScheme.onSurface),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                  child: Text(
                    badgeCount.toString(),
                    style: TextStyle(fontSize: 9, color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
