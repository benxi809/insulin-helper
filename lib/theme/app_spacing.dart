import 'package:flutter/material.dart';

/// 胰岛素泵医疗App — 间距与布局规范
///
/// 设计规范：
/// - 屏幕安全边距（左右）：16px
/// - 组件间距（垂直）：12px / 16px / 24px
/// - 列表项内边距（水平）：16px
/// - 列表项高度：48-56px
/// - 卡片圆角：8-12px
/// - 卡片内边距：16px
/// - 按钮高度：44-48px
/// - 按钮圆角：8-12px
class AppSpacing {
  AppSpacing._();

  // ──────────────────────────────────────────────
  // 微间距 (2 ~ 8)
  // ──────────────────────────────────────────────
  /// 极小间距 2px
  static const double xxs = 2.0;
  /// 特小间距 4px
  static const double xs = 4.0;
  /// 小间距 8px
  static const double sm = 8.0;

  // ──────────────────────────────────────────────
  // 中间距 (12 ~ 24)
  // ──────────────────────────────────────────────
  /// 中间距 12px — 卡片间距、组件内部间距
  static const double md = 12.0;
  /// 标准间距 16px — 屏幕安全边距、卡片内边距
  static const double lg = 16.0;
  /// 大间距 20px
  static const double xl = 20.0;
  /// 特大间距 24px — 区块间距
  static const double xxl = 24.0;

  // ──────────────────────────────────────────────
  // 超大间距 (32 ~ 48)
  // ──────────────────────────────────────────────
  /// 32px — 页面顶部间距
  static const double section = 32.0;
  /// 40px
  static const double sectionLarge = 40.0;
  /// 48px — 页面底部间距
  static const double sectionXl = 48.0;

  // ──────────────────────────────────────────────
  // 控件尺寸常量
  // ──────────────────────────────────────────────
  /// 按钮高度 — 标准 (48px)
  static const double buttonHeight = 48.0;
  /// 按钮高度 — 小号 (36px)
  static const double buttonHeightSmall = 36.0;
  /// 按钮圆角 (12px)
  static const double buttonRadius = 12.0;
  /// 按钮圆角 — 小号 (8px)
  static const double buttonRadiusSmall = 8.0;

  /// 列表行高 (52px)
  static const double listTileHeight = 52.0;
  /// 列表图标右侧间距（图标宽度 + 间距）
  static const double listIconOffset = 52.0;

  /// 卡片圆角 (12px)
  static const double cardRadius = 12.0;
  /// 卡片圆角 — 小号 (8px)
  static const double cardRadiusSmall = 8.0;
  /// 卡片阴影模糊半径
  static const double cardShadowBlur = 8.0;
  /// 卡片阴影偏移
  static const double cardShadowOffset = 2.0;

  /// 滑块/拖拽控件高度
  static const double sliderHeight = 48.0;

  /// 最小触控区域 (44px)
  static const double minTouchArea = 44.0;

  // ──────────────────────────────────────────────
  // 便捷 EdgeInsets 常量
  // ──────────────────────────────────────────────

  /// 页面标准水平边距 (左16, 右16)
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: lg);

  /// 页面标准内边距 (左16, 右16, 上16, 下16)
  static const EdgeInsets pagePadding = EdgeInsets.all(lg);

  /// 卡片标准内边距 (左16, 右16, 上16, 下16)
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  /// 卡片水平内边距 (左16, 右16)
  static const EdgeInsets cardPaddingHorizontal = EdgeInsets.symmetric(horizontal: lg);

  /// 列表项标准内边距 (左16, 右16)
  static const EdgeInsets listTilePadding = EdgeInsets.symmetric(horizontal: lg);

  /// 按钮水平内边距 (左24, 右24)
  static const EdgeInsets buttonHorizontal = EdgeInsets.symmetric(horizontal: 24.0);

  // ──────────────────────────────────────────────
  // 便捷 SizedBox 常量
  // ──────────────────────────────────────────────

  /// 极小垂直间距 4px
  static const SizedBox gapXs = SizedBox(height: xs);
  /// 小垂直间距 8px
  static const SizedBox gapSm = SizedBox(height: sm);
  /// 中垂直间距 12px
  static const SizedBox gapMd = SizedBox(height: md);
  /// 标准垂直间距 16px
  static const SizedBox gapLg = SizedBox(height: lg);
  /// 大垂直间距 24px
  static const SizedBox gapXl = SizedBox(height: xl);
  /// 特大垂直间距 32px
  static const SizedBox gapSection = SizedBox(height: section);

  /// 极小水平间距 4px
  static const SizedBox gapXsH = SizedBox(width: xs);
  /// 小水平间距 8px
  static const SizedBox gapSmH = SizedBox(width: sm);
  /// 中水平间距 12px
  static const SizedBox gapMdH = SizedBox(width: md);
  /// 标准水平间距 16px
  static const SizedBox gapLgH = SizedBox(width: lg);
}
