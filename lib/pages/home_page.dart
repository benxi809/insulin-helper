/// 主页面 — 胰岛素泵控制桌面
///
/// 参考设计图：43主桌面、主界面_1、主界面2
/// 功能：
/// - 顶部状态区（当前血糖/基础率/药量/电量）
/// - 快捷操作卡片（大剂量、临时基础率、暂停等）
/// - 信息概览面板（今日输注、血糖趋势等）

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:insulin_app/models/models.dart';
import 'package:insulin_app/services/alert_system.dart';
import 'package:insulin_app/database/local_db.dart';
import 'package:insulin_app/theme/app_colors.dart';
import 'package:insulin_app/theme/app_spacing.dart';
import 'package:insulin_app/theme/app_typography.dart';
import 'package:insulin_app/widgets/widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PumpService _pumpService = PumpService();
  final AlertSystem _alertSystem = AlertSystem();
  final AppDatabase _db = AppDatabase();

  PumpStatus _pumpStatus = PumpStatus();
  UserConfig _config = UserConfig();
  List<GlucoseRecord> _recentGlucose = [];
  bool _loading = true;
  StreamSubscription<PumpStatus>? _statusSub;

  @override
  void initState() {
    super.initState();
    _loadData();
    _pumpService.addStatusListener(_onPumpStatusChanged);
  }

  @override
  void dispose() {
    _pumpService.removeStatusListener(_onPumpStatusChanged);
    _statusSub?.cancel();
    super.dispose();
  }

  void _onPumpStatusChanged(PumpStatus status) {
    if (mounted) setState(() => _pumpStatus = status);
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    _pumpStatus = _pumpService.status;
    _config = await _db.getConfig();
    _recentGlucose = await _db.getGlucoseRecords(limit: 5);
    if (mounted) setState(() => _loading = false);
  }

  Color _glucoseColor(double g) {
    if (g < 3.9) return AppColors.danger;
    if (g < 5.0) return AppColors.warning;
    if (g <= 7.2) return AppColors.success;
    if (g <= 10.0) return AppColors.warning;
    return AppColors.danger;
  }

  /// 获取最近的血糖值
  double? get _latestGlucose =>
      _recentGlucose.isNotEmpty ? _recentGlucose.first.glucose : null;

  /// 泵连接状态文字
  String get _connectionText {
    switch (_pumpStatus.connectionState) {
      case PumpConnectionState.connected:
        return '已连接';
      case PumpConnectionState.connecting:
        return '连接中...';
      case PumpConnectionState.disconnected:
        return '未连接';
      case PumpConnectionState.pairing:
        return '配对中...';
      case PumpConnectionState.verifying:
        return '验证中...';
    }
  }

  Color get _connectionColor {
    switch (_pumpStatus.connectionState) {
      case PumpConnectionState.connected:
        return AppColors.success;
      case PumpConnectionState.connecting:
        return AppColors.warning;
      case PumpConnectionState.disconnected:
        return AppColors.disabledText;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('睿昇胰岛素泵'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/pump_alerts'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/pump_settings'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // ── 顶部状态区 ──
                  _buildStatusHeader(),
                  const SizedBox(height: AppSpacing.md),

                  // ── 快捷操作卡片 ──
                  _buildQuickActions(),
                  const SizedBox(height: AppSpacing.md),

                  // ── 信息概览面板 ──
                  _buildInfoPanel(),
                  const SizedBox(height: AppSpacing.md),

                  // ── 今日输注统计 ──
                  _buildDeliverySummary(),
                  const SizedBox(height: AppSpacing.md),

                  // ── 最近血糖记录 ──
                  if (_recentGlucose.isNotEmpty) ..._buildGlucoseSection(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  /// 顶部状态区 — 血糖 + 泵运行状态
  Widget _buildStatusHeader() {
    final latestGlucose = _latestGlucose;
    final glucoseStr = latestGlucose?.toStringAsFixed(1) ?? '--';
    final gColor = latestGlucose != null ? _glucoseColor(latestGlucose) : AppColors.textTertiary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 第一行：血糖 + 连接状态
          Row(
            children: [
              // 血糖区域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('当前血糖', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          glucoseStr,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Text('mmol/L', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 连接状态
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _connectionColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _connectionColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _connectionColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _connectionText,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 电池
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _pumpStatus.batteryLevel > 20
                            ? Icons.battery_std
                            : Icons.battery_alert,
                        color: _pumpStatus.batteryLevel > 20
                            ? Colors.white70
                            : AppColors.danger,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_pumpStatus.batteryLevel}%',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 第二行：基础率 + 药量 + 输注状态
          Row(
            children: [
              _statusBadge(Icons.speed, '基础率', '${_pumpStatus.currentBasalRate.toStringAsFixed(2)} U/h'),
              const SizedBox(width: 12),
              _statusBadge(
                Icons.water_drop,
                '药量',
                '${_pumpStatus.reservoirRemaining.toInt()}U',
                valueColor: _pumpStatus.reservoirRemaining < 20 ? AppColors.danger : null,
              ),
              const SizedBox(width: 12),
              _statusBadge(
                Icons.inventory_2,
                '今日',
                '${_pumpStatus.todayTotalDelivered.toStringAsFixed(1)}U',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(IconData icon, String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.white,
                )),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  /// 快捷操作卡片
  Widget _buildQuickActions() {
    return InfoCard(
      title: '快捷操作',
      icon: Icons.flash_on,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _actionButton('大剂量', Icons.medical_services, AppColors.primary, () {
              Navigator.pushNamed(context, '/pump_bolus');
            })),
            const SizedBox(width: 8),
            Expanded(child: _actionButton('临时基础率', Icons.timer_outlined, AppColors.warning, () {
              Navigator.pushNamed(context, '/pump_temp_basal');
            })),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _actionButton('基础率设置', Icons.speed, AppColors.info, () {
              Navigator.pushNamed(context, '/pump_basal');
            })),
            const SizedBox(width: 8),
            Expanded(
              child: _pumpStatus.mode == PumpMode.paused
                  ? _actionButton('恢复输注', Icons.play_arrow, AppColors.success, _resumePump)
                  : _actionButton('暂停输注', Icons.pause, AppColors.danger, _pausePump),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pausePump() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('暂停输注'),
        content: const Text('确定要暂停胰岛素输注吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('确认暂停'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _pumpService.pause();
    }
  }

  Future<void> _resumePump() async {
    await _pumpService.resume();
  }

  /// 信息概览面板
  Widget _buildInfoPanel() {
    return InfoCard(
      title: '运行概览',
      icon: Icons.dashboard,
      children: [
        InfoCardRow(
          icon: Icons.speed,
          label: '输注模式',
          value: _pumpStatus.mode == PumpMode.tempBasal
              ? '临时基础率'
              : _pumpStatus.mode == PumpMode.paused
                  ? '已暂停'
                  : _pumpStatus.mode == PumpMode.bolusing
                      ? '大剂量输注中'
                      : '正常运行',
          valueColor: _pumpStatus.mode == PumpMode.running
              ? AppColors.success
              : _pumpStatus.mode == PumpMode.paused
                  ? AppColors.warning
                  : AppColors.primary,
        ),
        InfoCardRow(
          icon: Icons.memory,
          label: '泵型号',
          value: '睿昇 RS-2401',
        ),
        InfoCardRow(
          icon: Icons.water_drop_outlined,
          label: '剩余药量',
          value: '${_pumpStatus.reservoirRemaining.toInt()} U',
          valueColor: _pumpStatus.reservoirRemaining < 20 ? AppColors.danger : null,
        ),
        if (_pumpStatus.lastDeliveryTime != null)
          InfoCardRow(
            icon: Icons.access_time,
            label: '上次输注',
            value: _formatTime(_pumpStatus.lastDeliveryTime!),
          ),
        if (_pumpStatus.tempBasalRate != null)
          InfoCardRow(
            icon: Icons.timer,
            label: '临时基础率',
            value: '${_pumpStatus.tempBasalRate!.toStringAsFixed(2)} U/h 剩余${_pumpStatus.tempBasalRemainingMinutes}分钟',
            valueColor: AppColors.warning,
          ),
      ],
    );
  }

  /// 今日输注统计
  Widget _buildDeliverySummary() {
    return InfoCard(
      title: '今日统计',
      icon: Icons.bar_chart,
      children: [
        Row(
          children: [
            Expanded(child: _statTile('基础输注', '8.5 U', Icons.speed, AppColors.primary)),
            Container(width: 1, height: 40, color: AppColors.divider),
            Expanded(child: _statTile('大剂量', '4.0 U', Icons.medical_services, AppColors.bolusDose)),
            Container(width: 1, height: 40, color: AppColors.divider),
            Expanded(child: _statTile('总量', '12.5 U', Icons.inventory_2, AppColors.success)),
          ],
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
      ],
    );
  }

  /// 最近血糖记录区
  List<Widget> _buildGlucoseSection() {
    return [
      Row(
        children: [
          const Icon(Icons.show_chart, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          const Text('最近血糖', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ],
      ),
      const SizedBox(height: 8),
      ..._recentGlucose.take(4).map((r) => Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: _glucoseColor(r.glucose).withValues(alpha: 0.2),
                child: Text(
                  r.glucose.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _glucoseColor(r.glucose),
                  ),
                ),
              ),
              title: Text(
                '${_formatTime(r.timestamp)}  ${r.tag.displayName}',
                style: const TextStyle(fontSize: 13),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
            ),
          )),
    ];
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
