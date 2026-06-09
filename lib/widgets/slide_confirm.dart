import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 滑动确认控件
///
/// 遵循胰岛素泵医疗App设计规范（参考 `15滑动确认.png` 118KB 大文件设计）：
/// - 用于高安全操作（如大剂量输注确认、暂停泵、取消操作等）
/// - 用户必须将滑块从左侧拖拽至右侧完成确认
/// - 触控区域 ≥ 48px
///
/// 这是胰岛素泵的关键安全交互组件，遵循 IEC 62366 医疗器械可用性工程规范。
///
/// 使用示例：
/// ```dart
/// SlideConfirm(
///   label: '滑动确认输注',
///   onConfirmed: () => _startInfusion(),
/// )
/// ```
class SlideConfirm extends StatefulWidget {
  /// 滑块上的提示文字
  final String label;

  /// 确认完成后的回调
  final VoidCallback onConfirmed;

  /// 滑块图标
  final IconData thumbIcon;

  /// 滑块轨道颜色（默认主蓝色）
  final Color? trackColor;

  /// 确认后的颜色（默认成功绿色）
  final Color? completedColor;

  /// 滑块高度
  final double height;

  /// 是否禁用
  final bool disabled;

  const SlideConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.thumbIcon = Icons.chevron_right,
    this.trackColor,
    this.completedColor,
    this.height = AppSpacing.sliderHeight,
    this.disabled = false,
  });

  @override
  State<SlideConfirm> createState() => _SlideConfirmState();
}

class _SlideConfirmState extends State<SlideConfirm>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  // 拖拽百分比 (0.0 ~ 1.0)
  double _dragFraction = 0.0;
  bool _isCompleted = false;
  bool _isDragging = false;

  // 滑块宽度占轨道比例
  static const double _thumbRatio = 0.2;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    // 监听动画完成
    _animController.addListener(() {
      if (_animController.isCompleted && !_isCompleted) {
        _onComplete();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onComplete() {
    setState(() => _isCompleted = true);
    widget.onConfirmed();

    // 延迟重置
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCompleted = false;
          _dragFraction = 0.0;
          _animController.reset();
        });
      }
    });
  }

  void _reset() {
    _animController.reverse();
    setState(() => _dragFraction = 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _buildCompleted();
    }

    return _buildSlider();
  }

  Widget _buildCompleted() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.completedColor ?? AppColors.success,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '已确认',
              style: AppTypography.buttonStyle.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider() {
    final Color trackBg = widget.trackColor ?? AppColors.primary;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color trackBgDim = trackBg.withValues(alpha: 0.3);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double trackWidth = constraints.maxWidth;
        final double thumbSize = trackWidth * _thumbRatio;
        final double maxDrag = trackWidth - thumbSize;

        // 当前滑块位置（根据拖拽或动画状态）
        double currentOffset;
        if (_animController.isAnimating) {
          currentOffset = _slideAnimation.value * maxDrag;
        } else {
          currentOffset = _dragFraction * maxDrag;
        }

        return GestureDetector(
          onPanStart: widget.disabled
              ? null
              : (_) {
                  setState(() => _isDragging = true);
                },
          onPanUpdate: widget.disabled
              ? null
              : (details) {
                  final double newFraction =
                      (currentOffset + details.delta.dx) / maxDrag;
                  setState(() {
                    _dragFraction = newFraction.clamp(0.0, 1.0);
                  });
                },
          onPanEnd: widget.disabled
              ? null
              : (details) {
                  setState(() => _isDragging = false);
                  if (_dragFraction >= 0.95) {
                    // 超过 95% 自动完成
                    _animController.forward();
                  } else {
                    // 回弹到起点
                    _reset();
                  }
                },
          onPanCancel: widget.disabled ? null : _reset,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2C2C2E)
                  : AppColors.disabledBackground,
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              border: Border.all(
                color: trackBgDim,
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // 轨道填充进度
                FractionallySizedBox(
                  widthFactor: _dragFraction.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: trackBg.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.buttonRadius - 1,
                      ),
                    ),
                  ),
                ),

                // 提示文字
                Center(
                  child: Opacity(
                    opacity: _isDragging
                        ? (1.0 - _dragFraction).clamp(0.0, 1.0)
                        : 1.0,
                    child: Text(
                      widget.label,
                      style: AppTypography.bodySmallStyle.copyWith(
                        color: isDark
                            ? const Color(0xFFAEAEB2)
                            : AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // 可拖拽滑块
                Positioned(
                  left: currentOffset,
                  top: 2,
                  bottom: 2,
                  child: Container(
                    width: thumbSize - 4,
                    decoration: BoxDecoration(
                      color: widget.disabled
                          ? AppColors.disabledText
                          : trackBg,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.buttonRadius - 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: trackBg.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.thumbIcon,
                        color: AppColors.textOnPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
