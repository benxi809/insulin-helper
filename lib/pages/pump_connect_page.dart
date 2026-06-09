/// 蓝牙连接页面
///
/// 参考设计图：05泵列表、28扫码界面、23链接验证
/// 功能：
/// - 扫描并显示可用泵设备列表
/// - 连接/断开管理
/// - 连接状态显示

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:glucare_app/services/pump_service.dart';
import 'package:glucare_app/models/pump_models.dart';
import 'package:glucare_app/theme/app_colors.dart';
import 'package:glucare_app/theme/app_spacing.dart';
import 'package:glucare_app/theme/app_typography.dart';
import 'package:glucare_app/widgets/widgets.dart';

class PumpConnectPage extends StatefulWidget {
  const PumpConnectPage({super.key});

  @override
  State<PumpConnectPage> createState() => _PumpConnectPageState();
}

class _PumpConnectPageState extends State<PumpConnectPage> {
  final PumpService _pumpService = PumpService();
  List<Map<String, String>> _devices = [];
  bool _scanning = false;
  StreamSubscription<Map<String, String>>? _scanSub;
  bool _connecting = false;
  String? _connectedId;

  @override
  void initState() {
    super.initState();
    _connectedId = _pumpService.connectionState == PumpConnectionState.connected
        ? 'RS-2401'
        : null;
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _scanning = true;
      _devices = [];
    });

    _scanSub = _pumpService.scanPumps().listen((pump) {
      if (mounted) {
        setState(() => _devices.add(pump));
      }
    }, onDone: () {
      if (mounted) setState(() => _scanning = false);
    });

    // 5秒后停止扫描
    Future.delayed(const Duration(seconds: 5), () {
      _scanSub?.cancel();
      if (mounted) setState(() => _scanning = false);
    });
  }

  Future<void> _connect(String deviceId) async {
    setState(() => _connecting = true);
    final success = await _pumpService.connect(deviceId);
    if (mounted) {
      setState(() {
        _connecting = false;
        if (success) _connectedId = deviceId;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已连接到 $deviceId'), duration: const Duration(seconds: 2)),
        );
        // 连接成功后跳转到验证页
        Navigator.pushNamed(context, '/pump_verify');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('连接失败，请重试'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    await _pumpService.disconnect();
    if (mounted) {
      setState(() => _connectedId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已断开连接'), duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _connectedId != null;

    return AppScaffold(
      title: '泵连接',
      showBack: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),

          // 当前连接状态
          if (isConnected)
            _buildConnectedCard()
          else
            _buildDisconnectedCard(),

          const SizedBox(height: AppSpacing.xl),

          // 设备列表标题
          Row(
            children: [
              const SizedBox(width: AppSpacing.lg + 4),
              const Expanded(
                child: Text('可用设备', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
              if (_scanning)
                const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.lg),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                TextButton.icon(
                  onPressed: _startScan,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('扫描'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // 设备列表
          if (_devices.isEmpty && !_scanning)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.bluetooth_disabled, size: 48, color: AppColors.textTertiary),
                    SizedBox(height: 12),
                    Text('未发现设备', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                    SizedBox(height: 4),
                    Text('请确保泵在附近且蓝牙已开启', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                  ],
                ),
              ),
            )
          else if (_scanning && _devices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('正在扫描设备...', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            Padding(
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
                  children: _devices.map((device) {
                    final deviceId = device['id']!;
                    final name = device['name']!;
                    final signal = device['signal']!;
                    final isThisConnected = deviceId == _connectedId;

                    return SettingsListTile(
                      icon: isThisConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                      iconColor: isThisConnected ? AppColors.success : AppColors.primary,
                      title: name,
                      subtitle: '信号: $signal${isThisConnected ? " · 已连接" : ""}',
                      trailing: isThisConnected
                          ? TextButton(
                              onPressed: _disconnect,
                              child: const Text('断开', style: TextStyle(color: AppColors.danger, fontSize: 13)),
                            )
                          : _connecting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : null,
                      showTrailingArrow: !isThisConnected,
                      onTap: isThisConnected ? null : () => _connect(deviceId),
                    );
                  }).toList(),
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.xl),

          // 扫码入口
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SecondaryButton(
              label: '扫码配对',
              icon: Icons.qr_code_scanner,
              onPressed: () => Navigator.pushNamed(context, '/pump_scan'),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 连接说明
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg + 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('连接提示', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                _tipItem('确保胰岛素泵在手机附近（10米内）'),
                _tipItem('确保泵的蓝牙功能已开启'),
                _tipItem('如连接失败，请尝试重启泵后再试'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('· ', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.success.withValues(alpha: 0.1), AppColors.successLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.bluetooth_connected, color: Colors.white, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('已连接', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success)),
                  const SizedBox(height: 2),
                  Text('$_connectedId · 信号良好', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            TextButton(
              onPressed: _disconnect,
              child: const Text('断开', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisconnectedCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.disabledBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.bluetooth_disabled, color: AppColors.disabledText, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('未连接', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  SizedBox(height: 2),
                  Text('点击"扫描"查找附近的泵设备', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                ],
              ),
            ),
            PrimaryButton(
              label: '扫描',
              width: 80,
              height: 36,
              onPressed: _startScan,
            ),
          ],
        ),
      ),
    );
  }
}
