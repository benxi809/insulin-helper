import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 危险按钮组件
///
/// 遵循胰岛素泵医疗App设计规范：
/// - 红色背景 + 白色文字
/// - 用于取消大剂量、暂停输注、删除数据等不可逆/高风险操作
/// - 圆角 12px，高度 48px
/// - 建议与确认弹窗或滑动确认控件配合使用
///
/// 使用示例：
/// ```dart
/// DangerButton(
///   label: '暂停输注',
///   icon: Icons.pause_circle_outline,
///   onPressed: () => _showPauseConfirmDialog(),
/// )
/// ```
class DangerButton extends StatelessWidget {
  /// 按钮文字
  final String label;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 是否显示加载状态
  final bool isLoading;

  /// 前置图标（可选）
  final IconData? icon;

  /// 按钮是否禁用
  final bool disabled;

  /// 按钮宽度（默认全宽）
  final double? width;

  /// 按钮高度（默认 48px）
  final double height;

  /// 是否使用边框样式（白色背景+红色边框，而非红色背景）
  final bool outlined;

  /// 自定义样式
  final ButtonStyle? style;

  const DangerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.disabled = false,
    this.width = double.infinity,
    this.height = AppSpacing.buttonHeight,
    this.outlined = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = disabled || isLoading;
    final Color bgColor = outlined
        ? Colors.transparent
        : (isDisabled ? AppColors.disabledBackground : AppColors.danger);
    final Color fgColor = outlined
        ? (isDisabled ? AppColors.disabledText : AppColors.danger)
        : (isDisabled ? AppColors.disabledText : AppColors.textOnPrimary);
    final Color borderColor = outlined
        ? (isDisabled ? AppColors.divider : AppColors.danger)
        : Colors.transparent;

    if (outlined) {
      return SizedBox(
        width: width,
        height: height,
        child: OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: style ??
              OutlinedButton.styleFrom(
                foregroundColor: fgColor,
                disabledForegroundColor: AppColors.disabledText,
                side: BorderSide(color: borderColor, width: 1.5),
                backgroundColor: bgColor,
                disabledBackgroundColor: Colors.transparent,
                elevation: 0,
                padding: AppSpacing.buttonHorizontal,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.buttonRadius),
                ),
                textStyle:
                    AppTypography.buttonStyle.copyWith(color: fgColor),
              ),
          child: _buildChild(fgColor),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: style ??
            ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              disabledBackgroundColor: AppColors.disabledBackground,
              disabledForegroundColor: AppColors.disabledText,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: AppSpacing.buttonHorizontal,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              textStyle:
                  AppTypography.buttonStyle.copyWith(color: fgColor),
            ),
        child: _buildChild(fgColor),
      ),
    );
  }

  Widget _buildChild(Color fgColor) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(fgColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }

    return Text(label);
  }
}
