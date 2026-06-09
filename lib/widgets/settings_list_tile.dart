import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 设置列表项组件
///
/// 遵循胰岛素泵医疗App设计规范（参考 `40系统设置`、`界面个性化`）：
/// - 左图标 + 标题 + 可选副标题/右辅助信息 + 右箭头
/// - 行高 48-56px，水平内边距 16px
/// - 分割线缩进：有图标时 52px，无图标时 16px
///
/// 使用示例：
/// ```dart
/// SettingsListTile(
///   icon: Icons.notifications_outlined,
///   title: '通知设置',
///   subtitle: '管理提醒和报警',
///   trailing: Text('开启'),
///   onTap: () => _navigateToNotifSettings(),
/// )
/// ```
class SettingsListTile extends StatelessWidget {
  /// 标题文字（必填）
  final String title;

  /// 前置图标
  final IconData? icon;

  /// 图标背景色（默认浅蓝背景）
  final Color? iconBackground;

  /// 图标颜色（默认主蓝色）
  final Color? iconColor;

  /// 副标题/说明文字
  final String? subtitle;

  /// 尾部组件（默认显示右箭头 `>`）
  final Widget? trailing;

  /// 是否显示尾部箭头（默认 true）
  final bool showTrailingArrow;

  /// 尾部文字（如开关状态、数值标签）
  final String? trailingText;

  /// 点击回调
  final VoidCallback? onTap;

  /// 是否显示分割线
  final bool showDivider;

  /// 分割线左边距（null 则自动计算）
  final double? dividerLeftIndent;

  /// 自定义高度
  final double height;

  /// 自定义内边距
  final EdgeInsetsGeometry? padding;

  /// 背景色
  final Color? backgroundColor;

  const SettingsListTile({
    super.key,
    required this.title,
    this.icon,
    this.iconBackground,
    this.iconColor,
    this.subtitle,
    this.trailing,
    this.showTrailingArrow = true,
    this.trailingText,
    this.onTap,
    this.showDivider = true,
    this.dividerLeftIndent,
    this.height = AppSpacing.listTileHeight,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = backgroundColor ??
        (isDark ? const Color(0xFF2C2C2E) : AppColors.surface);

    final Widget tile = Container(
      height: height,
      color: bg,
      padding: padding ?? AppSpacing.listTilePadding,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // 前置图标
            if (icon != null)
              _buildIcon()
            else
              const SizedBox(width: 4),

            // 标题区域（+ 可选副标题）
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyStyle.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: AppTypography.captionStyle.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // 尾部文字
            if (trailingText != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: Text(
                  trailingText!,
                  style: AppTypography.bodySmallStyle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

            // 尾部自定义组件
            if (trailing != null) trailing!,

            // 右箭头
            if (showTrailingArrow && trailing == null)
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tile,
        if (showDivider)
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: isDark
                ? const Color(0xFF38383A)
                : AppColors.divider,
            indent: dividerLeftIndent ??
                (icon != null ? AppSpacing.listIconOffset : AppSpacing.lg),
          ),
      ],
    );
  }

  Widget _buildIcon() {
    final Color bg = iconBackground ?? AppColors.primaryLight;
    final Color fg = iconColor ?? AppColors.primary;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 20,
        color: fg,
      ),
    );
  }
}

/// 带 Switch 开关的设置列表项
///
/// 使用示例：
/// ```dart
/// SwitchSettingsTile(
///   icon: Icons.notifications_outlined,
///   title: '推送通知',
///   value: _notificationsEnabled,
///   onChanged: (val) => _toggleNotifications(val),
/// )
/// ```
class SwitchSettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const SwitchSettingsTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsListTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      showDivider: showDivider,
      trailing: SizedBox(
        height: AppSpacing.minTouchArea,
        child: Switch(
          value: value,
          onChanged: onChanged,
        ),
      ),
      // 点击整行切换开关
      onTap: () => onChanged(!value),
    );
  }
}
