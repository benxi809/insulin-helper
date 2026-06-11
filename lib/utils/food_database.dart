import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:glucare_app/models/models.dart';

/// 中餐碳水库服务
/// 从本地 JSON 加载食物数据，提供搜索和份量调整功能
class FoodDatabase {
  final List<FoodItem> _foods = [];
  bool _loaded = false;

  /// 加载食物数据（从 assets/foods.json）
  Future<void> load() async {
    if (_loaded) return;
    final jsonStr = await rootBundle.loadString('assets/foods.json');
    final List<dynamic> jsonList = json.decode(jsonStr);
    for (final item in jsonList) {
      _foods.add(FoodItem.fromJson(item));
    }
    _loaded = true;
  }

  /// 获取所有食物
  List<FoodItem> get all => List.unmodifiable(_foods);

  /// 获取所有分类
  List<String> get categories {
    return _foods.map((f) => f.category).toSet().toList();
  }

  /// 按分类筛选
  List<FoodItem> getByCategory(String category) {
    return _foods.where((f) => f.category == category).toList();
  }

  /// 搜索食物（按名称模糊匹配）
  List<FoodItem> search(String query) {
    if (query.isEmpty) return all;
    final lower = query.toLowerCase();
    return _foods
        .where((f) => f.name.toLowerCase().contains(lower))
        .toList();
  }

  /// 按名称精确查找
  FoodItem? findByName(String name) {
    try {
      return _foods.firstWhere((f) => f.name == name);
    } catch (_) {
      return null;
    }
  }

  /// 更新某个食物的份量基准
  void updatePortion(String name, double newGramsPerUnit) {
    final index = _foods.indexWhere((f) => f.name == name);
    if (index >= 0) {
      _foods[index] = FoodItem(
        name: _foods[index].name,
        carbsPer100g: _foods[index].carbsPer100g,
        unit: _foods[index].unit,
        gramsPerUnit: newGramsPerUnit,
        category: _foods[index].category,
      );
    }
  }

  /// 添加自定义食物
  void addCustomFood(FoodItem food) {
    _foods.add(food);
  }

  /// 获取食物总数
  int get count => _foods.length;
}
