import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notifica locale al termine della scansione (canale Android).
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _plugin.initialize(initSettings);
    const channel = AndroidNotificationChannel(
      'photoai_scan',
      'Scansione PhotoAI',
      description: 'Avviso al termine della scansione del dispositivo',
      importance: Importance.defaultImportance,
    );
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(channel);
    _inited = true;
  }

  static Future<void> requestPermissionIfNeeded() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  static Future<void> showScanComplete({required int processed, String? title}) async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'photoai_scan',
        'Scansione PhotoAI',
        channelDescription: 'Avviso al termine della scansione',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(
      1001,
      title ?? 'PhotoAI — Scansione completata',
      'Indicizzate $processed foto. Apri l\'app per vedere gli album.',
      details,
    );
  }

  static Future<void> showScanError(String message) async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'photoai_scan',
        'Scansione PhotoAI',
        channelDescription: 'Errori scansione',
        importance: Importance.defaultImportance,
      ),
    );
    await _plugin.show(1002, 'PhotoAI — Scansione', message, details);
  }
}
