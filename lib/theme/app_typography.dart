import 'package:flutter/material.dart';

/// 胰岛素泵医疗App — 字体样式规范
///
/// 设计规范：
/// - 中文字体：PingFang SC / Noto Sans SC（系统默认无衬线字体）
/// - 数字字体：等宽或半等宽（SF Mono / Roboto Mono），方便数字对齐读取
/// - 胰岛素泵涉及大量数字数据（剂量、时间、血糖值），可读性是第一优先级
///
/// 字号层级：
/// | 层级          | 字号    | 字重     | 用途                         |
/// |--------------|---------|---------|------------------------------|
/// | H1           | 28-32px | Bold    | 页面标题、大数字显示           |
/// | H2           | 22-24px | SemiBold| 区块标题、重要数值             |
/// | H3           | 18-20px | Medium  | 卡片标题、列表标题             |
/// | Body         | 16-17px | Regular | 正文主要内容                   |
/// | BodySmall    | 14-15px | Regular | 辅助信息、说明文字             |
/// | Caption      | 12-13px | Regular | 标签、时间戳、脚注             |
/// | Giant        | 40-56px | Bold    | 当前基础率/大剂量数值显示      |
class AppTypography {
  AppTypography._();

  // ──────────────────────────────────────────────
  // 字号常量（基于 375×812 基准，实际使用中可根据屏幕缩放）
  // ──────────────────────────────────────────────
  static const double giant = 48.0;   // 特大数字 — 血糖值/剂量
  static const double giantLarge = 56.0; // 超大数字 — 锁屏/运行界面主显示
  static const double h1 = 28.0;
  static const double h2 = 22.0;
  static const double h3 = 18.0;
  static const double body = 16.0;
  static const double bodySmall = 14.0;
  static const double caption = 12.0;
  static const double overline = 10.0;

  // ──────────────────────────────────────────────
  // TextStyle 工厂方法
  // ──────────────────────────────────────────────

  /// 特大数字样式 — 运行界面核心数值
  static const TextStyle giantStyle = TextStyle(
    fontSize: giant,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -1.0,
  );

  /// 超大数字样式 — 锁屏/全屏显示
  static const TextStyle giantLargeStyle = TextStyle(
    fontSize: giantLarge,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -1.5,
  );

  /// H1 — 页面标题
  static const TextStyle h1Style = TextStyle(
    fontSize: h1,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.0,
  );

  /// H2 — 区块标题、重要数值
  static const TextStyle h2Style = TextStyle(
    fontSize: h2,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.0,
  );

  /// H3 — 卡片标题、列表标题
  static const TextStyle h3Style = TextStyle(
    fontSize: h3,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.0,
  );

  /// Body — 正文主要内容
  static const TextStyle bodyStyle = TextStyle(
    fontSize: body,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.0,
  );

  /// BodySmall — 辅助信息、说明文字
  static const TextStyle bodySmallStyle = TextStyle(
    fontSize: bodySmall,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.0,
  );

  /// Caption — 标签、时间戳、脚注
  static const TextStyle captionStyle = TextStyle(
    fontSize: caption,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0.2,
  );

  /// Overline — 极小说明文字（单位标签、角标）
  static const TextStyle overlineStyle = TextStyle(
    fontSize: overline,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// 等宽数字样式 — 用于血糖值、剂量数字显示
  static const TextStyle monoStyle = TextStyle(
    fontSize: body,
    fontWeight: FontWeight.w600,
    fontFamily: 'monospace',
    height: 1.4,
    letterSpacing: 0.5,
  );

  /// 按钮文字样式
  static const TextStyle buttonStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.3,
  );

  /// 小按钮文字样式
  static const TextStyle buttonSmallStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.2,
  );
}
