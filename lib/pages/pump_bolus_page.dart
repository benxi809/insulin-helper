/// 大剂量输注页面
///
/// 参考设计图：08扩展、09复合、10快速大剂量模板
/// 功能：选择剂量、选择模板、确认输注

import 'package:flutter/material.dart';
import 'package:insulin_app/services/pump_service.dart';
import 'package:insulin_app/models/pump_models.dart';
import 'package:insulin_app/theme/app_colors.dart';
import 'package:insulin_app/theme/app_spacing.dart';
import 'package:insulin_app/widgets/widgets.dart';

class BolusPage extends StatefulWidget {
  const BolusPage({super.key});

  @override
  State<BolusPage> createState() => _BolusPageState();
}

class _BolusPageState extends State<BolusPage> {
  final PumpService _pumpService = PumpService();
  double _dose = 1.0;
  BolusType _bolusType = BolusType.standard;
  bool _delivering = false;

  final List<BolusTemplate> _templates = [
    const BolusTemplate(name: '标准', type: BolusType.standard, dose: 2.0),
    const BolusTemplate(name: '餐时', type: BolusType.standard, dose: 4.0),
    const BolusTemplate(name: '校正', type: BolusType.standard, dose: 1.0),
    BolusTemplate(name: '扩展', type: BolusType.extended, dose: 3.0, extendedDurationMinutes: 120),
    BolusTemplate(name: '复合60/40', type: BolusType.combo, dose: 4.0, extendedPercentage: 0.4, extendedDurationMinutes: 120),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '大剂量输注',
      showBack: true,
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),

          // 剂量大数字
          LargeNumberDisplay(
            value: _dose.toStringAsFixed(1),
            unit: 'U',
            label: '输注剂量',
            status: GlucoseStatus.normal,
            size: DisplaySize.giant,
            customColor: AppColors.bolusDose,
            backgroundColor: AppColors.bolusDose.withValues(alpha: 0.08),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 剂量调节滑块
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                Slider(
                  value: _dose,
                  min: 0.1,
                  max: 20.0,
                  divisions: 199,
                  label: '${_dose.toStringAsFixed(1)} U',
                  activeColor: AppColors.bolusDose,
                  onChanged: (v) => setState(() => _dose = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('0.1 U', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    const Text('20 U', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 快捷键
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                _quickDoseBtn(0.5),
                const SizedBox(width: 8),
                _quickDoseBtn(1.0),
                const SizedBox(width: 8),
                _quickDoseBtn(2.0),
                const SizedBox(width: 8),
                _quickDoseBtn(5.0),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 模板选择
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('快速选择', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _templates.map((t) {
                    return ActionChip(
                      avatar: Icon(_typeIcon(t.type), size: 16, color: AppColors.bolusDose),
                      label: Text('${t.name} ${t.dose.toStringAsFixed(0)}U', style: const TextStyle(fontSize: 13)),
                      onPressed: () => setState(() => _dose = t.dose),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // 输注按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _delivering
                ? const Center(child: CircularProgressIndicator())
                : SlideConfirm(
                    label: '滑动确认输注 ${_dose.toStringAsFixed(1)}U',
                    onConfirmed: _startDelivery,
                    trackColor: AppColors.bolusDose,
                    completedColor: AppColors.success,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _quickDoseBtn(double amount) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _dose = amount),
        style: OutlinedButton.styleFrom(
          foregroundColor: _dose == amount ? AppColors.bolusDose : AppColors.textSecondary,
          side: BorderSide(color: _dose == amount ? AppColors.bolusDose : AppColors.divider),
        ),
        child: Text('${amount.toStringAsFixed(amount == 0.5 ? 1 : 0)}U', style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  IconData _typeIcon(BolusType type) {
    switch (type) {
      case BolusType.standard: return Icons.bolt;
      case BolusType.extended: return Icons.timer;
      case BolusType.combo: return Icons.blend;
    }
  }

  Future<void> _startDelivery() async {
    setState(() => _delivering = true);
    final success = await _pumpService.startBolus(_dose, type: _bolusType);
    if (mounted) {
      setState(() => _delivering = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('大剂量 ${_dose.toStringAsFixed(1)}U 输注完成'), duration: const Duration(seconds: 3)),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('输注失败，请重试'), backgroundColor: AppColors.danger),
        );
      }
    }
  }
}
