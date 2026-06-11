import 'package:glucare_app/database/local_db.dart';
import 'package:glucare_app/models/models.dart';

/// 报告生成器 — 病情总结、用药调整建议
class ReportGenerator {
  final AppDatabase _db = AppDatabase();

  /// 生成病情总结文本
  /// [days] 统计天数（7/14/30）
  Future<String> generateSummary(int days) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final config = await _db.getConfig();

    final buffer = StringBuffer();
    buffer.writeln('📋 病情总结报告');
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln('统计周期: 近 $days 天');
    buffer.writeln('患者: ${config.patientName.isNotEmpty ? config.patientName : "未设置"}');
    buffer.writeln('糖尿病类型: ${config.diabetesType == 1 ? "1型" : "2型"}');
    buffer.writeln('用药方案: ${config.medicationRegimen}');
    buffer.writeln('目标血糖: ${config.targetGlucoseMin} - ${config.targetGlucoseMax} mmol/L');
    buffer.writeln('');

    // 血糖统计
    final records = await _db.getGlucoseRecords(startDate: startDate, endDate: now);
    final doses = await _db.getDoses(startDate: startDate, endDate: now);

    if (records.isNotEmpty) {
      final values = records.map((r) => r.glucose).toList();
      final avg = values.reduce((a, b) => a + b) / values.length;
      final min = values.reduce((a, b) => a < b ? a : b);
      final max = values.reduce((a, b) => a > b ? a : b);

      final lowCount = values.where((v) => v < 3.9).length;
      final highCount = values.where((v) => v > config.targetGlucoseMax).length;
      final inRangeCount = values.length - lowCount - highCount;
      final tir = (inRangeCount / values.length * 100).toStringAsFixed(1);

      buffer.writeln('📊 血糖统计');
      buffer.writeln('  测量次数: ${records.length}');
      buffer.writeln('  平均血糖: ${avg.toStringAsFixed(1)} mmol/L');
      buffer.writeln('  最低血糖: ${min.toStringAsFixed(1)} mmol/L');
      buffer.writeln('  最高血糖: ${max.toStringAsFixed(1)} mmol/L');
      buffer.writeln('  目标范围内时间(TIR): $tir%');
      buffer.writeln('  低血糖(<3.9): $lowCount 次');
      buffer.writeln('  高血糖(>${config.targetGlucoseMax}): $highCount 次');
      buffer.writeln('');
    } else {
      buffer.writeln('📊 血糖统计: 暂无数据');
      buffer.writeln('');
    }

    // 用药统计
    if (doses.isNotEmpty) {
      final totalUnits = doses.fold<double>(0, (sum, d) => sum + d.units);
      final avgDaily = (totalUnits / days).toStringAsFixed(1);

      buffer.writeln('💉 用药统计');
      buffer.writeln('  注射次数: ${doses.length}');
      buffer.writeln('  总剂量: ${totalUnits.toStringAsFixed(1)} U');
      buffer.writeln('  日均剂量: $avgDaily U/天');
      buffer.writeln('');

      // 按类型统计
      final mealDoses = doses.where((d) => d.tag == DoseTag.meal);
      final correctionDoses = doses.where((d) => d.tag == DoseTag.correction);
      final basalDoses = doses.where((d) => d.tag == DoseTag.basal);

      if (mealDoses.isNotEmpty) {
        final mealTotal = mealDoses.fold<double>(0, (s, d) => s + d.units);
        buffer.writeln('  餐时胰岛素: ${mealTotal.toStringAsFixed(1)} U');
      }
      if (correctionDoses.isNotEmpty) {
        final corrTotal = correctionDoses.fold<double>(0, (s, d) => s + d.units);
        buffer.writeln('  校正胰岛素: ${corrTotal.toStringAsFixed(1)} U');
      }
      if (basalDoses.isNotEmpty) {
        final basalTotal = basalDoses.fold<double>(0, (s, d) => s + d.units);
        buffer.writeln('  基础胰岛素: ${basalTotal.toStringAsFixed(1)} U');
      }
      buffer.writeln('');
    } else {
      buffer.writeln('💉 用药统计: 暂无数据');
      buffer.writeln('');
    }

    // 用药打卡统计
    final medStats = await _db.getTodayMedicationStats();
    buffer.writeln('💊 今日用药打卡');
    buffer.writeln('  完成率: ${((medStats['completionRate'] as double? ?? 0) * 100).toStringAsFixed(0)}%');
    buffer.writeln('  已服: ${medStats['taken']} / 漏服: ${medStats['missed']} / 待服: ${medStats['pending']}');
    buffer.writeln('');

