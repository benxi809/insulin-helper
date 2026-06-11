import 'dart:math' as math;
import 'package:glucare_app/models/models.dart';

/// 基础率估算结果
class BasalProfile {
  final List<BasalSegment> segments; // 24小时分段基础率
  final double totalDailyBasal; // 每日基础总量
  final String analysis; // 分析说明
  final List<String> suggestions; // 建议

  BasalProfile({
    required this.segments,
    required this.totalDailyBasal,
    required this.analysis,
    this.suggestions = const [],
  });
}

/// 基础率分段
class BasalSegment {
  final int startHour; // 起始小时 0-23
  final int startMinute; // 起始分钟
  final int endHour; // 结束小时
  final int endMinute; // 结束分钟
  final double rate; // 基础率 (U/h)
  final String reason; // 设置原因

  BasalSegment({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.rate,
    this.reason = '',
  });

  String get timeLabel => '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}'
      ' - ${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
}

/// 膳食推荐
class MealSuggestion {
  final String mealType; // 早餐/午餐/晚餐/加餐
  final String suggestion; // 建议内容
  final double recommendedCarbs; // 推荐碳水(g)
  final List<String> foodExamples; // 食物示例
  final String reason; // 理由

  MealSuggestion({
    required this.mealType,
    required this.suggestion,
    required this.recommendedCarbs,
    this.foodExamples = const [],
    this.reason = '',
  });
}

// ========== 基础率估算 ==========

/// 基础率估算引擎
/// 结合 CGM 数据 + 毛细血管血糖 + 注射记录 + 饮食记录
class BasalEstimator {
  /// 从 CGM 数据估计基础率分段
  /// [cgmRecords] 过去3-14天的CGM记录（越多越准确）
  /// [config] 用户配置（ISF, TDD等）
  /// [insulinDoses] 最近的注射记录
  static BasalProfile estimate({
    required List<CGMRecord> cgmRecords,
    required UserConfig config,
    List<InsulinDose> insulinDoses = const [],
  }) {
    if (cgmRecords.length < 50) {
      return _defaultProfile(config);
    }

    // 1. 按小时分析血糖变化趋势
    final hourlyTrends = _analyzeHourlyTrends(cgmRecords);

    // 2. 识别需要调整基础率的时段
    final segments = _buildBasalSegments(hourlyTrends, config);

    // 3. 计算每日基础总量
    double totalBasal = 0;
    for (final seg in segments) {
      final hours = _segmentDurationHours(seg);
      totalBasal += seg.rate * hours;
    }

    // 4. 生成分析说明
    final analysis = _generateAnalysis(hourlyTrends, config);
    final suggestions = _generateSuggestions(hourlyTrends, config);

    return BasalProfile(
      segments: segments,
      totalDailyBasal: double.parse(totalBasal.toStringAsFixed(1)),
      analysis: analysis,
      suggestions: suggestions,
    );
  }

  /// 按小时分析血糖趋势
  static Map<int, _HourlyTrend> _analyzeHourlyTrends(List<CGMRecord> records) {
    // 按小时分组
    final hourlyData = <int, List<double>>{};
    for (final r in records) {
      final hour = r.timestamp.hour;
      hourlyData.putIfAbsent(hour, () => []);
      hourlyData[hour]!.add(r.glucose);
    }

    final trends = <int, _HourlyTrend>{};
    for (var h = 0; h < 24; h++) {
      final values = hourlyData[h] ?? [];
      if (values.isEmpty) {
        trends[h] = _HourlyTrend(hour: h, avgGlucose: 0, trend: 'unknown', stability: 0);
        continue;
      }

      final avg = values.reduce((a, b) => a + b) / values.length;
      final min = values.reduce(math.min);
      final max = values.reduce(math.max);
      final sd = _stdDev(values, avg);

      // 判断趋势方向：对比前2小时和后2小时
      final prevAvg = _safeAvg(hourlyData[(h - 2) % 24] ?? []);
      final nextAvg = _safeAvg(hourlyData[(h + 2) % 24] ?? []);

      String trend;
      if (avg < 3.9) {
        trend = 'low';
      } else if (avg > 10.0) {
        trend = 'high';
      } else if (nextAvg - prevAvg > 1.0) {
        trend = 'rising';
      } else if (nextAvg - prevAvg < -1.0) {
        trend = 'falling';
      } else {
        trend = 'stable';
      }

      trends[h] = _HourlyTrend(
        hour: h,
        avgGlucose: avg,
        minGlucose: min,
        maxGlucose: max,
        trend: trend,
        stability: sd,
        sampleCount: values.length,
      );
    }

    return trends;
  }

