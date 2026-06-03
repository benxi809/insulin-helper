import 'package:flutter/material.dart';
import 'package:insulin_app/calculators/dose_calculator.dart';
import 'package:insulin_app/calculators/iob_tracker.dart';
import 'package:insulin_app/calculators/safety_checks.dart';
import 'package:insulin_app/database/local_db.dart';
import 'package:insulin_app/models/models.dart';

/// 计算器页 — 核心剂量计算
class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final AppDatabase _db = AppDatabase();
  final _glucoseCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();

  UserConfig _config = UserConfig();
  double _iob = 0.0;
  String _iobDetail = '无活性胰岛素';
  DoseResult? _result;
  SafetyResult? _safetyResult;
  bool _calculating = false;
  bool _hasKetones = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    _config = await _db.getConfig();
    await _calcIOB();
    if (mounted) setState(() {});
  }

  Future<void> _calcIOB() async {
    final doses = await _db.getDoses(limit: 50);
    final relevantDoses = doses
        .where((d) => d.insulinType == _config.insulinType)
        .toList();

    _iob = IOBActivityTracker.calculateIOB(
      previousDoses: relevantDoses,
      currentTime: DateTime.now(),
      durationHours: _config.iobDurationHours,
    );

    if (_iob > 0) {
      _iobDetail = '活性胰岛素 ${_iob.toStringAsFixed(1)}U';
    } else {
      _iobDetail = '无活性胰岛素';
    }
  }

  void _calculate() {
    final glucose = double.tryParse(_glucoseCtrl.text);
    final carbs = double.tryParse(_carbsCtrl.text) ?? 0;

    if (glucose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入当前血糖值')),
      );
      return;
    }

    setState(() => _calculating = true);

    // 安全检查
    final safety = SafetyChecker.fullCheck(
      glucose: glucose,
      calculatedDose: 0, // 先做预检
      maxDosePerInjection: _config.maxDosePerInjection,
      hasKetones: _hasKetones,
    );

    if (!safety.allow) {
      setState(() {
        _safetyResult = safety;
        _result = null;
        _calculating = false;
      });
      return;
    }

    // 计算剂量
    final result = DoseCalculator.calculateBolus(
      currentGlucose: glucose,
      carbs: carbs,
      config: _config,
      iob: _iob,
    );

    // 剂量后检查
    final postCheck = SafetyChecker.postCheck(
      calculatedDose: result.totalDose,
      maxDosePerInjection: _config.maxDosePerInjection,
    );

    setState(() {
      _result = result;
      _safetyResult = postCheck;
      _calculating = false;
    });
  }

  void _pickFromFoodDB() {
    Navigator.pushNamed(context, '/foods', arguments: (double carbsGrams) {
      _carbsCtrl.text = carbsGrams.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('剂量计算')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 安全检查结果条
          if (_safetyResult != null) _buildSafetyBar(),
          const SizedBox(height: 16),

          // 血糖输入
          const Text('当前血糖 (mmol/L)', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 6),
          TextField(
            controller: _glucoseCtrl,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '例: 8.5',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.blue.shade50,
            ),
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 20),

          // 碳水输入
          Row(
            children: [
              const Text('碳水摄入 (g)', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const Spacer(),
              TextButton.icon(
                onPressed: _pickFromFoodDB,
                icon: const Icon(Icons.restaurant_menu, size: 16),
                label: const Text('选食物'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _carbsCtrl,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '例: 45',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.green.shade50,
            ),
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 12),

          // IOB 显示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.timeline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(_iobDetail, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 酮体开关（高血糖时显示）
          if ((double.tryParse(_glucoseCtrl.text) ?? 0) > 13.9)
            CheckboxListTile(
              value: _hasKetones,
              onChanged: (v) => setState(() => _hasKetones = v ?? false),
              title: const Text('检测到酮体阳性（血酮/尿酮）',
                  style: TextStyle(fontSize: 13, color: Colors.red)),
              dense: true,
            ),
          const SizedBox(height: 16),

          // 计算按钮
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _calculating ? null : _calculate,
              icon: _calculating
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.calculate),
              label: Text(_calculating ? '计算中...' : '计算剂量',
                  style: const TextStyle(fontSize: 18)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 结果展示
          if (_result != null) _buildResult(),
          if (_result == null && _safetyResult != null && !_safetyResult!.allow)
            _buildDangerMessage(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSafetyBar() {
    Color bg;
    Color fg;
    IconData icon;

    switch (_safetyResult!.level) {
      case SafetyLevel.safe:
        bg = Colors.green.shade50;
        fg = Colors.green;
        icon = Icons.check_circle;
      case SafetyLevel.warning:
        bg = Colors.orange.shade50;
        fg = Colors.orange;
        icon = Icons.warning;
      case SafetyLevel.danger:
        bg = Colors.red.shade50;
        fg = Colors.red;
        icon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _safetyResult!.message ?? '',
              style: TextStyle(fontSize: 13, color: fg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    return Card(
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calculate, color: Colors.purple),
                SizedBox(width: 8),
                Text('计算过程', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            _calcRow('🥣 食物覆盖', '${r.foodDose.toStringAsFixed(1)} U'),
            _calcRow('🎯 校正剂量', '${r.correctionDose.toStringAsFixed(1)} U'),
            _calcRow('↩ 扣除 IOB', '-${r.iob.toStringAsFixed(1)} U'),
            const Divider(height: 20),
            _calcRow('✅ 推荐总量', '${r.totalDose.toStringAsFixed(1)} U', bold: true),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '公式：(血糖-目标)/ISF + 碳水/ICR - IOB\n'
                '= (${_glucoseCtrl.text}-${r.targetGlucose.toStringAsFixed(1)})/${_config.isf.toStringAsFixed(1)} '
                '+ ${_carbsCtrl.text}/${_config.icr.toStringAsFixed(0)} - ${_iob.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calcRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                fontSize: bold ? 18 : 15,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              )),
        ],
      ),
    );
  }

  Widget _buildDangerMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _safetyResult?.message ?? '',
            style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          if (_safetyResult?.action != null) ...[
            const SizedBox(height: 8),
            Text(
              _safetyResult!.action!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _glucoseCtrl.dispose();
    _carbsCtrl.dispose();
    super.dispose();
  }
}
