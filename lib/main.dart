import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'fcm_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const CloudCourierApp());
}

class CloudCourierApp extends StatelessWidget {
  const CloudCourierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cloud Courier',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const CloudCourierHome(),
    );
  }
}

class CloudCourierHome extends StatefulWidget {
  const CloudCourierHome({super.key});

  @override
  State<CloudCourierHome> createState() => _CloudCourierHomeState();
}

class _CloudCourierHomeState extends State<CloudCourierHome> {
  final FCMService _fcmService = FCMService();

  StreamSubscription<FCMEvent>? _subscription;

  String _title = 'Waiting for a message';
  String _asset = 'default';
  String _lastHandler = 'None';
  String _messageId = 'None';
  String _diagnostic = 'No messages received yet.';
  String _permissionStatus = 'Not checked';
  String _tokenStatus = 'Not checked';

  int _receiptCount = 0;

  @override
  void initState() {
    super.initState();
    _startMessaging();
  }

  Future<void> _startMessaging() async {
    // Subscribe before initializing to avoid missing events.
    _subscription = _fcmService.events.listen(_processEvent);

    try {
      final settings = await _fcmService.requestPermission();

      if (!mounted) return;
      setState(() {
        _permissionStatus = settings.authorizationStatus.name;
      });

      await _fcmService.initialize();

      // Process a notification that launched the app.
      final initialEvent = _fcmService.takeInitialEvent();

      if (initialEvent != null) {
        _processEvent(initialEvent);
      }

      final token = await _fcmService.getToken();

      if (!mounted) return;
      setState(() {
        _tokenStatus = token == null ? 'Token unavailable' : 'Token available';
      });

      // Do not display the full token in screenshots.
      if (token != null) {
        debugPrint('FCM registration token: $token');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _diagnostic = 'Messaging setup failed: $error';
      });
    }
  }

  void _processEvent(FCMEvent event) {
    if (!mounted) return;

    final data = event.message.data;
    final action = data['action'];
    final asset = data['asset'];

    setState(() {
      _receiptCount++;
      _lastHandler = event.handler;
      _messageId = event.message.messageId ?? 'Unavailable';

      if (action != 'update_ui') {
        _diagnostic = 'Invalid action: ${action ?? "missing"}';
        return;
      }

      if (asset != 'default' && asset != 'promo') {
        _diagnostic = 'Unsupported asset: ${asset ?? "missing"}';
        return;
      }

      _asset = asset!;

      _title = asset == 'promo'
          ? 'New Promotion Received!'
          : 'Default Message Received';

      _diagnostic = 'Valid payload processed successfully.';
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _fcmService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPromo = _asset == 'promo';

    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Courier'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    isPromo ? Icons.local_offer : Icons.cloud_outlined,
                    size: 85,
                    color: isPromo ? Colors.orange : Colors.teal,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPromo
                        ? 'Promotional content is active.'
                        : 'Default content is active.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _infoCard('Last Handler', _lastHandler),
          _infoCard('Receipt Count', '$_receiptCount'),
          _infoCard('Message ID', _messageId),
          _infoCard('Permission', _permissionStatus),
          _infoCard('FCM Token', _tokenStatus),
          _infoCard('Diagnostic', _diagnostic),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Card(
      child: ListTile(title: Text(label), subtitle: Text(value)),
    );
  }
}
