import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

class FCMEvent {
  final RemoteMessage message;
  final String handler;

  FCMEvent({required this.message, required this.handler});
}

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final StreamController<FCMEvent> _events =
      StreamController<FCMEvent>.broadcast();

  Stream<FCMEvent> get events => _events.stream;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  FCMEvent? _initialEvent;

  FCMEvent? takeInitialEvent() {
    final event = _initialEvent;
    _initialEvent = null;
    return event;
  }

  Future<NotificationSettings> requestPermission() async {
    return _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<String?> getToken() async {
    return _messaging.getToken();
  }

  Future<void> initialize() async {
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      _events.add(FCMEvent(message: message, handler: 'onMessage'));
    });

    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      _events.add(FCMEvent(message: message, handler: 'onMessageOpenedApp'));
    });

    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      _initialEvent = FCMEvent(
        message: initialMessage,
        handler: 'getInitialMessage',
      );
    }
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _events.close();
  }
}
