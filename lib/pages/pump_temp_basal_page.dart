/// 临时基础率设置页面
///
/// 参考设计图：24临时基础率
/// 功能：设置临时基础率（剂量+时长）

import 'package:flutter/material.dart';
import 'package:insulin_app/services/pump_service.dart';
import 'package:insulin_app/theme/app_colors.dart';
import 'package:insulin_app/theme/app_spacing.dart';
import 'package:insulin_app/widgets/widgets.dart';

class TempBasalPage extends StatefulWidget {
  const TempBasalPage({super.key});

  @override
  State<TempBasalPage> createState() => _TempBasalPageState();
}

class _TempBasalPageState extends State<TempBasalPage> {
  final PumpService _pumpService = PumpService();
  double _rate = 1.0;
  int _durationMinutes = 60;

  final List<int> _durationOptions = [30, 60, 120, 180, 240, 360, 480, 720];

  @override
  Widget build(BuildContext context) {
    final currentBasal = _pumpService.status.currentBasalRate;

    return AppScaffold(
      title: '临时基础率',
      showBack: true,
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.md),

          LargeNumberDisplay(
            value: _rate.toStringAsFixed(2),
            unit: 'U/h',
            label: '临时基础率',
            status: GlucoseStatus.high,
            size: DisplaySize.giant,
            customColor: AppColors.warning,
            backgroundColor: AppColors.warning.withValues(alpha: 0.08),
          ),

          const SizedBox(height: AppSpacing.sm),
          Text('当前基础率: ${currentBasal.toStringAsFixed(2)} U/h',
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 14)),

          const SizedBox(height: AppSpacing.lg),

          // 剂量滑块
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                Slider(
                  value: _rate,
                  min: 0.0,
                  max: 5.0,
                  divisions: 50,
                  label: '${_rate.toStringAsFixed(2)} U/h',
                  activeColor: AppColors.warning,
                  onChanged: (v) => setState(() => _rate = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('0 U/h', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    const Text('5 U/h', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 时长选择
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('持续时间', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _durationOptions.map((min) {
                    final selected = min == _durationMinutes;
                    return ChoiceChip(
                      label: Text(min >= 60 ? '${min ~/ 60}小时' : '${min}分钟', style: const TextStyle(fontSize: 13)),
                      selected: selected,
                      onSelected: (_) => setState(() => _durationMinutes = min),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // 操作按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                PrimaryButton(
                  label: '开始临时基础率',
                  icon: Icons.play_arrow,
                  onPressed: _startTempBasal,
                ),
                const SizedBox(height: AppSpacing.md),
                if (_pumpService.status.tempBasalRate != null)
                  DangerButton(
                    label: '取消临时基础率',
                    icon: Icons.stop,
                    onPressed: _cancelTempBasal,
                    outlined: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startTempBasal() async {
    await _pumpService.setTempBasal(_rate, _durationMinutes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('临时基础率已设置: ${_rate.toStringAsFixed(2)} U/h, ${_durationMinutes}分钟'),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _cancelTempBasal() async {
    await _pumpService.cancelTempBasal();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('临时基础率已取消'), duration: Duration(seconds: 2)),
      );
    }
  }
}