  /// 构建基础率分段
  static List<BasalSegment> _buildBasalSegments(
    Map<int, _HourlyTrend> trends,
    UserConfig config,
  ) {
    final segments = <BasalSegment>[];
    final isf = config.isf; // mmol/L per U
    final targetMax = config.targetGlucoseMax;
    final weight = config.weight;

    // 估算基础率基准值：TDD * 0.5 / 24
    final estimatedTDD = weight * 0.4; // 从体重估算
    final baseRate = (estimatedTDD * 0.5) / 24;

    var currentStart = 0;
    String? currentPattern;

    for (var h = 0; h < 24; h++) {
      final trend = trends[h] ?? _HourlyTrend(hour: h, avgGlucose: 0, trend: 'unknown', stability: 0);
      final pattern = _classifyHour(trend, targetMax, isf, baseRate);

      if (currentPattern == null) {
        currentPattern = pattern;
        currentStart = h;
      } else if (pattern != currentPattern || h == 23) {
        // 结束前一段，开始新段
        final endH = (pattern != currentPattern) ? h : h + 1;
        final rate = _calculateRate(segments.isEmpty ? 0 : currentStart, endH, trends, config, baseRate);

        segments.add(BasalSegment(
          startHour: currentStart,
          startMinute: 0,
          endHour: endH == 24 ? 0 : endH,
          endMinute: 0,
          rate: double.parse(rate.toStringAsFixed(2)),
          reason: _patternReason(currentPattern!),
        ));

        currentPattern = pattern;
        currentStart = h;
      }
    }

    // 如果没有生成任何分段，使用默认
    if (segments.isEmpty) {
      segments.add(BasalSegment(
        startHour: 0, startMinute: 0,
        endHour: 0, endMinute: 0,
        rate: double.parse(baseRate.toStringAsFixed(2)),
        reason: '基础参考值',
      ));
    }

    return segments;
  }

  static String _classifyHour(_HourlyTrend trend, double targetMax, double isf, double baseRate) {
    if (trend.avgGlucose <= 0) return 'unknown';
    if (trend.avgGlucose < 3.9) return 'reduce';    // 低血糖，需减少基础率
    if (trend.trend == 'falling' && trend.avgGlucose < 5.0) return 'reduce';
    if (trend.trend == 'rising' && trend.avgGlucose > targetMax + 2) return 'increase'; // 上升且高，需增加
    if (trend.avgGlucose > 10.0 && trend.trend == 'stable') return 'increase'; // 持续高
    if (trend.avgGlucose >= 5.0 && trend.avgGlucose <= 7.2) return 'normal';   // 正常
    return 'normal';
  }

  static double _calculateRate(int startH, int endH, Map<int, _HourlyTrend> trends, UserConfig config, double baseRate) {
    // 分段内平均血糖
    double sum = 0;
    int count = 0;
    for (var h = startH; h < endH; h++) {
      final t = trends[h % 24];
      if (t != null && t.avgGlucose > 0) {
        sum += t.avgGlucose;
        count++;
      }
    }

    if (count == 0) return baseRate;
    final avgGlucose = sum / count;

    // 根据平均血糖调整基础率
    if (avgGlucose < 3.9) return (baseRate * 0.7).clamp(0.05, 2.0);
    if (avgGlucose < 5.0) return (baseRate * 0.85).clamp(0.05, 2.0);
    if (avgGlucose <= 7.2) return baseRate;
    if (avgGlucose <= 10.0) return (baseRate * 1.15).clamp(0.05, 2.0);
    return (baseRate * 1.3).clamp(0.05, 2.0);
  }

  static String _patternReason(String pattern) {
    switch (pattern) {
      case 'reduce': return '该时段血糖偏低/下降趋势，减少基础率';
      case 'increase': return '该时段血糖偏高/上升趋势，增加基础率';
      case 'normal': return '该时段血糖平稳达标';
      case 'unknown': return '数据不足，使用估算值';
      default: return '';
    }
  }

