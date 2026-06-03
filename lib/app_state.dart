import 'package:flutter/material.dart';
import 'package:insulin_app/utils/food_database.dart';
import 'package:insulin_app/database/local_db.dart';

/// 全局 app 状态
class AppState extends ChangeNotifier {
  final AppDatabase db = AppDatabase();
  final FoodDatabase foodDb = FoodDatabase();
  bool _initialized = false;

  bool get initialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    await foodDb.load();
    _initialized = true;
    notifyListeners();
  }
}
