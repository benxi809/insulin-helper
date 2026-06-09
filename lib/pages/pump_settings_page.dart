/// 设置页面 — 系统设置
///
/// 参考设计图：40系统设置、39系统日志、48泵状态、49泵信息
/// 使用 SettingsListTile 组件，分组列表样式

import 'package:flutter/material.dart';
import 'package:glucare_app/theme/app_colors.dart';
import 'package:glucare_app/theme/app_spacing.dart';
import 'package:glucare_app/theme/app_typography.dart';
import 'package:glucare_app/widgets/widgets.dart';
import 'package:glucare_app/services/pump_service.dart';
import 'package:glucare_app/models/pump_models.dart';

class PumpSettingsPage extends StatelessWidget {
  const PumpSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pumpService = PumpService();
    final status = pumpService.status;

    return AppScaffold(
      title: '系统设置',
      showBack: true,
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),

          // ── 泵信息区 ──
          _buildPumpInfoCard(status),

          const SizedBox(height: AppSpacing.md),

          // ── 设备设置 ──
          _sectionHeader('设备设置'),
          const SizedBox(height: AppSpacing.xs),
          _buildSettingsGroup(context, [
            SettingsListTile(
              icon: Icons.bluetooth,
              title: '蓝牙连接',
              subtitle: '连接状态: ${status.connectionState == PumpConnectionState.connected ? "已连接" : "未连接"}',
              trailingText: status.connectionState == PumpConnectionState.connected ? '睿昇泵 #2401' : '未连接',
              onTap: () => Navigator.pushNamed(context, '/pump_connect'),
            ),
            SettingsListTile(
              icon: Icons.qr_code_scanner,
              title: '扫码配对',
              subtitle: '扫描泵身二维码快速配对',
              onTap: () => Navigator.pushNamed(context, '/pump_scan'),
            ),
            SettingsListTile(
              icon: Icons.verified_user,
              title: '链接验证',
              subtitle: '验证泵与手机的配对连接',
              onTap: () => Navigator.pushNamed(context, '/pump_verify'),
            ),
          ]),

          const SizedBox(height: AppSpacing.lg),

          // ── 治疗设置 ──
          _sectionHeader('治疗设置'),
          const SizedBox(height: AppSpacing.xs),
          _buildSettingsGroup(context, [
            SettingsListTile(
              icon: Icons.speed,
              title: '基础率设置',
              subtitle: '${pumpService.basalProfile.segments.length}个时段 · 日总量${pumpService.basalProfile.totalDailyBasal.toStringAsFixed(2)}U',
              onTap: () => Navigator.pushNamed(context, '/pump_basal'),
            ),
            SettingsListTile(
              icon: Icons.timer_outlined,
              title: '临时基础率',
              subtitle: status.tempBasalRate != null
                  ? '${status.tempBasalRate!.toStringAsFixed(2)} U/h · 剩余${status.tempBasalRemainingMinutes}分钟'
                  : '未设置',
              onTap: () => Navigator.pushNamed(context, '/pump_temp_basal'),
            ),
            SettingsListTile(
              icon: Icons.injection,
              title: '大剂量模板',
              subtitle: '快速 · 扩展 · 复合',
              onTap: () => Navigator.pushNamed(context, '/pump_bolus_templates'),
            ),
            SettingsListTile(
              icon: Icons.tune,
              title: '治疗参数',
              subtitle: '碳水化合物系数 · 胰岛素敏感系数',
              onTap: () => Navigator.pushNamed(context, '/pump_therapy_params'),
            ),
          ]),

          const SizedBox(height: AppSpacing.lg),

          // ── 系统管理 ──
          _sectionHeader('系统管理'),
          const SizedBox(height: AppSpacing.xs),
          _buildSettingsGroup(context, [
            SettingsListTile(
              icon: Icons.info_outline,
              title: '泵状态',
              subtitle: '${status.mode == PumpMode.running ? "正常运行" : status.mode.name} · 电池${status.batteryLevel}%',
              onTap: () => Navigator.pushNamed(context, '/pump_device_status'),
            ),
            SettingsListTile(
              icon: Icons.history,
              title: '系统日志',
              subtitle: '查看运行日志和事件记录',
              onTap: () => Navigator.pushNamed(context, '/pump_logs'),
            ),
            SettingsListTile(
              icon: Icons.notifications_outlined,
              title: '报警与提示',
              subtitle: '查看和管理报警信息',
              onTap: () => Navigator.pushNamed(context, '/pump_alerts'),
            ),
            SettingsListTile(
              icon: Icons.lock_outline,
              title: '屏幕解锁设置',
              subtitle: '设置解锁方式',
              onTap: () => Navigator.pushNamed(context, '/pump_unlock_settings'),
            ),
            SettingsListTile(
              icon: Icons.palette_outlined,
              title: '界面个性化',
              subtitle: '字体大小 · 主题色 · 背景',
              onTap: () => Navigator.pushNamed(context, '/pump_personalize'),
            ),
          ]),

          const SizedBox(height: AppSpacing.lg),

          // ── 个人信息 ──
          _sectionHeader('个人信息'),
          const SizedBox(height: AppSpacing.xs),
          _buildSettingsGroup(context, [
            SettingsListTile(
              icon: Icons.person,
              title: '个人信息',
              subtitle: '姓名 · 年龄 · 病史',
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            SettingsListTile(
              icon: Icons.favorite,
              title: '亲情号',
              subtitle: '设置紧急联系人',
              onTap: () => Navigator.pushNamed(context, '/pump_emergency_contacts'),
            ),
          ]),

          const SizedBox(height: AppSpacing.xl),

          // ── 版本信息 ──
          const Center(
            child: Text('睿昇胰岛素泵 v1.0.0', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ),
          const SizedBox(height: AppSpacing.sectionXl),
        ],
      ),
    );
  }

  Widget _buildPumpInfoCard(PumpStatus status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.monitor_heart, color: Colors.white, size: 32),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('睿昇胰岛素泵', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '型号: RS-2401 · SN: RS24A0001',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.6)),
          ],
        ),
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

  Widget _buildSettingsGroup(BuildContext context, List<SettingsListTile> tiles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: tiles,
        ),
      ),
    );
  }
}
