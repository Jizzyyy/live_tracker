import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/models/tracker_models.dart';
import 'package:live_tracker/providers/tracker_providers.dart';

void main() {
  group('TacticalChatSerializationTest', () {
    test('ChatMessage correctly serializes to and from JSON', () {
      final now = DateTime(2026, 10, 2, 14, 35);
      final msg = ChatMessage(
        id: 'msg_001',
        userId: 'usr_falcon',
        senderName: 'Falcon Leader',
        text: 'Hati-hati tanjakan licin di depan',
        timestamp: now,
        isSystem: false,
      );

      final json = msg.toJson();
      expect(json['id'], 'msg_001');
      expect(json['userId'], 'usr_falcon');
      expect(json['senderName'], 'Falcon Leader');
      expect(json['text'], 'Hati-hati tanjakan licin di depan');
      expect(json['timestamp'], now.millisecondsSinceEpoch);
      expect(json['isSystem'], isFalse);

      final reconstructed = ChatMessage.fromJson(json);
      expect(reconstructed.id, msg.id);
      expect(reconstructed.userId, msg.userId);
      expect(reconstructed.senderName, msg.senderName);
      expect(reconstructed.text, msg.text);
      expect(reconstructed.timestamp.millisecondsSinceEpoch, msg.timestamp.millisecondsSinceEpoch);
      expect(reconstructed.isSystem, isFalse);
    });

    test('ChatMessage callerDisplayName and formattedTime formatting', () {
      final now = DateTime(2026, 10, 2, 8, 5);
      final msgWithCallsign = ChatMessage(
        id: 'msg_002',
        userId: 'u88',
        senderName: 'Ghost Rider',
        text: 'Gas terus bro',
        timestamp: now,
      );
      expect(msgWithCallsign.callerDisplayName, 'Ghost Rider');
      expect(msgWithCallsign.formattedTime, '08:05');

      final msgWithoutCallsign = ChatMessage(
        id: 'msg_003',
        userId: 'u88',
        senderName: null,
        text: 'Siap',
        timestamp: now,
      );
      expect(msgWithoutCallsign.callerDisplayName, 'User u88');

      final msgEmptyCallsign = ChatMessage(
        id: 'msg_004',
        userId: 'u88',
        senderName: '   ',
        text: 'Siap',
        timestamp: now,
      );
      expect(msgEmptyCallsign.callerDisplayName, 'User u88');
    });

    test('RoomState holds chatMessages and unreadChatCount mutations', () {
      const initial = RoomState();
      expect(initial.chatMessages, isEmpty);
      expect(initial.unreadChatCount, 0);

      final msg1 = ChatMessage(
        id: 'c1',
        userId: 'u1',
        text: 'Tunggu di pertigaan',
        timestamp: DateTime.now(),
      );

      final withMsg = initial.copyWith(
        chatMessages: [msg1],
        unreadChatCount: 1,
      );

      expect(withMsg.chatMessages.length, 1);
      expect(withMsg.chatMessages.first.text, 'Tunggu di pertigaan');
      expect(withMsg.unreadChatCount, 1);

      final read = withMsg.copyWith(unreadChatCount: 0);
      expect(read.unreadChatCount, 0);
      expect(read.chatMessages.length, 1);
    });
  });
}
