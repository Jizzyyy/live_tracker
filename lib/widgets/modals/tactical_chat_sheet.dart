import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/tracker_models.dart';
import '../../providers/tracker_providers.dart';
import '../../utils/ui_helpers.dart';
import '../../utils/app_theme.dart';

class TacticalChatSheet extends ConsumerStatefulWidget {
  const TacticalChatSheet({super.key});

  @override
  ConsumerState<TacticalChatSheet> createState() => _TacticalChatSheetState();
}

class _TacticalChatSheetState extends ConsumerState<TacticalChatSheet> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  static const _quickPhrases = [
    '👍 Siap!',
    '🚀 Gas lanjut!',
    '⛽ Butuh SPBU / bensin',
    '⚠️ Hati-hati jalan licin / rusak',
    '🛑 Tunggu di depan',
    '☕ Istirahat sejenak',
    '👋 Tertinggal, tunggu ya',
  ];

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(roomProvider.notifier).markChatAsRead();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? presetText]) {
    final text = presetText ?? _textController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    ref.read(roomProvider.notifier).sendChatMessage(text);
    if (presetText == null) {
      _textController.clear();
    }

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = ref.watch(appStringsProvider);
    final roomCode = ref.watch(roomProvider.select((r) => r.roomCode));
    final messages = ref.watch(roomProvider.select((r) => r.chatMessages));
    final myName = ref.watch(appSettingsProvider.select((s) => s.userName.trim()));
    final effectiveMyName = myName.isNotEmpty ? myName : 'ME';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: PremiumGlass(
            borderRadius: AppTheme.borderRadiusSheet,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Sheet Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.forum_outlined, color: AppTheme.primaryCyan, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(
                          s.tacticalChatTitle,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppTheme.primaryCyan,
                          ),
                        ),
                          Text(
                            roomCode != null
                                ? s.roomChatSubtitle(roomCode, messages.length)
                                : s.soloModeChatSubtitle,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quick Tactical Phrase Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _quickPhrases.map((phrase) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(
                            phrase,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                          side: BorderSide(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          onPressed: () => _sendMessage(phrase),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                const SizedBox(height: 10),

                // Message Feed
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 36,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                s.noChatYet,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                              Text(
                                s.tapPhrasePrompt,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isMe = msg.userId == effectiveMyName ||
                                (msg.senderName != null && msg.senderName == effectiveMyName);

                            return _ChatBubble(
                              message: msg,
                              isMe: isMe,
                              isDark: isDark,
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),

                // Input Bar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        child: TextField(
                          controller: _textController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: s.typeTacticalMessage,
                            hintStyle: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryCyan,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                        onPressed: () => _sendMessage(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isDark;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.darkCard,
              child: Text(
                message.callerDisplayName.substring(0, 1).toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryCyan,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? AppTheme.primaryCyan
                    : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 2),
                  bottomRight: Radius.circular(isMe ? 2 : 14),
                ),
                border: Border.all(
                  color: isMe
                      ? AppTheme.primaryCyan
                      : (isDark ? Colors.white12 : Colors.black12),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.callerDisplayName,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryCyan,
                      ),
                    ),
                  Text(
                    message.text,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isMe ? Colors.black : (isDark ? Colors.white : Colors.black87),
                      fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.formattedTime,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: isMe ? Colors.black54 : (isDark ? Colors.white38 : Colors.black38),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
