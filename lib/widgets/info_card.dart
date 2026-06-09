import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 信息卡片组件
///
/// 遵循胰岛素泵医疗App设计规范：
/// - 白色背景 + 12px 圆角 + 轻微阴影
/// - 左右内边距 16px
/// - 用于主桌面信息展示、状态总览等场景
///
/// 使用示例：
/// ```dart
/// InfoCard(
///   title: '今日汇总',
///   subtitle: '血糖控制良好',
///   icon: Icons.today,
///   trailing: Text('查看详情 >'),
///   children: [
///     _buildStatRow('平均血糖', '6.2', 'mmol/L'),
///   ],
///   onTap: () => _navigateToDetail(),
/// )
/// ```
class InfoCard extends StatelessWidget {
  /// 卡片标题
  final String? title;

  /// 副标题/说明文字
  final String? subtitle;

  /// 标题前置图标
  final IconData? icon;

  /// 图标颜色（默认主蓝色）
  final Color? iconColor;

  /// 尾部组件（如箭头、标签、开关）
  final Widget? trailing;

  /// 卡片主体子组件（在标题下方）
  final List<Widget>? children;

  /// 整卡点击回调（使整张卡片可点击）
  final VoidCallback? onTap;

  /// 卡片背景色（默认白色）
  final Color? backgroundColor;

  /// 卡片圆角
  final double borderRadius;

  /// 卡片内边距
  final EdgeInsetsGeometry padding;

  /// 顶部边框颜色（用于状态指示条，null 则不显示）
  final Color? topAccentColor;

  /// 是否需要底部安全区（用于列表末尾的卡片）
  final bool withBottomPadding;

  const InfoCard({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.children,
    this.onTap,
    this.backgroundColor,
    this.borderRadius = AppSpacing.cardRadius,
    this.padding = AppSpacing.cardPadding,
    this.topAccentColor,
    this.withBottomPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = backgroundColor ??
        (isDark ? const Color(0xFF2C2C2E) : AppColors.surface);

    Widget card = Container(
      margin: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: withBottomPadding ? AppSpacing.lg : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black)
                .withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: AppSpacing.cardShadowBlur,
            offset: const Offset(0, AppSpacing.cardShadowOffset),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部色条
          if (topAccentColor != null)
            Container(height: 3, color: topAccentColor),

          // 标题区域
          if (title != null || icon != null || trailing != null)
            _buildHeader(),

          // 主体子组件
          if (children != null && children!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                left: padding.horizontal / 2,
                right: padding.horizontal / 2,
                bottom: padding.vertical / 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children!,
              ),
            ),
        ],
      ),
    );

    // 如果可点击，包裹 InkWell
    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(
        left: padding.horizontal / 2,
        right: padding.horizontal / 2,
        top: padding.vertical / 2,
        bottom: (children != null && children!.isNotEmpty)
            ? AppSpacing.sm
            : padding.vertical / 2,
      ),
      child: Row(
        children: [
          // 图标
          if (icon != null) ...[
            Icon(
              icon,
              size: 22,
              color: iconColor ?? AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],

          // 标题和副标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: AppTypography.h3Style.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmallStyle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // 尾部组件
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 便捷方法：构建带图标的值行（用于卡片内部统计行）
class InfoCardRow extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData? icon;
  final Color? valueColor;
  final Widget? trailing;

  const InfoCardRow({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.icon,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            label,
            style: AppTypography.bodyStyle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTypography.h3Style.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (unit != null) ...[
            const SizedBox(width: 4),
            Text(
              unit!,
              style: AppTypography.captionStyle.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
