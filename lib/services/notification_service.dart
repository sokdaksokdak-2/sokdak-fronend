// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// 전역 플러그인 인스턴스
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// 앱 시작 시 한 번만 호출
Future<void> initializeNotificationService() async {
  tz.initializeTimeZones();
  final String localName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(localName));
  debugPrint('[초기화] 알림 서비스 • 시간대: $localName');

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
  );

  const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
    'daily_notification_channel_id',
    'Daily Notifications',
    description: '매일 정해진 시간에 감정 기록 알림',
    importance: Importance.high,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(defaultChannel);

  final status = await Permission.notification.request();
  debugPrint('[권한요청] $status');
  final granted = await Permission.notification.isGranted;
  debugPrint('[권한확인] 허용됨? $granted');
}

/// 즉시 알림 테스트
Future<void> sendTestNotification() async {
  const androidDetails = AndroidNotificationDetails(
    'daily_notification_channel_id',
    'Daily Notifications',
    channelDescription: '매일 정해진 시간에 감정 기록 알림',
    importance: Importance.max,
    priority: Priority.high,
  );
  const details = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(
    999,
    '테스트 알림',
    '이 메시지가 보이면 알림이 정상 작동 중입니다.',
    details,
  );
  debugPrint('[테스트알림] 발송 완료');
}

/// 매일 같은 시간에 반복 알림 예약
Future<void> scheduleDailyNotification(TimeOfDay time) async {
  final now = tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );

  // 너무 가까운 시각(예: 지금~1분 이내)이면 다음 날로 미룸
  if (scheduled.isBefore(now.add(const Duration(minutes: 1)))) {
    scheduled = scheduled.add(const Duration(days: 1));
  }

  debugPrint('[알림예약] $scheduled');

  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    '감정 기록 알림',
    '오늘 하루 감정을 기록해볼까요?',
    scheduled,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_notification_channel_id',
        'Daily Notifications',
        channelDescription: '매일 정해진 시간에 감정 기록 알림',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );

  // 예약 확인용 로그
  final pending =
      await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  for (final p in pending) {
    debugPrint('[예약됨] ID: ${p.id}, Title: ${p.title}, Body: ${p.body}');
  }
}

/// 예약된 알림 취소
Future<void> cancelNotification() async {
  await flutterLocalNotificationsPlugin.cancel(0);
  debugPrint('[알림취소] 기존 알림 취소됨');
}
