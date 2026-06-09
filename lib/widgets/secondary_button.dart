import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 次按钮组件
///
/// 遵循胰岛素泵医疗App设计规范：
/// - 白色背景 + 1.5px 蓝色边框
/// - 圆角 12px，高度 48px
/// - 用于次要操作（如取消、返回、预览）
///
/// 使用示例：
/// ```dart
/// SecondaryButton(
///   label: '取消',
///   icon: Icons.close,
///   onPressed: () => Navigator.pop(context),
/// )
/// ```
class SecondaryButton extends StatelessWidget {
  /// 按钮文字
  final String label;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 前置图标（可选）
  final IconData? icon;

  /// 后置图标（可选）
  final IconData? trailingIcon;

  /// 按钮是否禁用
  final bool disabled;

  /// 按钮宽度（默认全宽）
  final double? width;

  /// 按钮高度（默认 48px）
  final double height;

  /// 自定义样式
  final ButtonStyle? style;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.disabled = false,
    this.width = double.infinity,
    this.height = AppSpacing.buttonHeight,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = disabled;
    final Color fgColor = isDisabled
        ? AppColors.disabledText
        : AppColors.primary;
    final Color borderColor = isDisabled
        ? AppColors.divider
        : AppColors.primary;

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
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: AppSpacing.buttonHorizontal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              textStyle: AppTypography.buttonStyle.copyWith(color: fgColor),
            ),
        child: _buildChild(fgColor),
      ),
    );
  }

  Widget _buildChild(Color fgColor) {
    if (icon != null && trailingIcon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 20),
        ],
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

    if (trailingIcon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 20),
        ],
      );
    }

    return Text(label);
  }
}
