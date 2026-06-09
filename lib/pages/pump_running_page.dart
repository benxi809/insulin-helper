/// 运行监控页面
///
/// 参考设计图：29运行界面、31运行状态
/// 功能：
/// - 实时运行数据面板（大数字显示当前输注状态）
/// - 当前基础率/大剂量大数字展示
/// - 控制按钮（暂停/恢复、取消大剂量）

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:glucare_app/models/pump_models.dart';
import 'package:glucare_app/services/pump_service.dart';
import 'package:glucare_app/theme/app_colors.dart';
import 'package:glucare_app/theme/app_spacing.dart';
import 'package:glucare_app/theme/app_typography.dart';
import 'package:glucare_app/widgets/widgets.dart';

class PumpRunningPage extends StatefulWidget {
  const PumpRunningPage({super.key});

  @override
  State<PumpRunningPage> createState() => _PumpRunningPageState();
}

class _PumpRunningPageState extends State<PumpRunningPage> {
  final PumpService _pumpService = PumpService();
  PumpStatus _status = PumpStatus();

  @override
  void initState() {
    super.initState();
    _status = _pumpService.status;
    _pumpService.addStatusListener(_onStatusChanged);
  }

  @override
  void dispose() {
    _pumpService.removeStatusListener(_onStatusChanged);
    super.dispose();
  }

  void _onStatusChanged(PumpStatus status) {
    if (mounted) setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    final isPaused = _status.mode == PumpMode.paused;
    final isBolusing = _status.mode == PumpMode.bolusing;
    final isTempBasal = _status.mode == PumpMode.tempBasal;

    return AppScaffold(
      title: '运行监控',
      showBack: true,
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.md),

          // ── 大数字显示区 ──
          _buildMainDisplay(isBolusing, isTempBasal),

          const SizedBox(height: AppSpacing.xxl),

          // ── 详细数据面板 ──
          _buildDetailPanel(),

          const SizedBox(height: AppSpacing.xl),

          // ── 控制按钮 ──
          _buildControlButtons(isPaused, isBolusing),
        ],
      ),
    );
  }

  /// 主大数字显示
  Widget _buildMainDisplay(bool isBolusing, bool isTempBasal) {
    String mainValue;
    String unit;
    String label;
    Color valueColor;
    GlucoseStatus gStatus;

    if (isBolusing) {
      mainValue = _status.currentBolus.toStringAsFixed(1);
      unit = 'U';
      label = '大剂量输注中';
      valueColor = AppColors.bolusDose;
      gStatus = GlucoseStatus.normal;
    } else if (isTempBasal) {
      mainValue = _status.tempBasalRate!.toStringAsFixed(2);
      unit = 'U/h';
      label = '临时基础率 剩余${_status.tempBasalRemainingMinutes}分钟';
      valueColor = AppColors.warning;
      gStatus = GlucoseStatus.high;
    } else if (isPaused) {
      mainValue = '--';
      unit = '';
      label = '输注已暂停';
      valueColor = AppColors.disabledText;
      gStatus = GlucoseStatus.none;
    } else {
      mainValue = _status.currentBasalRate.toStringAsFixed(2);
      unit = 'U/h';
      label = '当前基础率';
      valueColor = AppColors.success;
      gStatus = GlucoseStatus.normal;
    }

    return Column(
      children: [
        LargeNumberDisplay(
          value: mainValue,
          unit: unit,
          label: label,
          status: gStatus,
          size: DisplaySize.giant,
          customColor: valueColor,
          backgroundColor: valueColor.withValues(alpha: 0.08),
        ),
        const SizedBox(height: AppSpacing.md),
        // 药量和电量指示
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _miniIndicator(Icons.water_drop, '${_status.reservoirRemaining.toInt()}U',
                _status.reservoirRemaining < 20 ? AppColors.danger : AppColors.primary),
            const SizedBox(width: 24),
            _miniIndicator(Icons.battery_std, '${_status.batteryLevel}%',
                _status.batteryLevel < 20 ? AppColors.danger : AppColors.success),
            const SizedBox(width: 24),
            _miniIndicator(Icons.inventory_2, '${_status.todayTotalDelivered.toStringAsFixed(1)}U', AppColors.textSecondary),
          ],
        ),
      ],
    );
  }

  Widget _miniIndicator(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  /// 详细数据面板
  Widget _buildDetailPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: InfoCard(
        title: '运行数据',
        icon: Icons.info_outline,
        children: [
          InfoCardRow(label: '泵状态', value: _status.mode == PumpMode.running ? '正常运行' : _status.mode.name),
          InfoCardRow(label: '基础率', value: '${_status.currentBasalRate.toStringAsFixed(2)} U/h'),
          InfoCardRow(label: '剩余药量', value: '${_status.reservoirRemaining.toInt()} U',
              valueColor: _status.reservoirRemaining < 20 ? AppColors.danger : null),
          InfoCardRow(label: '电池电量', value: '${_status.batteryLevel}%',
              valueColor: _status.batteryLevel < 20 ? AppColors.danger : null),
          InfoCardRow(label: '今日总量', value: '${_status.todayTotalDelivered.toStringAsFixed(1)} U'),
          if (_status.lastDeliveryTime != null)
            InfoCardRow(label: '上次输注', value: _formatDateTime(_status.lastDeliveryTime!)),
        ],
      ),
    );
  }

  /// 控制按钮
  Widget _buildControlButtons(bool isPaused, bool isBolusing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          if (isBolusing)
            DangerButton(
              label: '取消大剂量',
              icon: Icons.close,
              onPressed: _cancelBolus,
            )
          else if (isPaused)
            PrimaryButton(
              label: '恢复输注',
              icon: Icons.play_arrow,
              onPressed: _resumePump,
            )
          else ...[
            DangerButton(
              label: '暂停输注',
              icon: Icons.pause,
              onPressed: _pausePump,
              outlined: true,
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: '设置临时基础率',
              icon: Icons.timer_outlined,
              onPressed: () => Navigator.pushNamed(context, '/pump_temp_basal'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pausePump() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('暂停输注'),
        content: const Text('确定要暂停胰岛素输注吗？暂停后基础率和大剂量输注都将停止。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          DangerButton(
            label: '确认暂停',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _pumpService.pause();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('输注已暂停'), duration: Duration(seconds: 2)),
        );
      }
    }
  }

  Future<void> _resumePump() async {
    await _pumpService.resume();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('输注已恢复'), duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _cancelBolus() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('取消大剂量'),
        content: const Text('确定要取消正在输注的大剂量吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('不取消')),
          DangerButton(
            label: '确认取消',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _pumpService.cancelBolus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('大剂量已取消'), duration: Duration(seconds: 2)),
        );
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