  static String _generateAnalysis(Map<int, _HourlyTrend> trends, UserConfig config) {
    final problemHours = <String>[];
    final goodHours = <String>[];

    for (var h = 0; h < 24; h++) {
      final t = trends[h];
      if (t == null || t.avgGlucose <= 0) continue;
      if (t.avgGlucose < 3.9) problemHours.add('${h}:00 (低血糖 ${t.avgGlucose.toStringAsFixed(1)})');
      else if (t.avgGlucose > 10.0) problemHours.add('${h}:00 (高血糖 ${t.avgGlucose.toStringAsFixed(1)})');
      else if (t.avgGlucose >= 5.0 && t.avgGlucose <= 7.2) goodHours.add('${h}:00');
    }

    final buffer = StringBuffer('基于最近CGM数据分析：\n');
    if (problemHours.isNotEmpty) {
      buffer.write('⚠️ 问题时段：${problemHours.take(5).join('、')}\n');
    }
    if (goodHours.isNotEmpty) {
      buffer.write('✅ 达标时段：${goodHours.length}/24小时\n');
    }
    buffer.write('已根据各时段血糖趋势调整基础率分布。');
    return buffer.toString();
  }

  static List<String> _generateSuggestions(Map<int, _HourlyTrend> trends, UserConfig config) {
    final suggestions = <String>[];

    // 检查凌晨低血糖
    final earlyMorning = [0, 1, 2, 3, 4, 5];
    final earlyLow = earlyMorning.any((h) {
      final t = trends[h];
      return t != null && t.avgGlucose < 3.9;
    });
    if (earlyLow) suggestions.add('凌晨时段有低血糖风险，建议睡前加餐或减少基础率');

    // 检查黎明现象（早晨上升）
    final dawnHours = [4, 5, 6, 7];
    final dawnRise = dawnHours.every((h) {
      final t = trends[h];
      return t != null && t.trend == 'rising';
    });
    if (dawnRise) suggestions.add('出现黎明现象，建议增加凌晨4-7时基础率');

    // 检查餐后高血糖
    final postMeal = [9, 10, 13, 14, 19, 20];
    final postMealHigh = postMeal.any((h) {
      final t = trends[h];
      return t != null && t.avgGlucose > 10.0;
    });
    if (postMealHigh) suggestions.add('餐后血糖偏高，建议调整餐前大剂量或餐后运动');

    if (suggestions.isEmpty) {
      suggestions.add('各时段血糖控制良好，建议保持当前方案');
    }

    return suggestions;
  }

  static double _segmentDurationHours(BasalSegment seg) {
    if (seg.endHour == seg.startHour && seg.endMinute == seg.startMinute) return 24;
    final start = seg.startHour * 60 + seg.startMinute;
    var end = seg.endHour * 60 + seg.endMinute;
    if (end <= start) end += 24 * 60;
    return (end - start) / 60;
  }

  /// 默认基础率配置（当数据不足时使用）
  static BasalProfile _defaultProfile(UserConfig config) {
    final estimatedTDD = config.weight * 0.4;
    final baseRate = (estimatedTDD * 0.5) / 24;

    return BasalProfile(
      segments: [
        BasalSegment(
          startHour: 0, startMinute: 0,
          endHour: 0, endMinute: 0,
          rate: double.parse(baseRate.toStringAsFixed(2)),
          reason: '数据不足，基于体重估算',
        ),
      ],
      totalDailyBasal: double.parse((baseRate * 24).toStringAsFixed(1)),
      analysis: '数据不足（<50个CGM数据点），使用体重估算基础率。\n建议持续佩戴CGM 3天以上获取个性方案。',
      suggestions: ['继续佩戴CGM收集数据', '记录饮食和注射记录以便更准确分析'],
    );
  }

  static double _safeAvg(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double _stdDev(List<double> values, double mean) {
    if (values.length < 2) return 0;
    final variance = values.fold<double>(0, (sum, v) => sum + (v - mean) * (v - mean)) / values.length;
    return math.sqrt(variance);
  }
}

class _HourlyTrend {
  final int hour;
  final double avgGlucose;
  final double minGlucose;
  final double maxGlucose;
  final String trend; // 'low', 'high', 'rising', 'falling', 'stable', 'unknown'
  final double stability; // 标准差
  final int sampleCount;

