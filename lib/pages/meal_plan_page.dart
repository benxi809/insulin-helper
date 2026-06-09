import 'package:flutter/material.dart';
import 'package:insulin_app/utils/meal_planner.dart';
import 'package:insulin_app/utils/report_generator.dart';

/// 每周食谱推荐页面
class MealPlanPage extends StatefulWidget {
  const MealPlanPage({super.key});

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  final MealPlanner _planner = MealPlanner();
  WeeklyMealPlan? _weeklyPlan;
  bool _loading = true;
  int _selectedDay = DateTime.now().weekday; // 当前星期

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() => _loading = true);
    try {
      final plan = await _planner.generateWeeklyPlan();
      setState(() {
        _weeklyPlan = plan;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成食谱失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('推荐食谱'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlan,
            tooltip: '重新生成',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _weeklyPlan == null
              ? const Center(child: Text('暂无食谱数据'))
              : Column(
                  children: [
                    // 星期选择器
                    Container(
                      height: 72,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: 7,
                        itemBuilder: (context, index) {
                          final day = _weeklyPlan!.days[index];
                          final isSelected = _selectedDay == day.dayOfWeek;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _dayChip(day, isSelected),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),

                    // 当天食谱内容
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadPlan,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _mealSection(
                              '🌅 早餐',
                              _weeklyPlan!.days
                                  .firstWhere((d) => d.dayOfWeek == _selectedDay)
                                  .breakfast,
                              Icons.wb_sunny,
                            ),
                            _mealSection(
                              '🌤 午餐',
                              _weeklyPlan!.days
                                  .firstWhere((d) => d.dayOfWeek == _selectedDay)
                                  .lunch,
                              Icons.wb_cloudy,
                            ),
                            _mealSection(
                              '🌙 晚餐',
                              _weeklyPlan!.days
                                  .firstWhere((d) => d.dayOfWeek == _selectedDay)
                                  .dinner,
                              Icons.nights_stay,
                            ),
                            _mealSection(
                              '🍎 加餐',
                              _weeklyPlan!.days
                                  .firstWhere((d) => d.dayOfWeek == _selectedDay)
                                  .snacks,
                              Icons.apple,
                            ),

                            const SizedBox(height: 8),

                            // 营养小计
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _nutrientChip(
                                      '总碳水',
                                      '${_weeklyPlan!.days.firstWhere((d) => d.dayOfWeek == _selectedDay).totalCarbs.toStringAsFixed(0)}g',
                                      Colors.blue,
                                    ),
                                    _nutrientChip(
                                      '总热量',
                                      '${_weeklyPlan!.days.firstWhere((d) => d.dayOfWeek == _selectedDay).totalCalories.toStringAsFixed(0)}kcal',
                                      Colors.orange,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 跳转购买按钮
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Text(
                                      '网上买菜',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '选择平台跳转购买食材',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          MealPlanner.platformUrls.keys.map((name) {
                                        return ActionChip(
                                          avatar: const Icon(Icons.shopping_cart,
                                              size: 18),
                                          label: Text(name),
                                          onPressed: () {
                                            _launchPlatform(name);
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _dayChip(DailyMealPlan day, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedDay = day.dayOfWeek),
      child: Container(
        width: 52,
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.dayLabel.replaceAll('周', ''),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              '${day.totalCarbs.toStringAsFixed(0)}g',
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? Colors.white70
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealSection(String title, List<MealItem> items, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '碳水: ${items.fold<double>(0, (s, i) => s + i.carbs).toStringAsFixed(0)}g',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        item.isRecommended
                            ? Icons.check_circle
                            : Icons.info_outline,
                        size: 16,
                        color: item.isRecommended ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.name)),
                      Text(
                        '${item.carbs.toStringAsFixed(0)}g',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _nutrientChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  void _launchPlatform(String name) {
    // 跳转到对应 App
    final url = MealPlanner.platformUrls[name] ?? '';
    if (url.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('正在打开 $name...'),
          action: SnackBarAction(
            label: '跳转',
            onPressed: () {
              // 使用 launchUrl 需要添加 url_launcher 依赖
              // 这里先用剪贴板提示
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请手动打开对应App购买')),
              );
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name 暂不支持跳转')),
      );
    }
  }
}

/// 采购清单页面
class ShoppingListPage extends StatelessWidget {
  final WeeklyMealPlan plan;

  const ShoppingListPage({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final planner = MealPlanner();
    final list = plan.fullShoppingList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('采购清单'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: '复制清单',
            onPressed: () {
              final text = planner.generateShoppingListText(plan);
              // Clipboard.setData 需要 import
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请长按内容复制')),
              );
              // 直接显示可复制的 SnackBar
              showModalBottomSheet(
                context: context,
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '采购清单',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        text,
                        style: const TextStyle(fontSize: 14, height: 1.6),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '长按上方文字选择复制，粘贴到买菜App',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '🛒 本周采购清单',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            '根据本周食谱自动生成',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          ...list.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...entry.value.map((name) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.check_box_outline_blank,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(name),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // 跳转买菜
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    '网上买菜',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '选择平台跳转购买食材，无需手动输入',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MealPlanner.platformUrls.keys.map((name) {
                      return ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('正在打开 $name...')),
                          );
                        },
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: Text(name),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
