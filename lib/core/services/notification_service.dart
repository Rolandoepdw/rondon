import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as dev;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        dev.log('Notification tapped: ${details.payload}', name: 'NOTIFICATIONS');
      },
    );
    dev.log('Notifications initialized', name: 'NOTIFICATIONS');
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'rondon_alerts',
      'Alertas Rondon',
      channelDescription: 'Recordatorios de guardias y auditorías',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const details = NotificationDetails(android: androidDetails);
    
    await _notifications.show(id, title, body, details, payload: payload);
  }
}
