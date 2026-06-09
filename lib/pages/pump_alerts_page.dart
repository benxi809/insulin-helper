/// 报警与提示页面
///
/// 参考设计图：02报警与提示、46药物用尽提醒（1级/2级）
/// 功能：
/// - 当前活跃报警列表
/// - 历史报警记录
/// - 分级报警显示（1级=黄色, 2级=红色）

import 'package:flutter/material.dart';
import 'package:glucare_app/services/alert_system.dart';
import 'package:glucare_app/theme/app_colors.dart';
import 'package:glucare_app/theme/app_spacing.dart';
import 'package:glucare_app/theme/app_typography.dart';
import 'package:glucare_app/widgets/widgets.dart';

class PumpAlertsPage extends StatefulWidget {
  const PumpAlertsPage({super.key});

  @override
  State<PumpAlertsPage> createState() => _PumpAlertsPageState();
}

class _PumpAlertsPageState extends State<PumpAlertsPage> {
  final AlertSystem _alertSystem = AlertSystem();

  @override
  void initState() {
    super.initState();
    _alertSystem.addListener(_onAlert);
  }

  @override
  void dispose() {
    _alertSystem.removeListener(_onAlert);
    super.dispose();
  }

  void _onAlert(AlertEvent event) {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final activeAlerts = _alertSystem.activeAlerts;
    final history = _alertSystem.alertHistory;

    return AppScaffold(
      title: '报警与提示',
      showBack: true,
      actions: [
        if (activeAlerts.isNotEmpty)
          TextButton(
            onPressed: () {
              _alertSystem.clearAll();
              setState(() {});
            },
            child: const Text('清除全部'),
          ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),

          // ── 活跃报警 ──
          if (activeAlerts.isNotEmpty) ...[
            _sectionHeader('当前报警 (${activeAlerts.length})'),
            const SizedBox(height: AppSpacing.xs),
            ...activeAlerts.map((alert) => _buildAlertCard(alert)),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── 无报警状态 ──
          if (activeAlerts.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: AppColors.success.withValues(alpha: 0.5)),
                    const SizedBox(height: AppSpacing.md),
                    const Text('当前无报警', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    const Text('系统运行正常', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── 历史记录 ──
          if (history.isNotEmpty) ...[
            _sectionHeader('历史记录'),
            const SizedBox(height: AppSpacing.xs),
            ...history.reversed.take(20).map((alert) => _buildHistoryItem(alert)),
          ],

          if (history.isEmpty && activeAlerts.isEmpty) ...[
            _sectionHeader('历史记录'),
            const SizedBox(height: 8),
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('暂无报警历史', style: TextStyle(color: AppColors.textTertiary, fontSize: 14)),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.sectionXl),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.lg + 4, bottom: 4),
      child: Text(text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          )),
    );
  }

  /// 活跃报警卡片（带严重级别色标）
  Widget _buildAlertCard(AlertEvent alert) {
    final isLevel2 = alert.severity == AlertSeverity.level2;
    final accentColor = isLevel2 ? AppColors.danger : AppColors.warning;
    final bgColor = isLevel2 ? AppColors.dangerLight : AppColors.warningLight;
    final levelText = isLevel2 ? '2级紧急' : '1级警告';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border(left: BorderSide(color: accentColor, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(levelText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    )),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(alert.message,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(alert.timestamp) + ' · ${alert.category}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: AppColors.textTertiary,
                onPressed: () {
                  _alertSystem.acknowledgeAlert(alert.id);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 历史记录项（简化）
  Widget _buildHistoryItem(AlertEvent alert) {
    final isLevel2 = alert.severity == AlertSeverity.level2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
        ),
        child: Row(
          children: [
            Icon(
              isLevel2 ? Icons.error : Icons.warning_amber_rounded,
              size: 18,
              color: isLevel2 ? AppColors.danger : AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.title, style: const TextStyle(fontSize: 14)),
                  Text(
                    _formatTime(alert.timestamp),
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Text(
              alert.acknowledged ? '已确认' : '未处理',
              style: TextStyle(
                fontSize: 12,
                color: alert.acknowledged ? AppColors.success : AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
