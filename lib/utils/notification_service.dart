import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:convert';

/// 本地通知服务 — 血糖测量提醒
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// 初始化通知插件
  Future<void> init() async {
    if (_initialized) return;

    // 初始化时区数据
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// 请求通知权限（Android 13+ 需要）
  Future<void> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  /// 取消所有提醒
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// 取消指定 ID 的提醒
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  /// 预约每日定时通知
  /// [id] 唯一通知ID
  /// [hour] 小时 (0-23)
  /// [minute] 分钟 (0-59)
  /// [title] 通知标题
  /// [body] 通知内容
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    final location = tz.local;

    // 构建目标时间（今天）
    var scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 如果时间已过，推到明天
    if (scheduledDate.isBefore(DateTime.now())) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // 每周重复
    final androidDetails = AndroidNotificationDetails(
      'glucose_reminder',
      '血糖测量提醒',
      channelDescription: '提醒您按时测量血糖',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 根据用户配置设置所有血糖提醒
  Future<void> setupReminders({
    required bool breakfast,
    required bool lunch,
    required bool dinner,
    required bool bedtime,
  }) async {
    // 取消所有旧提醒
    await cancelAll();

    // 早餐前 7:00
    if (breakfast) {
      await scheduleDaily(
        id: 101,
        hour: 7,
        minute: 0,
        title: '🩸 测量血糖',
        body: '早餐前该测血糖了！',
      );
    }

    // 午餐前 11:30
    if (lunch) {
      await scheduleDaily(
        id: 102,
        hour: 11,
        minute: 30,
        title: '🩸 测量血糖',
        body: '午餐前该测血糖了！',
      );
    }

    // 晚餐前 17:30
    if (dinner) {
      await scheduleDaily(
        id: 103,
        hour: 17,
        minute: 30,
        title: '🩸 测量血糖',
        body: '晚餐前该测血糖了！',
      );
    }

    // 睡前 21:00
    if (bedtime) {
      await scheduleDaily(
        id: 104,
        hour: 21,
        minute: 0,
        title: '🩸 测量血糖',
        body: '睡前该测血糖了！',
      );
    }
  }

  // ========== 用药提醒 ==========

  /// 用药提醒频道ID
  static const String _medicationChannelId = 'medication_reminder';

  /// 用药提醒通知ID起始值（1000+ 防止与血糖提醒冲突）
  static const int _medicationIdBase = 1000;

  /// 为单个药品的某个时间点设置每日用药提醒
  Future<void> scheduleMedicationReminder({
    required int medicationId,
    required int reminderIndex,
    required int hour,
    required int minute,
    required String medicineName,
    required String doseText,
  }) async {
    final now = DateTime.now();
    final location = tz.local;

    var scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 如果时间已过，推到明天
    if (scheduledDate.isBefore(DateTime.now())) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      _medicationChannelId,
      '用药提醒',
      channelDescription: '提醒您按时用药',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = _medicationIdBase + medicationId * 10 + reminderIndex;

    await _plugin.zonedSchedule(
      notificationId,
      '💊 该用药了：$medicineName',
      '剂量：$doseText',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 根据所有生效的药品方案，批量设置用药提醒
  /// [medications] 药品列表（仅传入 isActive=true 的即可）
  /// 注意：会取消旧的药品相关提醒（ID 1000-9999）
  Future<void> setupAllMedicationReminders(List<Map<String, dynamic>> medications) async {
    // 先取消所有旧的用药提醒
    for (int i = 0; i < 9000; i++) {
      await _plugin.cancel(_medicationIdBase + i);
    }

    for (final med in medications) {
      final id = med['id'] as int;
      final name = med['name'] as String? ?? '';
      final dose = (med['dose'] as num?)?.toDouble() ?? 0;
      final unit = med['unit'] as String? ?? 'U';
      final doseTimesJson = med['doseTimesJson'] as String? ?? '[]';
      final doseText = '$dose$unit';

      // 解析时间点
      final List<dynamic> times;
      try {
        times = const JsonDecoder().convert(doseTimesJson) as List<dynamic>;
      } catch (_) {
        continue;
      }

      for (int i = 0; i < times.length; i++) {
        final timeStr = times[i] as String;
        final parts = timeStr.split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;

        await scheduleMedicationReminder(
          medicationId: id,
          reminderIndex: i,
          hour: hour,
          minute: minute,
          medicineName: name,
          doseText: doseText,
        );
      }
    }
  }
}
