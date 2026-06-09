import 'package:insulin_app/models/models.dart';

/// 活性胰岛素 (IOB) 追踪器
/// 基于胰岛素药代动力学，采用线性衰减模型
///
/// 速效胰岛素：活性持续约4小时
/// 短效胰岛素：活性持续约6小时
class IOBActivityTracker {
  /// 计算当前活性胰岛素总量
  /// [previousDoses] 过去一段时间内的注射记录
  /// [currentTime] 当前时间
  /// [durationHours] 活性持续时间（小时）
  static double calculateIOB({
    required List<InsulinDose> previousDoses,
    required DateTime currentTime,
    int durationHours = 4,
  }) {
    if (previousDoses.isEmpty) return 0.0;

    double totalIOB = 0.0;

    for (final dose in previousDoses) {
      // 计算注射后的分钟数
      final minutesSinceDose = currentTime.difference(dose.timestamp).inMinutes;

      // 如果注射时间还在未来，跳过
      if (minutesSinceDose < 0) continue;

      // 如果已经超过活性时长，完全衰减
      final activeMinutes = durationHours * 60;
      if (minutesSinceDose >= activeMinutes) continue;

      // 线性衰减计算
      // t=0 时 IOB = 100% 剂量
      // t=activeMinutes 时 IOB = 0%
      final remaining = 1.0 - (minutesSinceDose / activeMinutes);
      final iobFromDose = dose.units * remaining;
      totalIOB += iobFromDose;
    }

    return totalIOB;
  }

  /// 计算衰减曲线上的某一点
  /// 返回 0.0 ~ 1.0 之间的剩余比例
  static double remainingFraction({
    required DateTime doseTime,
    required DateTime currentTime,
    required int durationHours,
  }) {
    final minutesSinceDose = currentTime.difference(doseTime).inMinutes;
    if (minutesSinceDose <= 0) return 1.0;

    final activeMinutes = durationHours * 60;
    if (minutesSinceDose >= activeMinutes) return 0.0;

    return 1.0 - (minutesSinceDose / activeMinutes);
  }

  /// 获取IOB详细分解（调试和展示用）
  static List<Map<String, dynamic>> getIOBDetail({
    required List<InsulinDose> previousDoses,
    required DateTime currentTime,
    required int durationHours,
  }) {
    final details = <Map<String, dynamic>>[];

    for (final dose in previousDoses) {
      final fraction = remainingFraction(
        doseTime: dose.timestamp,
        currentTime: currentTime,
        durationHours: durationHours,
      );

      if (fraction > 0) {
        details.add({
          'dose': dose.units,
          'time': dose.timestamp,
          'remaining': dose.units * fraction,
          'fraction': fraction,
        });
      }
    }

    return details;
  }
}
