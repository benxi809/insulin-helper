
/// 安全等级
enum SafetyLevel {
  safe, // 安全
  warning, // 警告
  danger, // 危险
}

/// 安全检查结果
class SafetyResult {
  final bool allow;
  final SafetyLevel level;
  final String? message;
  final String? action;

  SafetyResult({
    required this.allow,
    required this.level,
    this.message,
    this.action,
  });

  /// 危险状态 - 禁止
  factory SafetyResult.danger(String message, {String? action}) {
    return SafetyResult(
      allow: false,
      level: SafetyLevel.danger,
      message: message,
      action: action,
    );
  }

  /// 警告状态 - 允许但提醒
  factory SafetyResult.warning(String message) {
    return SafetyResult(
      allow: true,
      level: SafetyLevel.warning,
      message: message,
    );
  }

  /// 安全状态
  factory SafetyResult.safe() {
    return SafetyResult(
      allow: true,
      level: SafetyLevel.safe,
    );
  }
}

/// 安全检查器
/// 在剂量计算前后进行多项安全检查
class SafetyChecker {
  /// 计算前的安全检查
  /// 检查当前血糖是否处于安全范围
  static SafetyResult preCheck({
    required double glucose,
    bool hasKetones = false,
  }) {
    // 1. 低血糖检查
    if (glucose < 3.9) {
      return SafetyResult.danger(
        '当前血糖 ${glucose.toStringAsFixed(1)} mmol/L，已低于 3.9（低血糖警戒线）',
        action: '请立即摄入 15g 速效糖类（果汁、葡萄糖片等），15分钟后复测',
      );
    }

    if (glucose < 4.5) {
      return SafetyResult.warning(
        '血糖偏低（${glucose.toStringAsFixed(1)} mmol/L），建议先少量进食后再考虑注射胰岛素',
      );
    }

    // 2. 高血糖伴酮体检查
    if (glucose > 13.9 && hasKetones) {
      return SafetyResult.danger(
        '血糖 > 13.9 且伴有酮体阳性，有酮症酸中毒（DKA）风险',
        action: '请立即联系医生或前往急诊，不要自行追加胰岛素',
      );
    }

    // 3. 单纯高血糖提醒
    if (glucose > 13.9) {
      return SafetyResult.warning(
        '血糖偏高（${glucose.toStringAsFixed(1)} mmol/L），建议检测血酮/尿酮。连续两次 > 13.9 请就医',
      );
    }

    return SafetyResult.safe();
  }

  /// 计算后的剂量安全检查
  static SafetyResult postCheck({
    required double calculatedDose,
    required double maxDosePerInjection,
  }) {
    if (calculatedDose <= 0) {
      return SafetyResult.warning(
        '计算剂量为 0 U，当前血糖和目标血糖匹配，无需追加胰岛素。如果计划进食，请确认碳水值输入是否正确',
      );
    }

    if (calculatedDose > maxDosePerInjection) {
      return SafetyResult.danger(
        '计算剂量 ${calculatedDose.toStringAsFixed(1)}U 已超过单次最大剂量上限 ${maxDosePerInjection.toStringAsFixed(1)}U',
        action: '请确认后手动调整，或咨询医生',
      );
    }

    if (calculatedDose > 10) {
      return SafetyResult.warning(
        '单次剂量 ${calculatedDose.toStringAsFixed(1)}U 较大，请确认计算参数无误',
      );
    }

    return SafetyResult.safe();
  }

  /// 综合剂量检查（pre + post）
  static SafetyResult fullCheck({
    required double glucose,
    required double calculatedDose,
    required double maxDosePerInjection,
    bool hasKetones = false,
  }) {
    // 先做预检
    final pre = preCheck(glucose: glucose, hasKetones: hasKetones);
    if (!pre.allow) return pre;

    // 再做剂量检查
    return postCheck(
      calculatedDose: calculatedDose,
      maxDosePerInjection: maxDosePerInjection,
    );
  }
}
