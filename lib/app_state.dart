import 'package:flutter/material.dart';
import 'package:glucare_app/utils/food_database.dart';
import 'package:glucare_app/database/local_db.dart';
import 'package:glucare_app/utils/notification_service.dart';

/// 全局 app 状态（单例）
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final AppDatabase db = AppDatabase();
  final FoodDatabase foodDb = FoodDatabase();
  final NotificationService notificationService = NotificationService();
  bool _initialized = false;

  bool get initialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    try {
      // 并行加载：食物数据 + 数据库初始化 + 启动画面最短展示时间
      await Future.wait([
        foodDb.load(),
        db.database.then((_) => db.ensureTodayLogs()),
        Future.delayed(const Duration(milliseconds: 2000)), // 至少2秒启动画面
      ]);

      // 标记初始化完成
      _initialized = true;
      notifyListeners();

      // 用药提醒等后台任务延迟执行，不阻塞启动
      _scheduleMedicationReminders();
    } catch (e) {
      debugPrint('AppState.init error: $e');
      // 即使初始化失败，也至少确保启动画面展示一段时间
      await Future.delayed(const Duration(milliseconds: 1000));
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> _scheduleMedicationReminders() async {
    try {
      final medications = await db.getMedications(activeOnly: true);
      if (medications.isNotEmpty) {
        await notificationService.setupAllMedicationReminders(
          medications.cast<Map<String, dynamic>>().toList(),
        );
      }
    } catch (_) {
      // 忽略提醒设置错误
    }
  }
}
