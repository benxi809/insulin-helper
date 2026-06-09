/// 治疗参数设置页面
///
/// 参考设计图：30治疗参数设置、24临时基础率、34/35碳水化合物系数
/// 功能：
/// - 参数卡片列表（碳水化合物系数、胰岛素敏感系数、目标血糖范围等）
/// - 编辑功能（点击数值可编辑）

import 'package:flutter/material.dart';
import 'package:insulin_app/database/local_db.dart';
import 'package:insulin_app/models/models.dart';
import 'package:insulin_app/theme/app_colors.dart';
import 'package:insulin_app/theme/app_spacing.dart';
import 'package:insulin_app/theme/app_typography.dart';
import 'package:insulin_app/widgets/widgets.dart';

class TherapyParamsPage extends StatefulWidget {
  const TherapyParamsPage({super.key});

  @override
  State<TherapyParamsPage> createState() => _TherapyParamsPageState();
}

class _TherapyParamsPageState extends State<TherapyParamsPage> {
  final AppDatabase _db = AppDatabase();
  UserConfig _config = UserConfig();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    _config = await _db.getConfig();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveConfig() async {
    await _db.updateConfig(_config);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('参数已保存'), duration: Duration(seconds: 2)),
      );
    }
  }

  void _editValue(String label, double currentValue, Function(double) onSave) {
    final ctrl = TextEditingController(text: currentValue.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('设置 $label'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null && val > 0) {
                onSave(val);
                _saveConfig();
              }
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return AppScaffold(
      title: '治疗参数',
      showBack: true,
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),

          // ── 碳水化合物系数 ──
          DataCard(
            title: '碳水化合物系数 (ICR)',
            value: _config.icr.toStringAsFixed(1),
            unit: 'g/U',
            icon: Icons.grain,
            subtitle: '每1U胰岛素覆盖的碳水克数',
            footer: '建议范围: 8-15 g/U (速效胰岛素)',
            onEdit: () => _editValue('ICR', _config.icr, (v) => setState(() => _config.icr = v)),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── 胰岛素敏感系数 ──
          DataCard(
            title: '胰岛素敏感系数 (ISF)',
            value: _config.isf.toStringAsFixed(2),
            unit: 'mmol/L/U',
            icon: Icons.speed,
            subtitle: '每1U胰岛素降低的血糖值',
            footer: '建议范围: 1.5-3.0 mmol/L/U',
            status: DataStatus.normal,
            onEdit: () => _editValue('ISF', _config.isf, (v) => setState(() => _config.isf = v)),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── 目标血糖范围 ──
          _buildTargetRangeCard(),
          const SizedBox(height: AppSpacing.md),

          // ── 胰岛素类型 ──
          DataCard(
            title: '胰岛素类型',
            value: _config.insulinType == InsulinType.rapidActing ? '速效' : '短效',
            icon: Icons.biotech,
            subtitle: _config.insulinType.displayName,
            footer: '活性时长: ${_config.iobDurationHours}小时',
            onTap: () => _selectInsulinType(),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── 胰岛素活性时长 ──
          DataCard(
            title: '胰岛素活性时长',
            value: '${_config.iobDurationHours}',
            unit: '小时',
            icon: Icons.timer,
            subtitle: '胰岛素在体内起效持续时间',
            onEdit: () => _editValue('活性时长', _config.iobDurationHours.toDouble(),
                (v) => setState(() => _config.iobDurationHours = v.round())),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── 单次最大剂量 ──
          DataCard(
            title: '单次最大剂量',
            value: _config.maxDosePerInjection.toStringAsFixed(1),
            unit: 'U',
            icon: Icons.warning_amber,
            subtitle: '单次大剂量上限',
            status: DataStatus.warning,
            onEdit: () => _editValue('最大剂量', _config.maxDosePerInjection,
                (v) => setState(() => _config.maxDosePerInjection = v)),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildTargetRangeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: const Border(left: BorderSide(color: AppColors.success, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, size: 18, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              const Text('目标血糖范围',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              const Spacer(),
              GestureDetector(
                onTap: _editTargetRange,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _config.targetGlucoseMin.toStringAsFixed(1),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.success, height: 1.0),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(' mmol/L', style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('—', style: TextStyle(fontSize: 20, color: AppColors.textTertiary)),
              ),
              Text(
                _config.targetGlucoseMax.toStringAsFixed(1),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.success, height: 1.0),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(' mmol/L', style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text('正常血糖范围', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  void _editTargetRange() {
    final minCtrl = TextEditingController(text: _config.targetGlucoseMin.toStringAsFixed(1));
    final maxCtrl = TextEditingController(text: _config.targetGlucoseMax.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('目标血糖范围'),
        content: Row(
          children: [
            Expanded(child: TextField(controller: minCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '下限'))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('—')),
            Expanded(child: TextField(controller: maxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '上限'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final min = double.tryParse(minCtrl.text);
              final max = double.tryParse(maxCtrl.text);
              if (min != null && max != null && min < max) {
                setState(() {
                  _config.targetGlucoseMin = min;
                  _config.targetGlucoseMax = max;
                });
                _saveConfig();
              }
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _selectInsulinType() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择胰岛素类型'),
        children: InsulinType.values.map((type) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _config.insulinType = type);
              _config.iobDurationHours = type.activeDurationHours;
              _saveConfig();
              Navigator.pop(ctx);
            },
            child: Text(type.displayName),
          );
        }).toList(),
      ),
    );
  }
}
