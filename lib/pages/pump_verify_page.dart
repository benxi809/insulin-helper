/// 链接验证页面
///
/// 参考设计图：23链接验证、21链接失败提示
/// 功能：验证泵与手机的配对连接

import 'package:flutter/material.dart';
import 'package:insulin_app/services/pump_service.dart';
import 'package:insulin_app/theme/app_colors.dart';
import 'package:insulin_app/theme/app_spacing.dart';
import 'package:insulin_app/widgets/widgets.dart';

class PumpVerifyPage extends StatefulWidget {
  const PumpVerifyPage({super.key});

  @override
  State<PumpVerifyPage> createState() => _PumpVerifyPageState();
}

class _PumpVerifyPageState extends State<PumpVerifyPage> {
  final PumpService _pumpService = PumpService();
  bool _verifying = false;
  bool _verified = false;
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '链接验证',
      showBack: true,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_verified) ...[
              const Icon(Icons.verified, size: 80, color: AppColors.success),
              const SizedBox(height: 24),
              const Text('连接验证成功', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.success)),
              const SizedBox(height: 8),
              const Text('睿昇胰岛素泵 #2401', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              const Text('已安全连接，可以开始使用', style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
              const SizedBox(height: 32),
              PrimaryButton(
                label: '完成',
                width: 200,
                onPressed: () => Navigator.pop(context),
              ),
            ] else if (_failed) ...[
              const Icon(Icons.error_outline, size: 80, color: AppColors.danger),
              const SizedBox(height: 24),
              const Text('连接失败', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.danger)),
              const SizedBox(height: 8),
              const Text('无法验证泵的身份，请重试', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              PrimaryButton(
                label: '重试',
                width: 200,
                icon: Icons.refresh,
                onPressed: _startVerify,
              ),
            ] else ...[
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: _verifying
                    ? const Center(child: CircularProgressIndicator())
                    : const Icon(Icons.bluetooth_searching, size: 56, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                _verifying ? '正在验证连接...' : '准备验证',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                '请确保泵上显示相同的验证码',
                style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 24),

              // 模拟验证码
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Text('2 4 7 9', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 12)),
              ),

              const SizedBox(height: 16),
              const Text('请在泵上确认此验证码', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),

              const SizedBox(height: 32),
              PrimaryButton(
                label: '开始验证',
                width: 200,
                icon: Icons.verified_user,
                onPressed: _startVerify,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() => _failed = true);
                },
                child: const Text('验证码不匹配', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startVerify() async {
    setState(() {
      _verifying = true;
      _verified = false;
      _failed = false;
    });

    // 模拟验证过程
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final connected = _pumpService.connectionState == _PumpConnectionState.connected;
      setState(() {
        _verifying = false;
        _verified = connected;
        _failed = !connected;
      });
    }
  }
}
