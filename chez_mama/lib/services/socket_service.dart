import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../api/api_config.dart';
import '../auth/auth_service.dart';
import '../storage/token_storage.dart';

/// Realtime Socket.IO client (JWT auth, room join, event helpers).
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  AuthService? _auth;
  VoidCallback? _authListener;
  bool _connecting = false;

  bool get isConnected => _socket?.connected == true;

  /// Wire to [AuthService] so we connect on login and disconnect on logout.
  void bindAuth(AuthService auth) {
    if (_auth == auth) return;
    if (_auth != null && _authListener != null) {
      _auth!.removeListener(_authListener!);
    }
    _auth = auth;
    _authListener = () {
      if (auth.isAuthed) {
        unawaited(connect());
      } else {
        disconnect();
      }
    };
    auth.addListener(_authListener!);
    if (auth.isAuthed) {
      unawaited(connect());
    }
  }

  Future<void> connect() async {
    if (_connecting || isConnected) return;
    final token = await TokenStorage.instance.readAccess();
    if (token == null || token.isEmpty) return;

    _connecting = true;
    try {
      disconnect(notify: false);
      final socket = io.io(
        ApiConfig.socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setPath('/socket.io/')
            .setAuth({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );
      _socket = socket;
      socket.onConnect((_) {
        if (kDebugMode) debugPrint('[SocketService] connected');
      });
      socket.onDisconnect((_) {
        if (kDebugMode) debugPrint('[SocketService] disconnected');
      });
      socket.onConnectError((e) {
        if (kDebugMode) debugPrint('[SocketService] connect error: $e');
      });
    } finally {
      _connecting = false;
    }
  }

  void disconnect({bool notify = true}) {
    final s = _socket;
    _socket = null;
    if (s != null) {
      s.clearListeners();
      s.disconnect();
      s.dispose();
    }
  }

  void join(List<String> rooms) {
    if (!isConnected || rooms.isEmpty) return;
    _socket!.emit('join', rooms);
  }

  void leave(List<String> rooms) {
    if (!isConnected || rooms.isEmpty) return;
    _socket!.emit('leave', rooms);
  }

  void on(String event, void Function(dynamic data) handler) {
    _socket?.on(event, handler);
  }

  void off(String event, [void Function(dynamic data)? handler]) {
    if (handler != null) {
      _socket?.off(event, handler);
    } else {
      _socket?.off(event);
    }
  }

  void emit(String event, [dynamic data]) {
    if (!isConnected) return;
    if (data == null) {
      _socket!.emit(event);
    } else {
      _socket!.emit(event, data);
    }
  }

  // Convenience event names
  static const eventNotification = 'notification';
  static const eventOrderStatus = 'order:status';
  static const eventChatMessage = 'chat:message';
  static const eventChatTyping = 'chat:typing';
  static const eventChatRead = 'chat:read';
  static const eventDeliveryLocation = 'delivery:location';
}
