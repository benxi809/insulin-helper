/// 胰岛素类型
enum InsulinType {
  rapidActing,  // 速效胰岛素（门冬、赖脯、谷赖）
  shortActing,  // 短效胰岛素（常规人胰岛素）
}

extension InsulinTypeExtension on InsulinType {
  String get displayName {
    switch (this) {
      case InsulinType.rapidActing:
        return '速效（门冬/赖脯）';
      case InsulinType.shortActing:
        return '短效（常规人胰岛素）';
    }
  }

  /// 500法则/450法则：每单位胰岛素覆盖的碳水克数
  int get icrFormulaBase {
    switch (this) {
      case InsulinType.rapidActing:
        return 500; // 500法则
      case InsulinType.shortActing:
        return 450; // 450法则
    }
  }

  /// 1800法则/1500法则：每单位胰岛素降低的血糖值(mg/dL)
  int get isfFormulaBase {
    switch (this) {
      case InsulinType.rapidActing:
        return 1800; // 1800法则
      case InsulinType.shortActing:
        return 1500; // 1500法则
    }
  }

  /// 胰岛素活性持续时间（小时）
  int get activeDurationHours {
    switch (this) {
      case InsulinType.rapidActing:
        return 4;
      case InsulinType.shortActing:
        return 6;
    }
  }
}

/// 血糖记录
class GlucoseRecord {
  final int? id;
  final double glucose; // mmol/L
  final DateTime timestamp;
  final GlucoseTag tag;

  GlucoseRecord({
    this.id,
    required this.glucose,
    required this.timestamp,
    this.tag = GlucoseTag.other,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'glucose': glucose,
        'timestamp': timestamp.toIso8601String(),
        'tag': tag.index,
      };

  factory GlucoseRecord.fromMap(Map<String, dynamic> map) => GlucoseRecord(
        id: map['id'] as int?,
        glucose: (map['glucose'] as num).toDouble(),
        timestamp: DateTime.parse(map['timestamp'] as String),
        tag: GlucoseTag.values[map['tag'] as int],
      );
}

/// 血糖标记
enum GlucoseTag {
  fasting, // 空腹
  preMeal, // 餐前
  postMeal, // 餐后
  bedtime, // 睡前
  earlyMorning, // 凌晨
  other, // 其他
}

extension GlucoseTagExtension on GlucoseTag {
  String get displayName {
    switch (this) {
      case GlucoseTag.fasting:
        return '空腹';
      case GlucoseTag.preMeal:
        return '餐前';
      case GlucoseTag.postMeal:
        return '餐后';
      case GlucoseTag.bedtime:
        return '睡前';
      case GlucoseTag.earlyMorning:
        return '凌晨';
      case GlucoseTag.other:
        return '其他';
    }
  }
}

/// 胰岛素注射记录
class InsulinDose {
  final int? id;
  final double units; // 单位 U
  final DateTime timestamp;
  final InsulinType insulinType;
  final DoseTag tag;

  InsulinDose({
    this.id,
    required this.units,
    required this.timestamp,
    this.insulinType = InsulinType.rapidActing,
    this.tag = DoseTag.meal,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'units': units,
        'timestamp': timestamp.toIso8601String(),
        'insulinType': insulinType.index,
        'tag': tag.index,
      };

  factory InsulinDose.fromMap(Map<String, dynamic> map) => InsulinDose(
        id: map['id'] as int?,
        units: (map['units'] as num).toDouble(),
        timestamp: DateTime.parse(map['timestamp'] as String),
        insulinType: InsulinType.values[map['insulinType'] as int],
        tag: DoseTag.values[map['tag'] as int],
      );
}

/// 注射标记
enum DoseTag {
  meal, // 餐时
  correction, // 校正
  basal, // 基础
}

/// 用户配置
class UserConfig {
  double targetGlucoseMin; // 目标血糖下限 (mmol/L)
  double targetGlucoseMax; // 目标血糖上限 (mmol/L)
  double isf; // 胰岛素敏感系数 (mmol/L per U)
  double icr; // 碳水系数 (g per U)
  InsulinType insulinType; // 使用的胰岛素类型
  int iobDurationHours; // IOB 活性时长
  double maxDosePerInjection; // 单次最大剂量上限

  UserConfig({
    this.targetGlucoseMin = 5.0,
    this.targetGlucoseMax = 7.2,
    this.isf = 2.5,
    this.icr = 12.0,
    this.insulinType = InsulinType.rapidActing,
    this.iobDurationHours = 4,
    this.maxDosePerInjection = 20.0,
  });

  Map<String, dynamic> toMap() => {
        'targetGlucoseMin': targetGlucoseMin,
        'targetGlucoseMax': targetGlucoseMax,
        'isf': isf,
        'icr': icr,
        'insulinType': insulinType.index,
        'iobDurationHours': iobDurationHours,
        'maxDosePerInjection': maxDosePerInjection,
      };

  factory UserConfig.fromMap(Map<String, dynamic> map) => UserConfig(
        targetGlucoseMin: (map['targetGlucoseMin'] as num?)?.toDouble() ?? 5.0,
        targetGlucoseMax: (map['targetGlucoseMax'] as num?)?.toDouble() ?? 7.2,
        isf: (map['isf'] as num?)?.toDouble() ?? 2.5,
        icr: (map['icr'] as num?)?.toDouble() ?? 12.0,
        insulinType: InsulinType.values[map['insulinType'] as int? ?? 0],
        iobDurationHours: map['iobDurationHours'] as int? ?? 4,
        maxDosePerInjection: (map['maxDosePerInjection'] as num?)?.toDouble() ?? 20.0,
      );
}

/// 食物条目（碳水库用）
class FoodItem {
  final String name;
  final double carbsPer100g; // 每100g碳水含量
  final String unit; // 常用单位（"碗"、"个"、"两"、"份"）
  final double gramsPerUnit; // 每单位对应的克数
  final String category; // 分类（"主食"、"水果"、"蔬菜"等）

  FoodItem({
    required this.name,
    required this.carbsPer100g,
    required this.unit,
    required this.gramsPerUnit,
    required this.category,
  });

  /// 按份量计算碳水
  double carbsForPortions(double portions) {
    return (carbsPer100g / 100) * gramsPerUnit * portions;
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        name: json['name'] as String,
        carbsPer100g: (json['carbsPer100g'] as num).toDouble(),
        unit: json['unit'] as String,
        gramsPerUnit: (json['gramsPerUnit'] as num).toDouble(),
        category: json['category'] as String,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'carbsPer100g': carbsPer100g,
        'unit': unit,
        'gramsPerUnit': gramsPerUnit,
        'category': category,
      };
}
