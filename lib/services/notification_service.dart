import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/reminder.dart';
import 'package:flutter/material.dart';
import 'dart:math'; // Import for Random

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
      
  NotificationService._internal();
  
  // List of motivational messages
  static const List<String> _motivationalMessages = [
    "Keep going, you're doing great!",
    "Consistency is key to success. Don't give up!",
    "Every step counts. Log your progress today!",
    "You're building a better you, one habit at a time.",
    "Don't forget to be consistent with your habits!",
    "A little progress each day adds up to big results.",
    "Believe in yourself and all that you are.",
    "The secret of getting ahead is getting started.",
    "Your future self will thank you for your efforts today."
  ];
  
  Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('America/Los_Angeles')); 
      print("[NotificationService] Successfully set local timezone to 'America/Los_Angeles'");
    } catch (e) {
      print("[NotificationService] Error setting local timezone: $e. Falling back to system default.");
    }
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
        print('Notification tapped: \${details.payload}');
      },
    );
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }
  
  // Helper to calculate the next occurrence of a day and time as a standard DateTime
  DateTime _nextInstanceOfDayAsDateTime(int day, int hour, int minute) {
    DateTime now = DateTime.now();
    DateTime scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // Adjust to the correct weekday
    // DateTime.weekday: Monday is 1 and Sunday is 7
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If the calculated date is in the past,
    // then schedule it for the next week.
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    return scheduledDate;
  }
  
  Future<void> scheduleReminder(HabitReminder reminder, String habitName) async {
    print('[NotificationService] Attempting to schedule reminder for: ${habitName}, ID: ${reminder.id}, Enabled: ${reminder.isEnabled} using Future.delayed');
    await cancelReminder(reminder.id); // Cancel any existing first
    if (!reminder.isEnabled) {
      print('[NotificationService] Reminder ${reminder.id} is disabled. Skipping scheduling.');
      return;
    }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'habit_reminders', 'Habit Reminders',
        channelDescription: 'Notifications for habit reminders',
      importance: Importance.high, priority: Priority.high, color: Color(0xFFFF0000),
      );
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    const AndroidNotificationDetails preAndroidDetails = AndroidNotificationDetails(
      'habit_pre_reminders', 'Habit Pre-Reminders',
      channelDescription: 'Notifications 5 minutes before habit reminders',
      importance: Importance.defaultImportance, priority: Priority.defaultPriority,
    );
    const NotificationDetails preNotificationDetails = NotificationDetails(
      android: preAndroidDetails,
      iOS: DarwinNotificationDetails(presentSound: false, presentBadge: false, presentAlert: true),
    );

    for (final dayOfWeek in reminder.days) { // 'dayOfWeek' is 1 (Mon) to 7 (Sun)
      print('[NotificationService] Processing day: $dayOfWeek for reminder ${reminder.id}');
      
      final int uniquePart = reminder.id.hashCode.abs() & 0x000FFFFF;
      final int dayIndex = (dayOfWeek - 1) & 0x07; // For ID generation consistency, not direct scheduling

      final int mainNotificationId = (uniquePart << 4) | (dayIndex << 1) | 0; 
      final int preNotificationId  = (uniquePart << 4) | (dayIndex << 1) | 1;
      
      print('[NotificationService] Generated IDs for day $dayOfWeek - Main: $mainNotificationId, Pre: $preNotificationId');

      DateTime mainScheduledDateTime = _nextInstanceOfDayAsDateTime(dayOfWeek, reminder.time.hour, reminder.time.minute);
      DateTime preScheduledDateTime = mainScheduledDateTime.subtract(const Duration(minutes: 5));
      DateTime now = DateTime.now();
      
      // Schedule Pre-Reminder
      if (preScheduledDateTime.isAfter(now)) {
        Duration durationUntilPre = preScheduledDateTime.difference(now);
        print('[NotificationService] Pre-Reminder for $habitName (ID: $preNotificationId) will be shown in $durationUntilPre. Scheduled at: $preScheduledDateTime');
        
        Future.delayed(durationUntilPre, () async {
          print('[NotificationService] Future.delayed (pre-reminder) complete for $habitName (ID: $preNotificationId). Showing notification.');
          await flutterLocalNotificationsPlugin.show(
            preNotificationId,
            'Upcoming: $habitName in 5 minutes',
            reminder.message,
            preNotificationDetails,
            payload: 'pre_\${reminder.habitId}',
          );
        });
      } else {
        print('[NotificationService] SKIPPED Pre-Reminder for $habitName (ID: $preNotificationId) as its time $preScheduledDateTime is in the past.');
      }

      // Schedule Main Reminder
      if (mainScheduledDateTime.isAfter(now)) {
        Duration durationUntilMain = mainScheduledDateTime.difference(now);
        print('[NotificationService] Main Reminder for $habitName (ID: $mainNotificationId) will be shown in $durationUntilMain. Scheduled at: $mainScheduledDateTime');

        Future.delayed(durationUntilMain, () async {
          print('[NotificationService] Future.delayed (main reminder) complete for $habitName (ID: $mainNotificationId). Showing notification.');
          await flutterLocalNotificationsPlugin.show(
            mainNotificationId,
            'Reminder: $habitName',
        reminder.message,
        notificationDetails,
        payload: reminder.habitId,
      );
        });
      } else {
         print('[NotificationService] SKIPPED Main Reminder for $habitName (ID: $mainNotificationId) as its time $mainScheduledDateTime is in the past.');
      }
    }
  }
  
  Future<void> cancelReminder(String reminderIdString) async {
    print('[NotificationService] Attempting to cancel reminders for string ID: $reminderIdString');
    // This cancellation logic remains the same as it cancels based on notification IDs,
    // which are still generated per day. Futures themselves are not directly "cancelled"
    // here, but by cancelling the ID, if the Future fires, the .show() might be
    // superseded or the OS might not display a new one if an old one with that ID was active.
    // For true Future cancellation, one would need to manage Completers or similar.
    // However, for this plugin, cancelling the ID is the main mechanism.
    final int uniquePart = reminderIdString.hashCode.abs() & 0x000FFFFF;

    for (int day = 1; day <= 7; day++) {
      final int dayIndex = (day - 1) & 0x07;
      final int mainNotificationId = (uniquePart << 4) | (dayIndex << 1) | 0;
      final int preNotificationId  = (uniquePart << 4) | (dayIndex << 1) | 1;
      
      await flutterLocalNotificationsPlugin.cancel(mainNotificationId);
      await flutterLocalNotificationsPlugin.cancel(preNotificationId);
    }
    print('[NotificationService] Cancelled all potential notifications (main and pre) for reminder string ID: $reminderIdString by ID.');
  }
  
  Future<void> cancelAllReminders() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print('[NotificationService] All notifications cancelled.');
  }
  
  Future<void> scheduleEngagementNotification() async {
    const int engagementNotificationId = 9999;
    const String channelId = 'engagement_notifications';
    const String channelName = 'Stay Engaged';
    const String channelDescription = 'Notifications to encourage app usage.';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId, channelName, channelDescription: channelDescription,
      importance: Importance.low, priority: Priority.low,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    DateTime now = DateTime.now();
    DateTime scheduledTimeToday = DateTime(now.year, now.month, now.day, 10); // 10 AM today
    DateTime scheduledDateTime;

    if (scheduledTimeToday.isAfter(now)) {
      scheduledDateTime = scheduledTimeToday;
    } else {
      scheduledDateTime = scheduledTimeToday.add(const Duration(days: 1)); // 10 AM tomorrow
    }
    
    Duration delay = scheduledDateTime.difference(now);

    if (delay.isNegative) { // Should not happen with above logic, but as a safeguard
        print('[NotificationService] Engagement notification delay is negative. Skipping.');
        return;
    }

    print('[NotificationService] Engagement notification will be shown in $delay. Scheduled for: $scheduledDateTime');

    Future.delayed(delay, () async {
      print('[NotificationService] Future.delayed (engagement) complete. Showing notification.');
      await flutterLocalNotificationsPlugin.show(
        engagementNotificationId,
        'Stay on Track!',
        'Don\'t forget to check in on your habits today. Great things take time!',
        notificationDetails,
        payload: 'engagement_reminder',
    );
    });
  }
  
  Future<void> scheduleMotivationNotification() async {
    const int baseMotivationNotificationId = 9998; 
    const String channelId = 'motivation_notifications';
    const String channelName = 'Stay Motivated';
    const String channelDescription = 'Random motivational messages to keep you going.';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId, channelName, channelDescription: channelDescription,
      importance: Importance.max, priority: Priority.high,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: false, presentSound: true),
    );

    final Random random = Random();
    final List<int> delays = [30, 60, 90];

    for (int i = 0; i < delays.length; i++) {
      final int notificationId = baseMotivationNotificationId - i; 
      final int delayInSeconds = delays[i];
      final String randomMessage = _motivationalMessages[random.nextInt(_motivationalMessages.length)];

      print('[NotificationService] Setting up Future.delayed for ${delayInSeconds}s to show motivational notification (ID: $notificationId).');

      Future.delayed(Duration(seconds: delayInSeconds), () async {
        print('[NotificationService] Future.delayed (${delayInSeconds}s) complete. Showing notification ID: $notificationId');
        await flutterLocalNotificationsPlugin.cancel(notificationId); 
        
        await flutterLocalNotificationsPlugin.show(
          notificationId,
          'Quick Boost! 😍', 
          randomMessage, 
          notificationDetails,
          payload: 'motivation_custom_delayed_${delayInSeconds}s_ID${notificationId}',
        );
        print('[NotificationService] Shown motivational notification (ID: $notificationId) via Future.delayed.');
      });
    }
  }
}