import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:insulin_app/models/models.dart';

/// 食物选择页 — 中餐碳水库 + 拍照识别入口
class FoodPickerPage extends StatefulWidget {
  final double? initialCarbs;
  const FoodPickerPage({super.key, this.initialCarbs});

  @override
  State<FoodPickerPage> createState() => _FoodPickerPageState();
}

class _FoodPickerPageState extends State<FoodPickerPage> {
  List<FoodItem> _foods = [];
  List<FoodItem> _filtered = [];
  String _selectedCategory = '全部';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    final jsonStr = await rootBundle.loadString('assets/foods.json');
    final List<dynamic> list = json.decode(jsonStr);
    _foods = list.map((j) => FoodItem.fromJson(j)).toList();
    _filtered = List.from(_foods);
    setState(() {});
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _selectedCategory == '全部'
            ? List.from(_foods)
            : _foods.where((f) => f.category == _selectedCategory).toList();
      } else {
        _filtered = _foods
            .where((f) => f.name.contains(query))
            .take(50)
            .toList();
      }
    });
  }

  void _selectCategory(String cat) {
    setState(() {
      _selectedCategory = cat;
      _searchCtrl.clear();
      _filtered = cat == '全部'
          ? List.from(_foods)
          : _foods.where((f) => f.category == cat).toList();
    });
  }

  void _showPortionEditor(FoodItem food) {
    final gramsCtrl = TextEditingController(text: food.gramsPerUnit.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(food.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '每100g含 ${food.carbsPer100g.toStringAsFixed(1)}g 碳水',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('1份 = ', style: TextStyle(fontSize: 16)),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: gramsCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    ),
                  ),
                ),
                const Text(' 克', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Text('/ ${food.unit}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (ctx, setLocalState) {
                final grams = double.tryParse(gramsCtrl.text) ?? food.gramsPerUnit;
                final carbs = (food.carbsPer100g / 100) * grams;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text('碳水:', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text('${carbs.toStringAsFixed(1)} g',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('/ ${food.unit}', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  final grams = double.tryParse(gramsCtrl.text) ?? food.gramsPerUnit;
                  final carbs = (food.carbsPer100g / 100) * grams;
                  Navigator.pop(ctx);
                  Navigator.pop(context, carbs);
                },
                child: const Text('确认选择', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> get _categories {
    final cats = _foods.map((f) => f.category).toSet().toList();
    return ['全部', ...cats];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择食物'),
        actions: [
          // 拍照识别按钮
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/camera_food');
              if (result != null && result is double) {
                Navigator.pop(context, result);
              }
            },
            tooltip: '拍照识别',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: '搜索食物名称...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          // 分类标签
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _categories.map((cat) {
                final selected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat, style: const TextStyle(fontSize: 13)),
                    selected: selected,
                    onSelected: (_) => _selectCategory(cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          // 食物列表
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('没有找到匹配的食物'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final food = _filtered[i];
                      final carbs = (food.carbsPer100g / 100) * food.gramsPerUnit;
                      return ListTile(
                        title: Text(food.name, style: const TextStyle(fontSize: 15)),
                        subtitle: Text(
                          '每100g ${food.carbsPer100g.toStringAsFixed(1)}g · 1${food.unit}=${carbs.toStringAsFixed(1)}g碳水',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () => _showPortionEditor(food),
                      );
                    },
                  ),
          ),

          // 底部拍照快捷按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.pushNamed(context, '/camera_food');
                    if (result != null && result is double) {
                      Navigator.pop(context, result);
                    }
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('📸 拍照识别食物'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
