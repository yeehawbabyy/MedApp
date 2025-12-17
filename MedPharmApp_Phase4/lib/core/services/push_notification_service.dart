import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  PushNotificationService._internal();
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final StreamController<NotificationPayload> _notificationStreamController =
      StreamController<NotificationPayload>.broadcast();

  Stream<NotificationPayload> get notificationStream =>
      _notificationStreamController.stream;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  static const String _channelIdReminders = 'reminders';
  static const String _channelNameReminders = 'Przypomnienia o ankietach';
  static const String _channelIdAlerts = 'alerts';
  static const String _channelNameAlerts = 'Ważne powiadomienia';

  Future<void> initialize() async {
    print('Initializing Push Notification Service...');

    await _initializeLocalNotifications();

    await _initializeFCM();

    print('Push Notification Service initialized');
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdReminders,
          _channelNameReminders,
          description: 'Przypomnienia o wypełnieniu ankiet zdrowotnych',
          importance: Importance.high,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdAlerts,
          _channelNameAlerts,
          description: 'Ważne powiadomienia z badania klinicznego',
          importance: Importance.max,
        ),
      );
    }
  }

  Future<void> _initializeFCM() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('FCM permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      _fcmToken = await _fcm.getToken();
      print('FCM Token: $_fcmToken');

      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('FCM Token refreshed: $newToken');
      });

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('FCM foreground message: ${message.messageId}');

    final notification = message.notification;
    if (notification != null) {
      showNotification(
        title: notification.title ?? 'MedPharm',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
        isReminder: false,
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('App opened via FCM notification: ${message.messageId}');

    final payload = NotificationPayload.fromFCM(message.data);
    _notificationStreamController.add(payload);
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.id}');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        final payload = NotificationPayload.fromMap(data);
        _notificationStreamController.add(payload);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    bool isReminder = false,
    int? id,
  }) async {
    final notificationId = id ?? DateTime.now().millisecondsSinceEpoch % 100000;

    final androidDetails = AndroidNotificationDetails(
      isReminder ? _channelIdReminders : _channelIdAlerts,
      isReminder ? _channelNameReminders : _channelNameAlerts,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notificationId,
      title,
      body,
      details,
      payload: payload,
    );

    print('Notification shown: $title');
  }

  Future<void> scheduleQuestionnaireReminder({
    required DateTime scheduledTime,
    required String questionnaireId,
    String? title,
    String? body,
  }) async {
    final notificationId = questionnaireId.hashCode % 100000;

    final payload = jsonEncode({
      'type': 'questionnaire_reminder',
      'questionnaire_id': questionnaireId,
    });

    final androidDetails = AndroidNotificationDetails(
      _channelIdReminders,
      _channelNameReminders,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      notificationId,
      title ?? 'Czas na ankietę',
      body ?? 'Nie zapomnij wypełnić dzisiejszej ankiety zdrowotnej',
      _convertToTZDateTime(scheduledTime),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    print('Reminder scheduled for: $scheduledTime');
  }

  Future<void> scheduleRemindMeLater({
    required String questionnaireId,
    int hours = 1,
  }) async {
    final scheduledTime = DateTime.now().add(Duration(hours: hours));

    await scheduleQuestionnaireReminder(
      scheduledTime: scheduledTime,
      questionnaireId: questionnaireId,
      title: 'Przypomnienie',
      body: 'Przypominamy o wypełnieniu ankiety zdrowotnej',
    );
  }

  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required String studyId,
  }) async {
    await cancelDailyReminder();

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final payload = jsonEncode({
      'type': 'daily_reminder',
      'study_id': studyId,
    });

    final androidDetails = AndroidNotificationDetails(
      _channelIdReminders,
      _channelNameReminders,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      _dailyReminderId,
      'Dzienna ankieta',
      'Czas na wypełnienie dziennej ankiety zdrowotnej',
      _convertToTZDateTime(scheduledDate),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, 
      payload: payload,
    );

    print('Daily reminder scheduled for: ${time.hour}:${time.minute}');
  }

  Future<void> cancelDailyReminder() async {
    await _localNotifications.cancel(_dailyReminderId);
    print('Daily reminder cancelled');
  }

  static const int _dailyReminderId = 999999;

  _convertToTZDateTime(DateTime dateTime) {
    return dateTime;
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  Future<void> cancelQuestionnaireReminder(String questionnaireId) async {
    final notificationId = questionnaireId.hashCode % 100000;
    await cancelNotification(notificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    print('All notifications cancelled');
  }

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    }

    if (Platform.isIOS) {
      final iosPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }

    return false;
  }

  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        return await androidPlugin.areNotificationsEnabled() ?? false;
      }
    }

    return true;
  }

  void dispose() {
    _notificationStreamController.close();
  }
}

class NotificationPayload {
  final String type;
  final String? questionnaireId;
  final String? studyId;
  final Map<String, dynamic>? data;

  NotificationPayload({
    required this.type,
    this.questionnaireId,
    this.studyId,
    this.data,
  });

  factory NotificationPayload.fromMap(Map<String, dynamic> map) {
    return NotificationPayload(
      type: map['type'] as String? ?? 'unknown',
      questionnaireId: map['questionnaire_id'] as String?,
      studyId: map['study_id'] as String?,
      data: map,
    );
  }

  factory NotificationPayload.fromFCM(Map<String, dynamic> fcmData) {
    return NotificationPayload(
      type: fcmData['type'] as String? ?? 'fcm_notification',
      questionnaireId: fcmData['questionnaire_id'] as String?,
      studyId: fcmData['study_id'] as String?,
      data: fcmData,
    );
  }

  @override
  String toString() {
    return 'NotificationPayload(type: $type, questionnaireId: $questionnaireId, studyId: $studyId)';
  }
}
