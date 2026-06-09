import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 带导航栏的页面框架
///
/// 遵循胰岛素泵医疗App设计规范：
/// - 统一顶部导航栏（标题居中 + 返回按钮 + 右侧操作按钮）
/// - 支持安全区域适配
/// - 可选底部操作按钮区域
///
/// 使用示例：
/// ```dart
/// AppScaffold(
///   title: '治疗参数',
///   showBack: true,
///   actions: [
///     IconButton(icon: Icon(Icons.save), onPressed: _save),
///   ],
///   body: _buildBody(),
///   bottomBar: PrimaryButton(label: '保存', onPressed: _save),
/// )
/// ```
class AppScaffold extends StatelessWidget {
  /// 页面标题
  final String title;

  /// 标题下方的副标题（可选）
  final String? subtitle;

  /// 页面主体内容
  final Widget body;

  /// 是否显示返回按钮（默认 true，首页可不显示）
  final bool showBack;

  /// 返回按钮回调（null 则使用默认 Navigator.pop）
  final VoidCallback? onBack;

  /// 右侧操作按钮列表
  final List<Widget>? actions;

  /// 底部固定栏（如确定按钮）
  final Widget? bottomBar;

  /// 底部安全区域高度（底部栏下方留空，默认 true）
  final bool useBottomSafeArea;

  /// 顶部安全区域（默认 true）
  final bool useTopSafeArea;

  /// 导航栏背景色
  final Color? appBarBackgroundColor;

  /// 导航栏前景色
  final Color? appBarForegroundColor;

  /// 页面背景色
  final Color? backgroundColor;

  /// 主体内容内边距
  final EdgeInsetsGeometry? bodyPadding;

  /// 是否在底部栏上方添加分割线
  final bool showBottomBarDivider;

  /// 自定义 AppBar（替换默认构建逻辑）
  final PreferredSizeWidget? customAppBar;

  /// 是否启用滚动（默认 true，自动包裹 SingleChildScrollView）
  /// 如果 body 内部已包含滚动组件，设为 false
  final bool enableScroll;

  /// 滚动控制器
  final ScrollController? scrollController;

  /// 导航栏是否透明（内容可穿透）
  final bool transparentAppBar;

  const AppScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.showBack = true,
    this.onBack,
    this.actions,
    this.bottomBar,
    this.useBottomSafeArea = true,
    this.useTopSafeArea = true,
    this.appBarBackgroundColor,
    this.appBarForegroundColor,
    this.backgroundColor,
    this.bodyPadding,
    this.showBottomBarDivider = true,
    this.customAppBar,
    this.enableScroll = true,
    this.scrollController,
    this.transparentAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = backgroundColor ??
        (isDark ? const Color(0xFF000000) : AppColors.background);
    final Color appBarBg = appBarBackgroundColor ??
        (transparentAppBar
            ? Colors.transparent
            : (isDark ? const Color(0xFF1C1C1E) : AppColors.surface));
    final Color appBarFg = appBarForegroundColor ??
        (isDark ? const Color(0xFFF5F5F7) : AppColors.textPrimary);
    final EdgeInsetsGeometry contentPadding = bodyPadding ??
        EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.sm,
          bottom: bottomBar != null ? AppSpacing.lg : AppSpacing.lg,
        );

    return Scaffold(
      backgroundColor: bg,
      appBar: customAppBar ??
          (transparentAppBar
              ? _buildTransparentAppBar(context, appBarFg)
              : _buildStandardAppBar(context, appBarBg, appBarFg)),
      body: SafeArea(
        top: useTopSafeArea,
        bottom: false,
        child: Column(
          children: [
            // 可滚动主体内容
            Expanded(
              child: enableScroll
                  ? SingleChildScrollView(
                      controller: scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: contentPadding,
                      child: body,
                    )
                  : Padding(
                      padding: contentPadding,
                      child: body,
                    ),
            ),

            // 底部操作栏
            if (bottomBar != null) ...[
              if (showBottomBarDivider)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: isDark
                      ? const Color(0xFF38383A)
                      : AppColors.divider,
                ),
              SafeArea(
                top: false,
                bottom: useBottomSafeArea,
                minimum: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.md,
                ),
                child: bottomBar,
              ),
            ],
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildStandardAppBar(
    BuildContext context,
    Color bg,
    Color fg,
  ) {
    return AppBar(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      title: subtitle != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.h3Style.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle!,
                  style: AppTypography.captionStyle.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: AppTypography.h3Style.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: onBack ?? () => Navigator.maybePop(context),
            )
          : null,
      actions: actions,
      surfaceTintColor: Colors.transparent,
    );
  }

  PreferredSizeWidget _buildTransparentAppBar(
    BuildContext context,
    Color fg,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: fg,
      elevation: 0,
      centerTitle: true,
      title: Text(
        title,
        style: AppTypography.h3Style.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: onBack ?? () => Navigator.maybePop(context),
            )
          : null,
      actions: actions,
      surfaceTintColor: Colors.transparent,
    );
  }
}
