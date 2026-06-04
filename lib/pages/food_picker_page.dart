import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:insulin_app/models/models.dart';

/// 已选食物条目
class _SelectedFood {
  final FoodItem food;
  double grams;
  double get carbs => (food.carbsPer100g / 100) * grams;

  _SelectedFood({required this.food, required this.grams});
}

/// 食物选择页 — 中餐碳水库 + 多选汇总 + 拍照识别入口
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

  // 多选：用 Set 记录已选食物名称（按名称去重）
  final Set<String> _selectedNames = {};
  // 已选食物的详细份量信息
  final List<_SelectedFood> _selectedFoods = [];

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
        _filtered =
            _foods.where((f) => f.containsName(query)).take(50).toList();
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

  /// 切换选择/取消食物
  void _toggleFood(FoodItem food) {
    setState(() {
      if (_selectedNames.contains(food.name)) {
        _selectedNames.remove(food.name);
        _selectedFoods.removeWhere((s) => s.food.name == food.name);
      } else {
        _selectedNames.add(food.name);
        _selectedFoods.add(_SelectedFood(food: food, grams: food.gramsPerUnit));
      }
    });
  }

  /// 修改已选食物的份量
  void _editSelectedFood(_SelectedFood selected) {
    final gramsCtrl =
        TextEditingController(text: selected.grams.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(selected.food.name,
                  style:
                      const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                '每100g含 ${selected.food.carbsPer100g.toStringAsFixed(1)}g 碳水',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('份量 = ', style: TextStyle(fontSize: 16)),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: gramsCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      ),
                    ),
                  ),
                  const Text(' 克', style: TextStyle(fontSize: 16)),
                  const Spacer(),
                  Text('/ ${selected.food.unit}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (ctx, setLocalState) {
                  final grams = double.tryParse(gramsCtrl.text) ??
                      selected.food.gramsPerUnit;
                  final carbs = (selected.food.carbsPer100g / 100) * grams;
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
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text('/ ${selected.food.unit}',
                            style:
                                const TextStyle(fontSize: 16, color: Colors.grey)),
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
                    final grams =
                        double.tryParse(gramsCtrl.text) ?? selected.food.gramsPerUnit;
                    setState(() => selected.grams = grams);
                    Navigator.pop(ctx);
                  },
                  child: const Text('确认', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 确认选择，返回总碳水量
  void _confirm() {
    final total = _selectedFoods.fold<double>(0, (sum, s) => sum + s.carbs);
    Navigator.pop(context, total);
  }

  @override
  Widget build(BuildContext context) {
    final totalCarbs = _selectedFoods.fold<double>(0, (sum, s) => sum + s.carbs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择食物'),
        actions: [
          // 拍照识别按钮
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () async {
              final result =
                  await Navigator.pushNamed(context, '/camera_food');
              if (result != null && result is double) {
                Navigator.pop(context, result);
              }
            },
            tooltip: '拍照识别',
          ),
          // 确认按钮（有选择时才显示）
          if (_selectedFoods.isNotEmpty)
            TextButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.check),
              label: Text('确认 (${totalCarbs.toStringAsFixed(0)}g)'),
            ),
        ],
      ),
      body: Column(
        children: [
          // ===== 已选食物条 =====
          if (_selectedFoods.isNotEmpty) _buildSelectedBar(),

          // ===== 搜索框 =====
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: '搜索食物名称...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // ===== 分类标签 =====
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

          // ===== 食物列表 =====
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('没有找到匹配的食物'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final food = _filtered[i];
                      final isSelected = _selectedNames.contains(food.name);
                      final carbsPerUnit =
                          (food.carbsPer100g / 100) * food.gramsPerUnit;
                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected ? Colors.green : Colors.grey,
                          size: 22,
                        ),
                        title: Text(food.name,
                            style: const TextStyle(fontSize: 15)),
                        subtitle: Text(
                          '每100g ${food.carbsPer100g.toStringAsFixed(1)}g · 1${food.unit}=${carbsPerUnit.toStringAsFixed(1)}g碳水',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: isSelected
                            ? Text(
                                '${_selectedFoods.firstWhere((s) => s.food.name == food.name, orElse: () => _SelectedFood(food: food, grams: 0)).carbs.toStringAsFixed(0)}g',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                        onTap: () => _toggleFood(food),
                        onLongPress: isSelected
                            ? () => _editSelectedFood(_selectedFoods.firstWhere(
                                (s) => s.food.name == food.name))
                            : null,
                      );
                    },
                  ),
          ),

          // ===== 底部确认栏 =====
          if (_selectedFoods.isNotEmpty)
            SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '已选 ${_selectedFoods.length} 项',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 13),
                          ),
                          Text(
                            '总碳水: ${totalCarbs.toStringAsFixed(1)} g',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _confirm,
                      icon: const Icon(Icons.check),
                      label: const Text('确认选择'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 已选食物水平滑动条
  Widget _buildSelectedBar() {
    return Container(
      width: double.infinity,
      color: Colors.green.shade50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: Text('已选食物（长按修改份量）',
                style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: _selectedFoods.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    avatar: Icon(Icons.check, size: 14, color: Colors.green),
                    label: Text(
                      '${s.food.name} ${s.carbs.toStringAsFixed(0)}g',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _editSelectedFood(s),
                    onDeleted: () => _toggleFood(s.food),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    deleteIconColor: Colors.red.shade400,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.green.shade200),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<String> get _categories {
    final cats = _foods.map((f) => f.category).toSet().toList();
    return ['全部', ...cats];
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

/// 扩展 FoodItem 支持模糊匹配
extension _FoodItemSearch on FoodItem {
  bool containsName(String query) {
    return name.toLowerCase().contains(query.toLowerCase());
  }
}
