import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 大数字显示组件
///
/// 遵循胰岛素泵医疗App设计规范：
/// - 特大字号（40-56px Bold）用于当前基础率/大剂量数值显示
/// - 运行界面核心数据使用超大字体，高对比度
/// - 支持趋势指示器、单位标签、状态色
///
/// 适用于：
/// - 当前血糖值显示（CGM 实时数据）
/// - 基础率数值
/// - 大剂量输注剂量
/// - 剩余药量
///
/// 使用示例：
/// ```dart
/// LargeNumberDisplay(
///   value: '6.2',
///   unit: 'mmol/L',
///   label: '当前血糖',
///   trend: TrendDirection.stable,
///   status: GlucoseStatus.normal,
///   size: DisplaySize.large,
/// )
/// ```
enum DisplaySize {
  /// 超大（56px）— 锁屏/全屏模式
  giant,

  /// 大（48px）— 运行界面主数值
  large,

  /// 中（36px）— 卡片内突出数值
  medium,

  /// 小（28px）— 列表内数值
  small,
}

/// 趋势方向
enum TrendDirection {
  /// 快速上升 ↑↑
  rapidRise,

  /// 缓慢上升 ↑
  rise,

  /// 稳定 →
  stable,

  /// 缓慢下降 ↓
  fall,

  /// 快速下降 ↓↓
  rapidFall,

  /// 未知
  unknown,
}

/// 血糖/数据状态
enum GlucoseStatus {
  /// 正常范围
  normal,

  /// 偏高
  high,

  /// 偏低
  low,

  /// 严重偏高
  criticalHigh,

  /// 严重偏低
  criticalLow,

  /// 禁用/无数据
  none,
}

class LargeNumberDisplay extends StatelessWidget {
  /// 显示的数值（字符串形式，便于格式化如 "6.2"）
  final String value;

  /// 数值单位
  final String? unit;

  /// 数值标签（如 "当前血糖"、"基础率"）
  final String? label;

  /// 趋势方向（显示箭头）
  final TrendDirection? trend;

  /// 数据状态（决定颜色）
  final GlucoseStatus status;

  /// 显示尺寸
  final DisplaySize size;

  /// 自定义文字颜色（覆盖 status 自动颜色）
  final Color? customColor;

  /// 自定义背景色
  final Color? backgroundColor;

  /// 是否显示动画入场效果（默认 true）
  final bool animate;

  /// 数字对齐方式
  final TextAlign align;

  /// 最小宽度（防止数字过短）
  final double? minWidth;

  const LargeNumberDisplay({
    super.key,
    required this.value,
    this.unit,
    this.label,
    this.trend,
    this.status = GlucoseStatus.normal,
    this.size = DisplaySize.large,
    this.customColor,
    this.backgroundColor,
    this.animate = true,
    this.align = TextAlign.center,
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    final Color valueColor = customColor ?? _statusColor(status);
    final double fontSize = _fontSize(size);

    // 趋势箭头
    final String? trendIconText = _trendIcon(trend);

    // 趋势箭头颜色
    final Color? trendColor = trend != null ? _trendColor(trend!) : null;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标签
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              label!,
              style: AppTypography.bodySmallStyle.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: align,
            ),
          ),

        // 数值行
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              align == TextAlign.center
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
          children: [
            // 主数值
            Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: valueColor,
                height: 1.0,
                letterSpacing: -1.0,
              ),
              textAlign: align,
            ),

            // 单位
            if (unit != null)
              Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.xs,
                  bottom: fontSize * 0.15,
                ),
                child: Text(
                  unit!,
                  style: AppTypography.h3Style.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // 趋势箭头
            if (trendIconText != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: EdgeInsets.only(
                  bottom: fontSize * 0.1,
                ),
                child: Text(
                  trendIconText,
                  style: TextStyle(
                    fontSize: fontSize * 0.5,
                    fontWeight: FontWeight.w700,
                    color: trendColor ?? valueColor,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );

    // 如果有背景色，包裹容器
    if (backgroundColor != null) {
      content = Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: content,
      );
    }

    if (minWidth != null) {
      content = SizedBox(
        width: minWidth,
        child: content,
      );
    }

    return content;
  }

  double _fontSize(DisplaySize size) {
    switch (size) {
      case DisplaySize.giant:
        return AppTypography.giantLarge; // 56px
      case DisplaySize.large:
        return AppTypography.giant; // 48px
      case DisplaySize.medium:
        return 36.0;
      case DisplaySize.small:
        return AppTypography.h1; // 28px
    }
  }

  Color _statusColor(GlucoseStatus status) {
    switch (status) {
      case GlucoseStatus.normal:
        return AppColors.success;
      case GlucoseStatus.high:
        return AppColors.warning;
      case GlucoseStatus.low:
        return AppColors.danger;
      case GlucoseStatus.criticalHigh:
        return AppColors.danger;
      case GlucoseStatus.criticalLow:
        return AppColors.danger;
      case GlucoseStatus.none:
        return AppColors.disabledText;
    }
  }

  String? _trendIcon(TrendDirection? direction) {
    switch (direction) {
      case TrendDirection.rapidRise:
        return '↑↑';
      case TrendDirection.rise:
        return '↑';
      case TrendDirection.stable:
        return '→';
      case TrendDirection.fall:
        return '↓';
      case TrendDirection.rapidFall:
        return '↓↓';
      case TrendDirection.unknown:
        return '⇅';
      case null:
        return null;
    }
  }

  Color _trendColor(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.rapidRise:
      case TrendDirection.rise:
        return AppColors.warning;
      case TrendDirection.stable:
        return AppColors.success;
      case TrendDirection.fall:
      case TrendDirection.rapidFall:
        return AppColors.danger;
      case TrendDirection.unknown:
        return AppColors.textTertiary;
    }
  }
}