    return buffer.toString();
  }

  /// 生成用药方案调整建议
  Future<String> generateAdjustmentSuggestions(int days) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final config = await _db.getConfig();
    final records = await _db.getGlucoseRecords(startDate: startDate, endDate: now);

    final buffer = StringBuffer();
    buffer.writeln('📝 用药方案调整建议');
    buffer.writeln('━━━━━━━━━━━━━━━━');

    if (records.isEmpty) {
      buffer.writeln('数据不足，无法生成建议。请继续记录血糖和用药数据。');
      return buffer.toString();
    }

    // 按日期分组分析血糖模式
    final dayGroups = <DateTime, List<GlucoseRecord>>{};
    for (final r in records) {
      final day = DateTime(r.timestamp.year, r.timestamp.month, r.timestamp.day);
      dayGroups.putIfAbsent(day, () => []).add(r);
    }

    // 分析空腹血糖
    final fastingValues = records
        .where((r) => r.tag == GlucoseTag.fasting)
        .map((r) => r.glucose)
        .toList();

    if (fastingValues.isNotEmpty) {
      final avgFasting =
          fastingValues.reduce((a, b) => a + b) / fastingValues.length;
      buffer.writeln('空腹血糖均值: ${avgFasting.toStringAsFixed(1)} mmol/L');

      if (avgFasting > config.targetGlucoseMax) {
        buffer.writeln('  ➡️ 建议：空腹血糖偏高，可考虑增加基础胰岛素剂量或调整睡前用药。');
      } else if (avgFasting < config.targetGlucoseMin) {
        buffer.writeln('  ➡️ 建议：空腹血糖偏低，夜间低血糖风险增加，建议减少基础胰岛素。');
      } else {
        buffer.writeln('  ✅ 空腹血糖控制良好。');
      }
      buffer.writeln('');
    }

    // 分析餐后血糖
    final postMealValues = records
        .where((r) => r.tag == GlucoseTag.postMeal)
        .map((r) => r.glucose)
        .toList();

    if (postMealValues.isNotEmpty) {
      final avgPostMeal =
          postMealValues.reduce((a, b) => a + b) / postMealValues.length;
      buffer.writeln('餐后血糖均值: ${avgPostMeal.toStringAsFixed(1)} mmol/L');

      if (avgPostMeal > 10.0) {
        buffer.writeln('  ➡️ 建议：餐后血糖偏高（>10.0），可考虑增加餐时胰岛素剂量或提前注射时间。');
      } else if (avgPostMeal > config.targetGlucoseMax) {
        buffer.writeln('  ➡️ 建议：餐后血糖略高，可微调餐时胰岛素剂量或减少碳水摄入。');
      } else {
        buffer.writeln('  ✅ 餐后血糖控制良好。');
      }
      buffer.writeln('');
    }

    // 低血糖分析
    final lowRecords = records.where((r) => r.glucose < 3.9).length;
    if (lowRecords >= 3) {
      buffer.writeln('⚠️ 低血糖频率较高（${lowRecords}次），建议：');
      buffer.writeln('  - 减少餐时胰岛素剂量 1-2U');
      buffer.writeln('  - 增加餐间加餐');
      buffer.writeln('  - 睡前血糖 < 6.0 mmol/L 时补充碳水');
      buffer.writeln('');
    }

    // 时间在范围(TIR)分析
    final total = records.length;
    final inRange = records
        .where((r) =>
            r.glucose >= config.targetGlucoseMin &&
            r.glucose <= config.targetGlucoseMax)
        .length;
    final tir = inRange / total * 100;

    buffer.writeln('目标范围时间(TIR): ${tir.toStringAsFixed(1)}%');
    if (tir >= 70) {
      buffer.writeln('  ✅ TIR > 70%，控制达标，维持当前方案。');
    } else if (tir >= 50) {
      buffer.writeln('  ⚠️ TIR 在 50-70% 之间，建议微调用药方案。');
    } else {
      buffer.writeln('  ❌ TIR < 50%，建议尽快咨询医生调整整体治疗方案。');
    }
    buffer.writeln('');

    buffer.writeln('📌 温馨提示');
    buffer.writeln('  本建议仅供参考，具体用药调整请咨询您的主治医生。');
    buffer.writeln('  建议定期复查糖化血红蛋白(HbA1c)，评估长期血糖控制效果。');

    return buffer.toString();
  }

  /// 获取开药提醒列表（基于血糖数据）
  Future<List<String>> getRefillReminders() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final records = await _db.getGlucoseRecords(
      startDate: sevenDaysAgo,
      endDate: now,
    );
    final config = await _db.getConfig();

    final reminders = <String>[];

    // 持续高血糖提醒
    final highDays = <DateTime>{};
    for (final r in records) {
      if (r.tag == GlucoseTag.fasting && r.glucose > 7.0) {
        highDays.add(DateTime(r.timestamp.year, r.timestamp.month, r.timestamp.day));
      }
    }
    if (highDays.length >= 3) {
      reminders.add('⚠️ 近7天有${highDays.length}天空腹血糖偏高(>7.0mmol/L)，建议联系医生调整用药方案。');
    }

    // 低血糖风险
    final lowCount = records.where((r) => r.glucose < 3.9).length;
    if (lowCount >= 2) {
      reminders.add('⚠️ 近7天发生${lowCount}次低血糖(<3.9mmol/L)，请关注是否用药过量。');
    }

    // 高血糖趋势
    final recentGlucose =
        records.where((r) => r.glucose > config.targetGlucoseMax).length;
    if (records.isNotEmpty && recentGlucose / records.length > 0.5) {
      reminders.add('📈 近期超过50%的测量值高于目标范围，建议优化用药方案。');
    }

    return reminders;
  }
}
