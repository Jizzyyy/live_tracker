import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  String? _url;
  int _reconnectAttempts = 0;
  bool _intentionalClose = false;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  bool get isConnected => _channel != null;

  void connect(String url) {
    // Close existing connection before starting new one
    disconnect();
    _url = url;
    _intentionalClose = false;
    _reconnectAttempts = 0;
    _doConnect();
  }

  void _doConnect() {
    if (_url == null) return;

    // Close any orphaned previous connection
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;

    // Ensure URL has ws: or wss: scheme
    String wsUrl = _url!;
    if (wsUrl.startsWith('http://')) {
      wsUrl = wsUrl.replaceFirst('http://', 'ws://');
    } else if (wsUrl.startsWith('https://')) {
      wsUrl = wsUrl.replaceFirst('https://', 'wss://');
    } else if (!wsUrl.startsWith('ws://') && !wsUrl.startsWith('wss://')) {
      wsUrl = 'wss://$wsUrl'; // Default to secure wss:// for public servers
    }

    try {
      // Some versions of web_socket_channel expect Uri, others expect String or Uri.
      // We parse it and pass the Uri. If that fails, we fallback to String or handle error gracefully.
      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);
    } catch (e) {
      debugPrint('WS connection initiation failed: $e');
      _channel = null;
      if (!_intentionalClose) _scheduleReconnect();
      return;
    }

    _reconnectAttempts = 0;

    _subscription = _channel!.stream.listen(
      (data) {
        if (_messageController.isClosed) return;
        try {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          _messageController.add(json);
        } catch (e) {
          debugPrint('WS parse error: $e');
        }
      },
      onDone: () {
        _channel = null;
        if (!_intentionalClose) _scheduleReconnect();
      },
      onError: (error) {
        debugPrint('WS error: $error');
        _channel = null;
        if (!_intentionalClose) _scheduleReconnect();
      },
    );
  }

  void send(Map<String, dynamic> data) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(data));
  }

  void disconnect() {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final delay = min(pow(2, _reconnectAttempts).toInt(), 30);
    _reconnectAttempts++;
    debugPrint('WS reconnecting in ${delay}s (attempt $_reconnectAttempts)');
    _reconnectTimer = Timer(Duration(seconds: delay), _doConnect);
  }

  void dispose() {
    disconnect();
    if (!_messageController.isClosed) _messageController.close();
  }
}
