import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

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

    const details = NotificationDetails(
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
}
