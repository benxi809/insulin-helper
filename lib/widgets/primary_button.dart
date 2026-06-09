import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 主按钮组件
///
/// 遵循胰岛素泵医疗App设计规范：
/// - 蓝色渐变背景 + 白色文字
/// - 圆角 12px，高度 48px（最小触控区域 44px）
/// - 支持加载状态、禁用态、图标前置
///
/// 使用示例：
/// ```dart
/// PrimaryButton(
///   label: '确认输注',
///   icon: Icons.check_circle_outline,
///   onPressed: () => _onConfirm(),
///   isLoading: _isLoading,
/// )
/// ```
class PrimaryButton extends StatelessWidget {
  /// 按钮文字
  final String label;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 是否显示加载状态（禁用点击并显示进度指示器）
  final bool isLoading;

  /// 前置图标（可选）
  final IconData? icon;

  /// 后置图标（可选）
  final IconData? trailingIcon;

  /// 按钮是否完全禁用
  final bool disabled;

  /// 按钮宽度（默认全宽 double.infinity）
  final double? width;

  /// 按钮高度（默认 48px）
  final double height;

  /// 自定义按钮样式
  final ButtonStyle? style;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.disabled = false,
    this.width = double.infinity,
    this.height = AppSpacing.buttonHeight,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = disabled || isLoading;
    final Color bgColor = isDisabled
        ? AppColors.disabledBackground
        : AppColors.primary;
    final Color fgColor = isDisabled
        ? AppColors.disabledText
        : AppColors.textOnPrimary;

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
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              textStyle: AppTypography.buttonStyle.copyWith(color: fgColor),
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
