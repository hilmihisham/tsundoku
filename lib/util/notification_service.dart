import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _internal = NotificationService._();
  factory NotificationService() => _internal;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Initialize the notification service
  Future<void> initNotifications() async {
    // Initialize timezone data for scheduled notifications
    tz.initializeTimeZones();

    // Android settings: use the default icon for notifications
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('notification_icon');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap logic here (e.g., navigate to a specific screen)
        Logger().i('Notification tapped: ${response.payload}');
      },
    ); 
  }

  // helper for notification channels details
  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'tsundoku_notif_channel', // unique channel ID
        'Weekly Tsundoku Notifications', // channel name
        channelDescription: 'Weekly Notifications for Tsundoku app showing your current book count', // channel description
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        styleInformation: BigTextStyleInformation(''),
      ),
    );
  }

  // show scheduled notification
  Future<void> showScheduledNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDateTime, tz.local),
      notificationDetails: _notificationDetails(),
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at the same time
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Ensure the notification is delivered even in low power mode
    );
  }

  // show notification in next set seconds
  Future<void> showNextSecondsNotification({
    required int id,
    required String title,
    required String body,
    required int secondsFromNow,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.now(tz.local).add(Duration(seconds: secondsFromNow)),
      notificationDetails: _notificationDetails(),
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at the same time
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Ensure the notification is delivered even in low power mode
    );
  }

  // cancel specific notifications
  Future<void> cancelNotifications(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }
      
}