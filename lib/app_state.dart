import 'package:flutter/material.dart';
import 'package:glucare_app/utils/food_database.dart';
import 'package:glucare_app/database/local_db.dart';
import 'package:glucare_app/utils/notification_service.dart';

/// 全局 app 状态
class AppState extends ChangeNotifier {
  final AppDatabase db = AppDatabase();
  final FoodDatabase foodDb = FoodDatabase();
  final NotificationService notificationService = NotificationService();
  bool _initialized = false;

  bool get initialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    // 加载食物数据（最快）
    await foodDb.load();

    // 初始化数据库（触发迁移）
    await db.database;

    // 自动创建今日用药打卡记录
    await db.ensureTodayLogs();

    // 标记初始化完成，先显示主界面
    _initialized = true;
    notifyListeners();

    // 用药提醒等后台任务延迟执行，不阻塞启动
    _scheduleMedicationReminders();
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
