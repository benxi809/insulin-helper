import 'package:insulin_app/models/models.dart';

/// 剂量计算结果
class DoseResult {
  final double foodDose; // 食物覆盖剂量
  final double correctionDose; // 校正剂量
  final double totalDose; // 总剂量
  final double iob; // 本次扣除的活性胰岛素
  final double targetGlucose; // 目标血糖（取上限）
  final bool isSafe;
  final String? warning;

  DoseResult({
    required this.foodDose,
    required this.correctionDose,
    required this.totalDose,
    required this.iob,
    required this.targetGlucose,
    this.isSafe = true,
    this.warning,
  });

  @override
  String toString() {
    return '食物覆盖: ${foodDose.toStringAsFixed(1)}U · '
        '校正: ${correctionDose.toStringAsFixed(1)}U · '
        '扣除IOB: ${iob.toStringAsFixed(1)}U · '
        '合计: ${totalDose.toStringAsFixed(1)}U';
  }
}

/// 剂量计算器
/// 基于标准碳水化合物计数法：
/// 总剂量 = (当前血糖 - 目标血糖) / ISF + 碳水 / ICR - IOB
class DoseCalculator {
  /// 计算餐前追加剂量
  /// [currentGlucose] 当前血糖 (mmol/L)
  /// [carbs] 计划摄入碳水 (g)
  /// [config] 用户配置
  /// [iob] 当前活性胰岛素 (U)
  /// [previousGlucose] 上一次餐后血糖（用于二次校正，可选）
  static DoseResult calculateBolus({
    required double currentGlucose,
    required double carbs,
    required UserConfig config,
    double iob = 0.0,
    double? previousGlucose,
  }) {
    final targetGlucose = config.targetGlucoseMax;

    // 1. 计算校正剂量
    double correctionDose = 0.0;
    if (currentGlucose > targetGlucose) {
      correctionDose = (currentGlucose - targetGlucose) / config.isf;
    } else if (currentGlucose < config.targetGlucoseMin) {
      // 血糖低于目标下限，需要减剂量
      correctionDose = (currentGlucose - targetGlucose) / config.isf;
      // 已经是负数
    }

    // 2. 计算食物覆盖剂量
    double foodDose = carbs / config.icr;

    // 3. 计算总剂量（并扣除IOB）
    double totalDose = foodDose + correctionDose - iob;

    // 4. 如果结果小于0，取0（不推荐负注射）
    if (totalDose < 0) {
      totalDose = 0;
    }

    // 返回结果
    return DoseResult(
      foodDose: foodDose,
      correctionDose: correctionDose,
      totalDose: totalDose,
      iob: iob,
      targetGlucose: targetGlucose,
      isSafe: true,
    );
  }

  /// 根据TDD（每日总剂量）计算建议的ISF
  /// 基于1800/1500法则
  static double suggestedISF(double tdd, InsulinType type) {
    if (tdd <= 0) return 2.5; // 默认值
    // 1800法则以 mg/dL 为单位，除以18转为 mmol/L
    return type.isfFormulaBase / (tdd * 18);
  }

  /// 根据TDD计算建议的ICR
  /// 基于500/450法则
  static double suggestedICR(double tdd, InsulinType type) {
    if (tdd <= 0) return 12.0; // 默认值
    return type.icrFormulaBase / tdd;
  }

  /// 根据体重估算初始TDD
  /// [weightKg] 体重(kg)
  /// [isType1] 是否为1型糖尿病
  static double estimateTDD(double weightKg, {bool isType1 = true}) {
    if (isType1) {
      return weightKg * 0.4; // 1型：0.3-0.5 U/kg，取中间值
    } else {
      return weightKg * 0.15; // 2型：0.1-0.2 U/kg，取中间值
    }
  }
}
