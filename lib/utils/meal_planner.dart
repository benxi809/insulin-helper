import 'dart:math';
import 'package:insulin_app/database/local_db.dart';

/// 餐型标签
enum MealType { breakfast, lunch, dinner, snack }

/// 食谱条目
class MealItem {
  final String name;
  final double carbs; // 估算碳水(g)
  final double calories; // 估算热量(kcal)
  final MealType type;
  final String category; // "主食"、"蛋白质"、"蔬菜"等
  final bool isRecommended; // 是否适合当前血糖状况

  MealItem({
    required this.name,
    required this.carbs,
    required this.calories,
    required this.type,
    this.category = '其他',
    this.isRecommended = true,
  });
}

/// 每日食谱
class DailyMealPlan {
  final int dayOfWeek; // 1=周一, 7=周日
  final List<MealItem> breakfast;
  final List<MealItem> lunch;
  final List<MealItem> dinner;
  final List<MealItem> snacks;

  DailyMealPlan({
    required this.dayOfWeek,
    this.breakfast = const [],
    this.lunch = const [],
    this.dinner = const [],
    this.snacks = const [],
  });

  String get dayLabel {
    const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return days[(dayOfWeek - 1) % 7];
  }

  /// 当天总碳水
  double get totalCarbs {
    double sum = 0;
    for (final items in [breakfast, lunch, dinner, snacks]) {
      for (final item in items) {
        sum += item.carbs;
      }
    }
    return sum;
  }

  /// 当天总热量
  double get totalCalories {
    double sum = 0;
    for (final items in [breakfast, lunch, dinner, snacks]) {
      for (final item in items) {
        sum += item.calories;
      }
    }
    return sum;
  }

  /// 采购清单（去重）
  Map<String, Set<String>> get shoppingList {
    final list = <String, Set<String>>{};
    for (final items in [breakfast, lunch, dinner, snacks]) {
      for (final item in items) {
        list.putIfAbsent(item.category, () => {}).add(item.name);
      }
    }
    return list;
  }
}

/// 一周食谱建议
class WeeklyMealPlan {
  final List<DailyMealPlan> days;

  WeeklyMealPlan({required this.days});

  /// 全部采购清单
  Map<String, Set<String>> get fullShoppingList {
    final combined = <String, Set<String>>{};
    for (final day in days) {
      for (final entry in day.shoppingList.entries) {
        combined.putIfAbsent(entry.key, () => {}).addAll(entry.value);
      }
    }
    return combined;
  }
}

/// 食谱推荐引擎
class MealPlanner {
  final AppDatabase _db = AppDatabase();
  final Random _random = Random();

  /// 基础食材库（按类别）
  static const _foodDatabase = {
    '主食': [
      ('全麦面包2片', 30, 140),
      ('燕麦粥(碗)', 40, 180),
      ('糙米饭(碗)', 45, 200),
      ('荞麦面(碗)', 40, 180),
      ('蒸红薯(中等)', 35, 150),
      ('玉米(根)', 30, 130),
      ('杂粮馒头(个)', 35, 160),
      ('藜麦沙拉(份)', 35, 200),
      ('全麦意面(份)', 40, 190),
    ],
    '蛋白质': [
      ('水煮蛋(2个)', 2, 140),
      ('鸡胸肉(100g)', 0, 165),
      ('三文鱼(100g)', 0, 208),
      ('豆腐(200g)', 8, 144),
      ('瘦牛肉(100g)', 0, 250),
      ('虾仁(100g)', 0, 99),
      ('希腊酸奶(杯)', 10, 100),
      ('豆干(100g)', 6, 140),
    ],
    '蔬菜': [
      ('西兰花(150g)', 8, 52),
      ('菠菜(份)', 4, 28),
      ('番茄沙拉(份)', 10, 40),
      ('黄瓜(根)', 4, 16),
      ('生菜沙拉(份)', 5, 25),
      ('炒青菜(份)', 6, 35),
      ('蘑菇(100g)', 3, 22),
      ('彩椒沙拉(份)', 8, 35),
    ],
    '水果': [
      ('苹果(个)', 25, 95),
      ('蓝莓(把)', 12, 45),
      ('草莓(5颗)', 10, 35),
      ('柚子(瓣)', 15, 55),
      ('猕猴桃(个)', 15, 60),
      ('樱桃(10颗)', 12, 50),
    ],
    '饮品': [
      ('无糖豆浆(杯)', 4, 40),
      ('纯牛奶(杯)', 10, 120),
      ('黑咖啡(杯)', 0, 5),
      ('绿茶(杯)', 0, 0),
    ],
    '加餐': [
      ('坚果(30g)', 8, 180),
      ('无糖酸奶(杯)', 8, 80),
      ('全麦饼干(2片)', 15, 90),
      ('低脂奶酪(片)', 2, 60),
      ('黑巧克力(15g)', 5, 75),
    ],
  };

  /// 根据用户情况生成一周食谱
  Future<WeeklyMealPlan> generateWeeklyPlan() async {
    final config = await _db.getConfig();
    final now = DateTime.now();

    // 获取近期血糖数据以调整食谱
    final recentGlucose = await _db.getGlucoseRecords(
      startDate: now.subtract(const Duration(days: 7)),
      endDate: now,
    );

    // 判断血糖趋势
    final avgGlucose = recentGlucose.isEmpty
        ? (config.targetGlucoseMin + config.targetGlucoseMax) / 2
        : recentGlucose.map((r) => r.glucose).reduce((a, b) => a + b) /
            recentGlucose.length;

    final isHigh = avgGlucose > config.targetGlucoseMax;
    final isLow = avgGlucose < config.targetGlucoseMin;

    final days = <DailyMealPlan>[];
    for (int i = 0; i < 7; i++) {
      days.add(_generateDay(i + 1, isHigh, isLow));
    }

    return WeeklyMealPlan(days: days);
  }

