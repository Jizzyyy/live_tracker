import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/src/core/services/websocket_service.dart';

void main() {
  test('WebSocketService parses URI correctly and translates schemes', () {
    final ws = WebSocketService();
    try {
      ws.connect('http://localhost:8080');
      ws.disconnect();
      
      ws.connect('https://example.com/ws');
      ws.disconnect();

      ws.connect('ws://localhost:8080');
      ws.disconnect();

      ws.connect('wss://example.com/ws');
      ws.disconnect();
    } catch (e) {
      fail('Failed: $e');
    }
  });
}