  _HourlyTrend({
    required this.hour,
    required this.avgGlucose,
    this.minGlucose = 0,
    this.maxGlucose = 0,
    this.trend = 'unknown',
    this.stability = 0,
    this.sampleCount = 0,
  });
}

// ========== 饮食推荐 ==========

/// 饮食推荐引擎
/// 基于当前血糖水平 + 历史模式 + 碳水库推荐
class MealAdvisor {
  /// 推荐下一餐方案
  static List<MealSuggestion> recommend({
    required double currentGlucose,
    required UserConfig config,
    List<CGMRecord> recentTrend = const [],
    String? upcomingMeal, // 'breakfast', 'lunch', 'dinner', 'snack'
  }) {
    final meal = upcomingMeal ?? _guessNextMeal();
    final suggestions = <MealSuggestion>[];

    if (currentGlucose < 3.9) {
      // 低血糖：快速升糖
      suggestions.add(MealSuggestion(
        mealType: '紧急处理',
        suggestion: '⚠️ 血糖过低，请立即补糖！',
        recommendedCarbs: 15,
        foodExamples: ['半杯果汁 (约120ml)', '3-4块葡萄糖片', '一勺蜂蜜'],
        reason: '15-15法则：摄入15g快碳，15分钟后复测',
      ));
    } else if (currentGlucose < 5.0) {
      suggestions.add(MealSuggestion(
        mealType: meal,
        suggestion: '血糖偏低，建议进食含碳水中等偏高的餐食',
        recommendedCarbs: _recommendCarbs(meal, 45),
        foodExamples: _getMealExamples(meal, 'normal'),
        reason: '当前血糖偏低，适量增加碳水摄入',
      ));
    } else if (currentGlucose <= 7.2) {
      suggestions.add(MealSuggestion(
        mealType: meal,
        suggestion: '血糖达标，按常规标准进餐',
        recommendedCarbs: _recommendCarbs(meal, 40),
        foodExamples: _getMealExamples(meal, 'normal'),
        reason: '目标范围，正常用餐',
      ));
    } else if (currentGlucose <= 10.0) {
      suggestions.add(MealSuggestion(
        mealType: meal,
        suggestion: '血糖偏高，建议减少碳水摄入，增加蔬菜',
        recommendedCarbs: _recommendCarbs(meal, 30),
        foodExamples: _getMealExamples(meal, 'low_carbs'),
        reason: '血糖偏高，适当减少碳水可改善餐后血糖',
      ));
    } else {
      suggestions.add(MealSuggestion(
        mealType: meal,
        suggestion: '⚠️ 血糖高，建议先校正再进餐',
        recommendedCarbs: _recommendCarbs(meal, 25),
        foodExamples: _getMealExamples(meal, 'low_carbs'),
        reason: '高血糖状态，需优先处理高血糖，餐食建议低碳水',
      ));
    }

    // 如果趋势是快速下降，即使当前血糖正常也加预警
    if (recentTrend.length >= 3) {
      final last3 = recentTrend.take(3).toList();
      final drop = last3.first.glucose - last3.last.glucose;
      if (drop > 2.0) {
        suggestions.add(MealSuggestion(
          mealType: '预警',
          suggestion: '血糖快速下降趋势，餐后注意监测',
          recommendedCarbs: 0,
          foodExamples: [],
          reason: '下降速率 >2 mmol/L/15min',
        ));
      }
    }

    return suggestions;
  }

  static String _guessNextMeal() {
    final hour = DateTime.now().hour;
    if (hour < 9) return '早餐';
    if (hour < 14) return '午餐';
    if (hour < 20) return '晚餐';
    return '加餐';
  }

  static double _recommendCarbs(String meal, double base) {
    switch (meal) {
      case '早餐': return base * 1.0;
      case '午餐': return base * 1.2;
      case '晚餐': return base * 1.0;
      case '加餐': return base * 0.5;
      default: return base;
    }
  }

  static List<String> _getMealExamples(String meal, String style) {
    if (style == 'low_carbs') {
      switch (meal) {
        case '早餐': return ['全麦面包1片 + 鸡蛋 + 无糖豆浆', '燕麦片(少量) + 坚果 + 蔬菜沙拉'];
        case '午餐': return ['清蒸鱼 + 青菜 + 杂粮饭(小半碗)', '鸡胸肉沙拉 + 豆腐汤'];
        case '晚餐': return ['番茄炒蛋 + 炒青菜 + 少量藜麦', '清炒虾仁 + 西兰花'];
        case '加餐': return ['一小把杏仁', '无糖酸奶', '黄瓜/番茄'];
        default: return ['蔬菜沙拉', '清蒸蛋白'];
      }
    } else {
      switch (meal) {
        case '早餐': return ['全麦包子/馒头 + 鸡蛋 + 牛奶', '燕麦粥 + 鸡蛋羹'];
        case '午餐': return ['米饭(小碗) + 炒菜 + 瘦肉', '杂粮饭 + 蒸鱼 + 青菜'];
        case '晚餐': return ['杂粮饭(小碗) + 清蒸蛋白 + 蔬菜', '荞麦面 + 卤蛋 + 青菜'];
        case '加餐': return ['一个苹果/梨', '全麦饼干2-3片', '无糖酸奶'];
        default: return ['均衡搭配主食+蛋白+蔬菜'];
      }
    }
  }
}
