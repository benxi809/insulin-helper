/// 扫码页面
///
/// 参考设计图：28扫码界面、38-1连接超时、38-2未识别到二维码
/// 功能：模拟扫码配对流程

import 'package:flutter/material.dart';
import 'package:insulin_app/theme/app_colors.dart';
import 'package:insulin_app/theme/app_spacing.dart';
import 'package:insulin_app/widgets/widgets.dart';

class PumpScanPage extends StatefulWidget {
  const PumpScanPage({super.key});

  @override
  State<PumpScanPage> createState() => _PumpScanPageState();
}

class _PumpScanPageState extends State<PumpScanPage> {
  bool _scanning = false;
  bool _scanned = false;
  bool _timeout = false;

  @override
  void initState() {
    super.initState();
    _startSimulatedScan();
  }

  void _startSimulatedScan() {
    setState(() {
      _scanning = true;
      _scanned = false;
      _timeout = false;
    });

    // 模拟扫描过程
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _scanning = false;
          _scanned = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '扫码配对',
      showBack: true,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_scanning) ...[
              // 扫码动画
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, size: 80, color: AppColors.primary),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('正在扫描二维码...', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              const CircularProgressIndicator(),
            ] else if (_scanned) ...[
              const Icon(Icons.check_circle, size: 80, color: AppColors.success),
              const SizedBox(height: 24),
              const Text('识别成功', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('设备: 睿昇胰岛素泵 #2401', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              PrimaryButton(
                label: '开始连接',
                width: 200,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/pump_verify');
                },
              ),
              SecondaryButton(
                label: '重新扫描',
                width: 200,
                onPressed: _startSimulatedScan,
              ),
            ] else ...[
              const Icon(Icons.qr_code_scanner, size: 80, color: AppColors.textTertiary),
              const SizedBox(height: 24),
              const Text('将二维码置于框内', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              const Text('扫描泵身或包装上的二维码', style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
              const SizedBox(height: 24),
              PrimaryButton(
                label: '开始扫描',
                width: 200,
                onPressed: _startSimulatedScan,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
