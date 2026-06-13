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
  final String? note;

  GlucoseRecord({
    this.id,
    required this.glucose,
    required this.timestamp,
    this.tag = GlucoseTag.other,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'glucose': glucose,
        'timestamp': timestamp.toIso8601String(),
        'tag': tag.index,
        'note': note,
      };

  factory GlucoseRecord.fromMap(Map<String, dynamic> map) => GlucoseRecord(
        id: map['id'] as int?,
        glucose: (map['glucose'] as num).toDouble(),
        timestamp: DateTime.parse(map['timestamp'] as String),
        tag: GlucoseTag.values[map['tag'] as int],
        note: map['note'] as String?,
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

/// 口服药物条目
class OralMedication {
  String name;      // 药物名称（如：二甲双胍）
  String dosage;    // 剂量（如：500mg）
  String frequency; // 频次（如：每日两次，随餐）

  OralMedication({
    this.name = '',
    this.dosage = '',
    this.frequency = '',
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
      };

  factory OralMedication.fromMap(Map<String, dynamic> map) => OralMedication(
        name: map['name'] as String? ?? '',
        dosage: map['dosage'] as String? ?? '',
        frequency: map['frequency'] as String? ?? '',
      );
}

/// 用户配置
/// 用户配置（含患者个人信息）
class UserConfig {
  double targetGlucoseMin; // 目标血糖下限 (mmol/L)
  double targetGlucoseMax; // 目标血糖上限 (mmol/L)
  double isf; // 胰岛素敏感系数 (mmol/L per U)
  double icr; // 碳水系数 (g per U)
  InsulinType insulinType; // 使用的胰岛素类型
  int iobDurationHours; // IOB 活性时长
  double maxDosePerInjection; // 单次最大剂量上限

  // 患者个人信息
  String patientName; // 患者姓名
  int age; // 年龄
  int diabetesType; // 1=1型, 2=2型
  DateTime? diagnosisDate; // 诊断日期
  double? hba1c; // 最近糖化血红蛋白 (%)
  int? targetHba1c; // 目标糖化血红蛋白 (如7即7%)
  String medicationRegimen; // 用药方案描述
  double weight; // 体重 (kg)
  List<OralMedication> oralMedications; // 口服药物列表

  // 提醒设置
  bool reminderBreakfast; // 早餐前7:00
  bool reminderLunch; // 午餐前11:30
  bool reminderDinner; // 晚餐前17:30
  bool reminderBedtime; // 睡前21:00

  UserConfig({
    this.targetGlucoseMin = 5.0,
    this.targetGlucoseMax = 7.2,
    this.isf = 2.5,
    this.icr = 12.0,
    this.insulinType = InsulinType.rapidActing,
    this.iobDurationHours = 4,
    this.maxDosePerInjection = 20.0,
    this.patientName = '',
    this.age = 30,
    this.diabetesType = 1,
    this.diagnosisDate,
    this.hba1c,
    this.medicationRegimen = '每日多次注射（MDI）',
    this.targetHba1c = 7,
    this.weight = 65.0,
    this.oralMedications = const [],
    this.reminderBreakfast = true,
    this.reminderLunch = true,
    this.reminderDinner = true,
    this.reminderBedtime = true,
  });

  Map<String, dynamic> toMap() => {
        'targetGlucoseMin': targetGlucoseMin,
        'targetGlucoseMax': targetGlucoseMax,
        'isf': isf,
        'icr': icr,
        'insulinType': insulinType.index,
        'iobDurationHours': iobDurationHours,
        'maxDosePerInjection': maxDosePerInjection,
        'patientName': patientName,
        'age': age,
        'diabetesType': diabetesType,
        'diagnosisDate': diagnosisDate?.toIso8601String(),
        'hba1c': hba1c,
        'medicationRegimen': medicationRegimen,
        'targetHba1c': targetHba1c,
        'weight': weight,
        'oralMedications': oralMedications.map((m) => m.toMap()).toList(),
        'reminderBreakfast': reminderBreakfast ? 1 : 0,
        'reminderLunch': reminderLunch ? 1 : 0,
        'reminderDinner': reminderDinner ? 1 : 0,
        'reminderBedtime': reminderBedtime ? 1 : 0,
      };

  factory UserConfig.fromMap(Map<String, dynamic> map) => UserConfig(
        targetGlucoseMin: (map['targetGlucoseMin'] as num?)?.toDouble() ?? 5.0,
        targetGlucoseMax: (map['targetGlucoseMax'] as num?)?.toDouble() ?? 7.2,
        isf: (map['isf'] as num?)?.toDouble() ?? 2.5,
        icr: (map['icr'] as num?)?.toDouble() ?? 12.0,
        insulinType: InsulinType.values[map['insulinType'] as int? ?? 0],
        iobDurationHours: map['iobDurationHours'] as int? ?? 4,
        maxDosePerInjection: (map['maxDosePerInjection'] as num?)?.toDouble() ?? 20.0,
        patientName: (map['patientName'] as String?) ?? '',
        age: (map['age'] as int?) ?? 30,
        diabetesType: (map['diabetesType'] as int?) ?? 1,
        diagnosisDate: map['diagnosisDate'] != null
            ? DateTime.tryParse(map['diagnosisDate'] as String)
            : null,
        hba1c: (map['hba1c'] as num?)?.toDouble(),
        medicationRegimen: (map['medicationRegimen'] as String?) ?? '每日多次注射（MDI）',
        targetHba1c: (map['targetHba1c'] as int?) ?? 7,
        weight: (map['weight'] as num?)?.toDouble() ?? 65.0,
        oralMedications: (map['oralMedications'] as List<dynamic>?)
                ?.map((e) => OralMedication.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        reminderBreakfast: (map['reminderBreakfast'] as int?) == 1,
        reminderLunch: (map['reminderLunch'] as int?) == 1,
        reminderDinner: (map['reminderDinner'] as int?) == 1,
        reminderBedtime: (map['reminderBedtime'] as int?) == 1,
      );
}

/// CGM 血糖记录（来自动态血糖仪）
class CGMRecord {
  final int? id;
  final double glucose; // mmol/L
  final DateTime timestamp;
  final String source; // "dexcom", "libre", "mock", "manual"
  final String trend; // "rapidRise", "rise", "stable", "fall", "rapidFall", "unknown"
  final int? trendArrow; // 箭头方向: 0=→, 1=↑, 2=↑↑, 3=↓, 4=↓↓, 5=⇅

  CGMRecord({
    this.id,
    required this.glucose,
    required this.timestamp,
    this.source = 'mock',
    this.trend = 'stable',
    this.trendArrow,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'glucose': glucose,
    'timestamp': timestamp.toIso8601String(),
    'source': source,
    'trend': trend,
    'trendArrow': trendArrow,
  };

  factory CGMRecord.fromMap(Map<String, dynamic> map) => CGMRecord(
    id: map['id'] as int?,
    glucose: (map['glucose'] as num).toDouble(),
    timestamp: DateTime.parse(map['timestamp'] as String),
    source: map['source'] as String? ?? 'mock',
    trend: map['trend'] as String? ?? 'stable',
    trendArrow: map['trendArrow'] as int?,
  );
}

/// CGM 设备配置
class CGMDeviceConfig {
  String deviceType; // "dexcom", "libre", "mock", "none"
  String displayName; // 显示名称
  bool isConnected;
  String? apiKey; // API密钥（Dexcom Share 账号等）
  String? username; // 账号
  String? password; // 密码（本地存储）
  int syncIntervalMinutes;

  CGMDeviceConfig({
    this.deviceType = 'none',
    this.displayName = '未连接',
    this.isConnected = false,
    this.apiKey,
    this.username,
    this.password,
    this.syncIntervalMinutes = 5,
  });

  Map<String, dynamic> toMap() => {
    'id': 1,
    'deviceType': deviceType,
    'displayName': displayName,
    'isConnected': isConnected ? 1 : 0,
    'apiKey': apiKey,
    'username': username,
    'password': password,
    'syncIntervalMinutes': syncIntervalMinutes,
  };

  factory CGMDeviceConfig.fromMap(Map<String, dynamic> map) => CGMDeviceConfig(
    deviceType: map['deviceType'] as String? ?? 'none',
    displayName: map['displayName'] as String? ?? '未连接',
    isConnected: (map['isConnected'] as int?) == 1,
    apiKey: map['apiKey'] as String?,
    username: map['username'] as String?,
    password: map['password'] as String?,
    syncIntervalMinutes: map['syncIntervalMinutes'] as int? ?? 5,
  );
}

/// CGM趋势箭头辅助方法
extension CGMRecordExtension on CGMRecord {
  String get trendIcon {
    switch (trendArrow ?? _arrowFromTrend) {
      case 0: return '→';
      case 1: return '↑';
      case 2: return '↑↑';
      case 3: return '↓';
      case 4: return '↓↓';
      case 5: return '⇅';
      default: return '→';
    }
  }

  int get _arrowFromTrend {
    switch (trend) {
      case 'rapidRise': return 2;
      case 'rise': return 1;
      case 'stable': return 0;
      case 'fall': return 3;
      case 'rapidFall': return 4;
      default: return 5;
    }
  }

  String get trendDescription {
    switch (trend) {
      case 'rapidRise': return '快速上升 (>2 mmol/L/15min)';
      case 'rise': return '缓慢上升';
      case 'stable': return '稳定';
      case 'fall': return '缓慢下降';
      case 'rapidFall': return '快速下降 (>2 mmol/L/15min)';
      default: return '波动';
    }
  }
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
