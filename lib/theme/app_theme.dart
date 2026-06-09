import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// 胰岛素泵医疗App — 完整主题配置
///
/// 提供 Material 3 主题数据，包含：
/// - 颜色方案（浅色/深色）
/// - 文字主题（全字号层级）
/// - 控件主题（按钮、卡片、列表、输入框、底部导航等）
///
/// 使用方式：
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
///   themeMode: ThemeMode.system,
/// )
/// ```
class AppTheme {
  AppTheme._();

  /// ──────────────────────────────────────────────
  /// 浅色主题
  /// ──────────────────────────────────────────────
  static ThemeData get light => _buildLight();

  /// ──────────────────────────────────────────────
  /// 深色主题
  /// ──────────────────────────────────────────────
  static ThemeData get dark => _buildDark();

  // ──────────────────────────────────────────────
  // 构建浅色主题
  // ──────────────────────────────────────────────
  static ThemeData _buildLight() {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.primary,
      onSecondary: AppColors.textOnPrimary,
      secondaryContainer: AppColors.primaryLight,
      onSecondaryContainer: AppColors.primaryDark,
      tertiary: AppColors.info,
      onTertiary: AppColors.textOnPrimary,
      error: AppColors.danger,
      onError: AppColors.textOnPrimary,
      errorContainer: AppColors.dangerLight,
      onErrorContainer: AppColors.danger,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.divider,
      outlineVariant: AppColors.dividerLight,
      shadow: Colors.black.withValues(alpha: 0.08),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,

      // ── 文字主题 ──
      textTheme: TextTheme(
        displayLarge: AppTypography.giantLargeStyle.copyWith(
          color: AppColors.textPrimary,
        ),
        displayMedium: AppTypography.giantStyle.copyWith(
          color: AppColors.textPrimary,
        ),
        headlineLarge: AppTypography.h1Style.copyWith(
          color: AppColors.textPrimary,
        ),
        headlineMedium: AppTypography.h2Style.copyWith(
          color: AppColors.textPrimary,
        ),
        headlineSmall: AppTypography.h3Style.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyLarge: AppTypography.bodyStyle.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyMedium: AppTypography.bodySmallStyle.copyWith(
          color: AppColors.textSecondary,
        ),
        bodySmall: AppTypography.captionStyle.copyWith(
          color: AppColors.textTertiary,
        ),
        labelLarge: AppTypography.buttonStyle.copyWith(
          color: AppColors.textOnPrimary,
        ),
        labelMedium: AppTypography.buttonSmallStyle.copyWith(
          color: AppColors.textSecondary,
        ),
        labelSmall: AppTypography.overlineStyle.copyWith(
          color: AppColors.textTertiary,
        ),
      ),

      // ── AppBar 主题 ──
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: AppTypography.h3Style.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.primary,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.primary,
          size: 24,
        ),
      ),

      // ── 底部导航栏 ──
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.captionStyle.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.captionStyle.copyWith(
            color: AppColors.textTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.primary,
              size: 24,
            );
          }
          return const IconThemeData(
            color: AppColors.textTertiary,
            size: 24,
          );
        }),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        surfaceTintColor: Colors.transparent,
      ),

      // ── 卡片主题 ──
      cardTheme: CardTheme(
        elevation: 0,
        color: AppColors.surface,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),

      // ── ElevatedButton 主题（主按钮） ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.disabledBackground,
          disabledForegroundColor: AppColors.disabledText,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          padding: AppSpacing.buttonHorizontal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTypography.buttonStyle.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
      ),

      // ── OutlinedButton 主题（次按钮） ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.disabledText,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          padding: AppSpacing.buttonHorizontal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTypography.buttonStyle.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),

      // ── TextButton 主题 ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.disabledText,
          minimumSize: const Size(0, AppSpacing.minTouchArea),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          textStyle: AppTypography.buttonStyle.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),

      // ── 输入框主题 ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        hintStyle: AppTypography.bodyStyle.copyWith(
          color: AppColors.textTertiary,
        ),
        labelStyle: AppTypography.bodyStyle.copyWith(
          color: AppColors.textSecondary,
        ),
        errorStyle: AppTypography.captionStyle.copyWith(
          color: AppColors.danger,
        ),
      ),

      // ── 开关主题 ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.3);
          }
          return AppColors.disabledBackground;
        }),
      ),

      // ── 复选框主题 ──
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.resolveWith((states) {
          return AppColors.textOnPrimary;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: const BorderSide(color: AppColors.textTertiary, width: 1.5),
      ),

      // ── 单选按钮主题 ──
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textTertiary;
        }),
      ),

      // ── 滑块主题 ──
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.12),
        valueIndicatorColor: AppColors.primary,
        valueIndicatorTextStyle: AppTypography.bodySmallStyle.copyWith(
          color: AppColors.textOnPrimary,
        ),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),

      // ── 对话框主题 ──
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        titleTextStyle: AppTypography.h3Style.copyWith(
          color: AppColors.textPrimary,
        ),
        contentTextStyle: AppTypography.bodyStyle.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // ── 底部弹出框主题 ──
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadius),
          ),
        ),
        dragHandleColor: AppColors.divider,
        dragHandleSize: Size(32, 4),
      ),

      // ── 分割线主题 ──
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.5,
        space: 0,
      ),

      // ── 进度指示器 ──
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryLight,
        linearMinHeight: 4,
      ),

      // ── 提示气泡 Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        disabledColor: AppColors.disabledBackground,
        selectedColor: AppColors.primaryLight,
        secondarySelectedColor: AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        labelStyle: AppTypography.bodySmallStyle,
        secondaryLabelStyle: AppTypography.bodySmallStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
      ),

      // ── 浮动操作按钮 ──
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ── 弹出菜单 ──
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
        ),
        textStyle: AppTypography.bodyStyle.copyWith(
          color: AppColors.textPrimary,
        ),
      ),

      // ── 工具提示 ──
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTypography.captionStyle.copyWith(
          color: AppColors.textOnPrimary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // 构建深色主题
  // ──────────────────────────────────────────────
  static ThemeData _buildDark() {
    final colorScheme = ColorScheme.dark(
      primary: const Color(0xFF0A84FF),
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: const Color(0xFF003366),
      onPrimaryContainer: const Color(0xFF99CCFF),
      secondary: const Color(0xFF0A84FF),
      onSecondary: AppColors.textOnPrimary,
      secondaryContainer: const Color(0xFF003366),
      onSecondaryContainer: const Color(0xFF99CCFF),
      tertiary: const Color(0xFF64D2FF),
      onTertiary: const Color(0xFF003549),
      error: const Color(0xFFFF453A),
      onError: AppColors.textOnPrimary,
      errorContainer: const Color(0xFF4D0000),
      onErrorContainer: const Color(0xFFFFD6D6),
      surface: const Color(0xFF1C1C1E),
      onSurface: const Color(0xFFF5F5F7),
      onSurfaceVariant: const Color(0xFFAEAEB2),
      outline: const Color(0xFF38383A),
      outlineVariant: const Color(0xFF2C2C2E),
      shadow: Colors.black.withValues(alpha: 0.3),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF000000),

      textTheme: TextTheme(
        displayLarge: AppTypography.giantLargeStyle.copyWith(
          color: const Color(0xFFF5F5F7),
        ),
        displayMedium: AppTypography.giantStyle.copyWith(
          color: const Color(0xFFF5F5F7),
        ),
        headlineLarge: AppTypography.h1Style.copyWith(
          color: const Color(0xFFF5F5F7),
        ),
        headlineMedium: AppTypography.h2Style.copyWith(
          color: const Color(0xFFF5F5F7),
        ),
        headlineSmall: AppTypography.h3Style.copyWith(
          color: const Color(0xFFF5F5F7),
        ),
        bodyLarge: AppTypography.bodyStyle.copyWith(
          color: const Color(0xFFF5F5F7),
        ),
        bodyMedium: AppTypography.bodySmallStyle.copyWith(
          color: const Color(0xFFAEAEB2),
        ),
        bodySmall: AppTypography.captionStyle.copyWith(
          color: const Color(0xFF636366),
        ),
        labelLarge: AppTypography.buttonStyle.copyWith(
          color: AppColors.textOnPrimary,
        ),
        labelMedium: AppTypography.buttonSmallStyle.copyWith(
          color: const Color(0xFFAEAEB2),
        ),
        labelSmall: AppTypography.overlineStyle.copyWith(
          color: const Color(0xFF636366),
        ),
      ),

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: const Color(0xFF1C1C1E),
        foregroundColor: const Color(0xFFF5F5F7),
        titleTextStyle: AppTypography.h3Style.copyWith(
          color: const Color(0xFFF5F5F7),
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF0A84FF),
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: Color(0xFF0A84FF),
          size: 24,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: const Color(0xFF1C1C1E),
        indicatorColor: const Color(0xFF003366),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.captionStyle.copyWith(
              color: const Color(0xFF0A84FF),
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.captionStyle.copyWith(
            color: const Color(0xFF636366),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: Color(0xFF0A84FF),
              size: 24,
            );
          }
          return const IconThemeData(
            color: Color(0xFF636366),
            size: 24,
          );
        }),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardTheme(
        elevation: 0,
        color: const Color(0xFF2C2C2E),
        shadowColor: Colors.black.withValues(alpha: 0.3),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A84FF),
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: const Color(0xFF38383A),
          disabledForegroundColor: const Color(0xFF636366),
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          padding: AppSpacing.buttonHorizontal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTypography.buttonStyle.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0A84FF),
          disabledForegroundColor: const Color(0xFF636366),
          side: const BorderSide(color: Color(0xFF0A84FF), width: 1.5),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          padding: AppSpacing.buttonHorizontal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTypography.buttonStyle.copyWith(
            color: const Color(0xFF0A84FF),
          ),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFF38383A),
        thickness: 0.5,
        space: 0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: Color(0xFF38383A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: Color(0xFF38383A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: Color(0xFF0A84FF), width: 2),
        ),
        hintStyle: AppTypography.bodyStyle.copyWith(
          color: const Color(0xFF636366),
        ),
        labelStyle: AppTypography.bodyStyle.copyWith(
          color: const Color(0xFFAEAEB2),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF0A84FF),
        linearTrackColor: Color(0xFF003366),
        linearMinHeight: 4,
      ),

      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF2C2C2E),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        titleTextStyle: AppTypography.h3Style.copyWith(
          color: const Color(0xFFF5F5F7),
        ),
        contentTextStyle: AppTypography.bodyStyle.copyWith(
          color: const Color(0xFFAEAEB2),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF2C2C2E),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadius),
          ),
        ),
        dragHandleColor: Color(0xFF38383A),
        dragHandleSize: Size(32, 4),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFF0A84FF),
        inactiveTrackColor: const Color(0xFF0A84FF).withValues(alpha: 0.2),
        thumbColor: const Color(0xFF0A84FF),
        overlayColor: const Color(0xFF0A84FF).withValues(alpha: 0.12),
        valueIndicatorColor: const Color(0xFF0A84FF),
        valueIndicatorTextStyle: AppTypography.bodySmallStyle.copyWith(
          color: AppColors.textOnPrimary,
        ),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF0A84FF),
        foregroundColor: AppColors.textOnPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),
    );
  }
}

/// 便捷扩展：在 BuildContext 上快速访问主题
extension ThemeContextExtension on BuildContext {
  /// 主题颜色方案
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// 是否深色模式
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// 主题间距规范
  // ignore: use_full_import
  AppSpacing get spacing => AppSpacing;
}
