import 'package:flutter/material.dart';
import 'package:insulin_app/utils/food_database.dart';
import 'package:insulin_app/database/local_db.dart';
import 'package:insulin_app/utils/notification_service.dart';

/// 全局 app 状态
class AppState extends ChangeNotifier {
  final AppDatabase db = AppDatabase();
  final FoodDatabase foodDb = FoodDatabase();
  bool _initialized = false;

  bool get initialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    await foodDb.load();
    // 初始化数据库（触发迁移）
    final database = await db.database;
    // 自动创建今日用药打卡记录
    await db.ensureTodayLogs();
    // 设置用药提醒
    try {
      final medications = await db.getMedications(activeOnly: true);
      if (medications.isNotEmpty) {
        final notif = NotificationService();
        await notif.setupAllMedicationReminders(
          medications.map((m) => m.toMap()).toList(),
        );
      }
    } catch (_) {
      // 忽略提醒设置错误
    }
    _initialized = true;
    notifyListeners();
  }
}
