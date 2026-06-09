import 'package:flutter/material.dart';

/// 胰岛素泵医疗App — 颜色常量定义
///
/// 设计规范参考：
/// - 主色：蓝色系（#007AFF / #2196F3），传递信任、专业、冷静
/// - 功能色：绿色(成功)、黄色(警告)、红色(危险)
/// - 背景色：#F5F5F5 浅灰底色，卡片 #FFFFFF 白色
/// - 文字色：三层灰度 (#333 / #666 / #999)
class AppColors {
  AppColors._();

  // ──────────────────────────────────────────────
  // 主色 — Primary
  // ──────────────────────────────────────────────
  /// 主蓝色 — 导航栏、主按钮、选中态
  static const Color primary = Color(0xFF007AFF);
  /// 主色浅色变体 — 背景高亮、选中背景
  static const Color primaryLight = Color(0xFFE5F2FF);
  /// 主色深色变体 — 按压态、强调文字
  static const Color primaryDark = Color(0xFF0055CC);

  // ──────────────────────────────────────────────
  // 功能色 — Semantic
  // ──────────────────────────────────────────────
  /// 成功/正常运行 — 绿色
  static const Color success = Color(0xFF34C759);
  /// 成功背景（浅绿）
  static const Color successLight = Color(0xFFE8F8ED);

  /// 警告/一级告警 — 黄色/琥珀
  static const Color warning = Color(0xFFFF9500);
  /// 警告背景（浅黄）
  static const Color warningLight = Color(0xFFFFF3E0);

  /// 危险/二级告警 — 红色
  static const Color danger = Color(0xFFFF3B30);
  /// 危险背景（浅红）
  static const Color dangerLight = Color(0xFFFFEBEA);

  /// 信息提示蓝
  static const Color info = Color(0xFF5AC8FA);
  /// 信息背景（浅蓝）
  static const Color infoLight = Color(0xFFE5F7FF);

  // ──────────────────────────────────────────────
  // 中性色 — Neutral
  // ──────────────────────────────────────────────
  /// 页面背景
  static const Color background = Color(0xFFF5F5F7);
  /// 卡片/内容背景
  static const Color surface = Color(0xFFFFFFFF);
  /// 深色背景（用于开关机、暗色模式）
  static const Color surfaceDark = Color(0xFF1C1C1E);

  /// 分割线
  static const Color divider = Color(0xFFE5E5EA);
  /// 分隔符（更浅）
  static const Color dividerLight = Color(0xFFF2F2F7);

  /// 禁用态背景
  static const Color disabledBackground = Color(0xFFF2F2F7);
  /// 禁用态文字
  static const Color disabledText = Color(0xFFC7C7CC);

  // ──────────────────────────────────────────────
  // 文字色 — Text
  // ──────────────────────────────────────────────
  /// 标题/主要文字
  static const Color textPrimary = Color(0xFF1C1C1E);
  /// 正文/次级文字
  static const Color textSecondary = Color(0xFF636366);
  /// 辅助说明文字/占位符
  static const Color textTertiary = Color(0xFFAEAEB2);
  /// 白色文字（在主色/暗色背景上使用）
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ──────────────────────────────────────────────
  // 图表色 — Chart
  // ──────────────────────────────────────────────
  /// 血糖曲线色
  static const Color chartLine = Color(0xFF007AFF);
  /// 目标范围填充色（半透明）
  static const Color chartRange = Color(0x33007AFF);
  /// 血糖高于目标范围
  static const Color chartHigh = Color(0xFFFF9500);
  /// 血糖低于目标范围
  static const Color chartLow = Color(0xFFFF3B30);
  /// 血糖在目标范围内
  static const Color chartInRange = Color(0xFF34C759);

  // ──────────────────────────────────────────────
  // 基础率 & 剂量 — Pump
  // ──────────────────────────────────────────────
  /// 基础率曲线
  static const Color basalRate = Color(0xFF007AFF);
  /// 大剂量输注
  static const Color bolusDose = Color(0xFFAF52DE);
  /// 临时基础率
  static const Color tempBasal = Color(0xFFFF9500);
}
