import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 数据显示卡片组件
///
/// 遵循胰岛素泵医疗App设计规范（参考 `30治疗参数设置` 参数卡片风格）：
/// - 参数卡片：标题栏 + 数值区域 + 编辑入口
/// - 数值突出显示，大字号
/// - 用于展示血糖值、基础率、剂量、碳水系数等医疗数据
///
/// 使用示例：
/// ```dart
/// DataCard(
///   title: '当前血糖',
///   value: '6.2',
///   unit: 'mmol/L',
///   icon: Icons.biotech,
///   status: DataStatus.normal,
///   onEdit: () => _editValue(),
/// )
/// ```
enum DataStatus {
  /// 正常/目标范围内
  normal,

  /// 偏高/高于目标范围
  high,

  /// 偏低/低于目标范围
  low,

  /// 警告状态
  warning,

  /// 禁用/不可用
  disabled,
}

class DataCard extends StatelessWidget {
  /// 卡片标题
  final String title;

  /// 数值（主显示）
  final String value;

  /// 数值单位
  final String? unit;

  /// 前置图标
  final IconData? icon;

  /// 数据状态（影响边框/背景色）
  final DataStatus status;

  /// 副标题/说明
  final String? subtitle;

  /// 底部文字（如时间戳、趋势描述）
  final String? footer;

  /// 编辑回调（显示编辑图标）
  final VoidCallback? onEdit;

  /// 整卡点击回调
  final VoidCallback? onTap;

  /// 自定义颜色映射（覆盖默认状态颜色）
  final Color? customValueColor;

  /// 卡片宽度（null 则自适应）
  final double? width;

  /// 大数值字号（默认 28px h1）
  final double? valueFontSize;

  /// 是否紧凑模式（用于网格布局）
  final bool compact;

  const DataCard({
    super.key,
    required this.title,
    required this.value,
    this.unit,
    this.icon,
    this.status = DataStatus.normal,
    this.subtitle,
    this.footer,
    this.onEdit,
    this.onTap,
    this.customValueColor,
    this.width,
    this.valueFontSize,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = customValueColor ?? _statusColor(status);
    final Color statusBgColor = _statusBgColor(status);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? const Color(0xFF2C2C2E) : AppColors.surface;

    // 紧凑模式：更小的内边距和间距
    final double hPadding = compact ? AppSpacing.md : AppSpacing.lg;
    final double vPadding = compact ? AppSpacing.md : AppSpacing.lg;

    Widget card = Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: hPadding,
        vertical: vPadding,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border(
          left: BorderSide(
            color: statusColor,
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black)
                .withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: AppSpacing.cardShadowBlur,
            offset: const Offset(0, AppSpacing.cardShadowOffset),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题行
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: statusColor),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                title,
                style: AppTypography.bodySmallStyle.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),

          // 数值区域
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: AppTypography.h1Style.copyWith(
                  fontSize: valueFontSize ?? (compact ? 22 : 28),
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: compact ? 2 : 4,
                  ),
                  child: Text(
                    unit!,
                    style: AppTypography.bodySmallStyle.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // 副标题
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: AppTypography.captionStyle.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          // 底部说明
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              footer!,
              style: AppTypography.captionStyle.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );

    // 如果可点击，包裹 InkWell
    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }

  /// 根据状态获取对应颜色
  Color _statusColor(DataStatus status) {
    switch (status) {
      case DataStatus.normal:
        return AppColors.primary;
      case DataStatus.high:
        return AppColors.warning;
      case DataStatus.low:
        return AppColors.danger;
      case DataStatus.warning:
        return AppColors.warning;
      case DataStatus.disabled:
        return AppColors.disabledText;
    }
  }

  Color _statusBgColor(DataStatus status) {
    switch (status) {
      case DataStatus.normal:
        return AppColors.primaryLight;
      case DataStatus.high:
        return AppColors.warningLight;
      case DataStatus.low:
        return AppColors.dangerLight;
      case DataStatus.warning:
        return AppColors.warningLight;
      case DataStatus.disabled:
        return AppColors.disabledBackground;
    }
  }
}