  DailyMealPlan _generateDay(int dayOfWeek, bool isHigh, bool isLow) {
    return DailyMealPlan(
      dayOfWeek: dayOfWeek,
      breakfast: _generateMeal(MealType.breakfast, isHigh, isLow),
      lunch: _generateMeal(MealType.lunch, isHigh, isLow),
      dinner: _generateMeal(MealType.dinner, isHigh, isLow),
      snacks: _generateMeal(MealType.snack, isHigh, isLow),
    );
  }

  List<MealItem> _generateMeal(MealType type, bool isHigh, bool isLow) {
    final items = <MealItem>[];
    final carbLimit = _getCarbLimit(type, isHigh, isLow);

    switch (type) {
      case MealType.breakfast:
        items.add(_pickFood('主食', 1, carbLimit));
        items.add(_pickFood('蛋白质', 1, 100));
        items.add(_pickFood('饮品', 1, 50));
        break;
      case MealType.lunch:
        items.add(_pickFood('主食', 1, carbLimit));
        items.add(_pickFood('蛋白质', 1, 100));
        items.add(_pickFood('蔬菜', 2, 50));
        break;
      case MealType.dinner:
        items.add(_pickFood('主食', 1, carbLimit * 0.8));
        items.add(_pickFood('蛋白质', 1, 100));
        items.add(_pickFood('蔬菜', 2, 50));
        break;
      case MealType.snack:
        items.add(_pickFood('水果', 1, 50));
        items.add(_pickFood('加餐', 1, 50));
        break;
    }

    return items;
  }

  double _getCarbLimit(MealType type, bool isHigh, bool isLow) {
    // 高血糖时减少碳水，低血糖时增加碳水
    final factor = isHigh ? 0.7 : (isLow ? 1.3 : 1.0);
    switch (type) {
      case MealType.breakfast:
        return 40 * factor;
      case MealType.lunch:
        return 55 * factor;
      case MealType.dinner:
        return 45 * factor;
      case MealType.snack:
        return 20 * factor;
    }
  }

  MealItem _pickFood(String category, int count, double maxCarbs) {
    final foods = _foodDatabase[category] ?? [];
    if (foods.isEmpty) {
      return MealItem(
        name: '${category}（待补充）',
        carbs: 0,
        calories: 0,
        type: MealType.snack,
        category: category,
      );
    }
    // 随机选择
    final idx = _random.nextInt(foods.length);
    final food = foods[idx];
    return MealItem(
      name: food.$1,
      carbs: food.$2.toDouble(),
      calories: food.$3.toDouble(),
      type: MealType.breakfast,
      category: category,
      isRecommended: food.$2 <= maxCarbs,
    );
  }

  // ========== 采购清单相关 ==========

  /// 生成采购清单一周列表
  String generateShoppingListText(WeeklyMealPlan plan) {
    final buffer = StringBuffer();
    final now = DateTime.now();

    // 找本周五
    final daysUntilFriday = (DateTime.friday - now.weekday + 7) % 7;
    final friday = now.add(Duration(days: daysUntilFriday));

    buffer.writeln('🛒 本周采购清单');
    buffer.writeln('📅 ${friday.month}月${friday.day}日 (周五)');
    buffer.writeln('━━━━━━━━━━━━━━━━');

    final list = plan.fullShoppingList;
    for (final entry in list.entries) {
      buffer.writeln('');
      buffer.writeln('【${entry.key}】');
      for (final name in entry.value) {
        buffer.writeln('  □ $name');
      }
    }

    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln('💡 提示：请根据实际家庭人数调整采购量');

    return buffer.toString();
  }

  /// 平台跳转映射（后续可通过设置扩展）
  static const Map<String, String> platformUrls = {
    '美团买菜': 'mtw://',
    '盒马': 'hema://',
    '叮咚买菜': 'dd://',
    '饿了么': 'eleme://',
  };

  /// 获取当日应跳转的 App 信息（根据食谱中的食材构建搜索关键词）
  Map<String, String> getDayShoppingSuggestions(DailyMealPlan day) {
    final ingredients = <String>{};
    for (final items in [day.breakfast, day.lunch, day.dinner, day.snacks]) {
      for (final item in items) {
        // 从食谱名提取核心食材
        final name = item.name;
        if (name.contains('蛋')) ingredients.add('鸡蛋');
        if (name.contains('肉') || name.contains('鸡') || name.contains('牛')) {
          ingredients.add(name.replaceAll(RegExp(r'\(.*\)'), '').trim());
        }
        if (name.contains('蔬菜') || name.contains('青菜') || name.contains('西兰花')) {
          ingredients.add(name.replaceAll(RegExp(r'\(.*\)'), '').trim());
        }
        if (name.contains('水果') || name.contains('苹果') || name.contains('蓝莓')) {
          ingredients.add(name.replaceAll(RegExp(r'\(.*\)'), '').trim());
        }
      }
    }
    return {'食材': ingredients.join(' ')};
  }
}
