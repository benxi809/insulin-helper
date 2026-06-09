/// 胰岛素泵数据模型
///
/// 包含：泵状态、基础率配置、大剂量模板、报警信息、输注记录等

/// 泵运行模式
enum PumpMode {
  /// 正常运行
  running,
  /// 暂停
  paused,
  /// 大剂量输注中
  bolusing,
  /// 临时基础率
  tempBasal,
  /// 报警
  alerting,
  /// 关机
  poweredOff,
}

/// 泵连接状态
enum PumpConnectionState {
  disconnected,
  connecting,
  connected,
  pairing,
  verifying,
}

/// 基础率时段
class BasalRateSegment {
  /// 起始时间（小时），如 0.0 = 00:00, 1.5 = 01:30
  final double startHour;
  /// 基础率剂量 (U/h)
  final double rate;

  const BasalRateSegment({
    required this.startHour,
    required this.rate,
  });

  String get timeDisplay {
    final h = startHour.floor();
    final m = ((startHour - h) * 60).round();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() => {
        'startHour': startHour,
        'rate': rate,
      };

  factory BasalRateSegment.fromMap(Map<String, dynamic> map) => BasalRateSegment(
        startHour: (map['startHour'] as num).toDouble(),
        rate: (map['rate'] as num).toDouble(),
      );
}

/// 基础率配置（一组时段）
class BasalRateProfile {
  final String name;
  final List<BasalRateSegment> segments;

  const BasalRateProfile({
    this.name = '默认基础率',
    required this.segments,
  });

  /// 24小时总基础量
  double get totalDailyBasal {
    double total = 0;
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final nextStart = (i + 1 < segments.length)
          ? segments[i + 1].startHour
          : 24.0;
      final hours = nextStart - seg.startHour;
      total += seg.rate * hours;
    }
    return total;
  }

  /// 获取指定时间的基础率
  double getRateAt(double hour) {
    BasalRateSegment? active;
    for (final seg in segments) {
      if (seg.startHour <= hour) {
        active = seg;
      } else {
        break;
      }
    }
    return active?.rate ?? segments.last.rate;
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'segments': segments.map((s) => s.toMap()).toList(),
      };

  factory BasalRateProfile.fromMap(Map<String, dynamic> map) =>
      BasalRateProfile(
        name: map['name'] as String? ?? '默认基础率',
        segments: (map['segments'] as List?)
                ?.map((s) => BasalRateSegment.fromMap(s as Map<String, dynamic>))
                .toList() ??
            _defaultSegments,
      );

  static const List<BasalRateSegment> _defaultSegments = [
    BasalRateSegment(startHour: 0.0, rate: 0.8),
    BasalRateSegment(startHour: 3.0, rate: 1.0),
    BasalRateSegment(startHour: 6.0, rate: 1.2),
    BasalRateSegment(startHour: 9.0, rate: 0.9),
    BasalRateSegment(startHour: 12.0, rate: 0.7),
    BasalRateSegment(startHour: 15.0, rate: 0.8),
    BasalRateSegment(startHour: 18.0, rate: 1.0),
    BasalRateSegment(startHour: 21.0, rate: 0.6),
  ];
}

/// 大剂量模板
enum BolusType {
  /// 快速/标准大剂量
  standard,
  /// 扩展大剂量（方波）
  extended,
  /// 复合大剂量（双波）
  combo,
}

/// 大剂量模板配置
class BolusTemplate {
  final String name;
  final BolusType type;
  final double dose; // 剂量 (U)
  final double? extendedPercentage; // 扩展比例（复合/扩展时使用）
  final int? extendedDurationMinutes; // 扩展持续时间（分钟）

  const BolusTemplate({
    required this.name,
    required this.type,
    required this.dose,
    this.extendedPercentage,
    this.extendedDurationMinutes,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type.index,
        'dose': dose,
        'extendedPercentage': extendedPercentage,
        'extendedDurationMinutes': extendedDurationMinutes,
      };

  factory BolusTemplate.fromMap(Map<String, dynamic> map) => BolusTemplate(
        name: map['name'] as String? ?? '',
        type: BolusType.values[map['type'] as int? ?? 0],
        dose: (map['dose'] as num?)?.toDouble() ?? 0,
        extendedPercentage: (map['extendedPercentage'] as num?)?.toDouble(),
        extendedDurationMinutes: map['extendedDurationMinutes'] as int?,
      );
}

/// 泵状态信息
class PumpStatus {
  /// 运行模式
  final PumpMode mode;
  /// 连接状态
  final PumpConnectionState connectionState;
  /// 当前基础率 (U/h)
  final double currentBasalRate;
  /// 当前大剂量 (U)，无则为0
  final double currentBolus;
  /// 剩余药量 (U)
  final double reservoirRemaining;
  /// 电池电量百分比 (0-100)
  final int batteryLevel;
  /// 输注量今日累计 (U)
  final double todayTotalDelivered;
  /// 上次输注时间
  final DateTime? lastDeliveryTime;
  /// 报警消息
  final String? alertMessage;
  /// 报警级别（0=无, 1=一级, 2=二级）
  final int alertLevel;
  /// 临时基础率（如果有）
  final double? tempBasalRate;
  /// 临时基础率剩余分钟
  final int? tempBasalRemainingMinutes;

  const PumpStatus({
    this.mode = PumpMode.running,
    this.connectionState = PumpConnectionState.disconnected,
    this.currentBasalRate = 0.0,
    this.currentBolus = 0.0,
    this.reservoirRemaining = 0,
    this.batteryLevel = 0,
    this.todayTotalDelivered = 0,
    this.lastDeliveryTime,
    this.alertMessage,
    this.alertLevel = 0,
    this.tempBasalRate,
    this.tempBasalRemainingMinutes,
  });

  PumpStatus copyWith({
    PumpMode? mode,
    PumpConnectionState? connectionState,
    double? currentBasalRate,
    double? currentBolus,
    double? reservoirRemaining,
    int? batteryLevel,
    double? todayTotalDelivered,
    DateTime? lastDeliveryTime,
    String? alertMessage,
    int? alertLevel,
    double? tempBasalRate,
    int? tempBasalRemainingMinutes,
  }) =>
      PumpStatus(
        mode: mode ?? this.mode,
        connectionState: connectionState ?? this.connectionState,
        currentBasalRate: currentBasalRate ?? this.currentBasalRate,
        currentBolus: currentBolus ?? this.currentBolus,
        reservoirRemaining: reservoirRemaining ?? this.reservoirRemaining,
        batteryLevel: batteryLevel ?? this.batteryLevel,
        todayTotalDelivered: todayTotalDelivered ?? this.todayTotalDelivered,
        lastDeliveryTime: lastDeliveryTime ?? this.lastDeliveryTime,
        alertMessage: alertMessage ?? this.alertMessage,
        alertLevel: alertLevel ?? this.alertLevel,
        tempBasalRate: tempBasalRate ?? this.tempBasalRate,
        tempBasalRemainingMinutes:
            tempBasalRemainingMinutes ?? this.tempBasalRemainingMinutes,
      );
}

/// 报警记录
class PumpAlert {
  final int? id;
  final String title;
  final String message;
  final int level; // 1=一级警告, 2=二级紧急
  final DateTime timestamp;
  final bool acknowledged;
  final String? category; // 'reservoir', 'battery', 'occlusion', 'connectivity', 'system'

  PumpAlert({
    this.id,
    required this.title,
    required this.message,
    required this.level,
    required this.timestamp,
    this.acknowledged = false,
    this.category,
  });

  PumpAlert copyWith({
    int? id,
    String? title,
    String? message,
    int? level,
    DateTime? timestamp,
    bool? acknowledged,
    String? category,
  }) =>
      PumpAlert(
        id: id ?? this.id,
        title: title ?? this.title,
        message: message ?? this.message,
        level: level ?? this.level,
        timestamp: timestamp ?? this.timestamp,
        acknowledged: acknowledged ?? this.acknowledged,
        category: category ?? this.category,
      );
}

/// 历史输注记录
class DeliveryRecord {
  final int? id;
  final DateTime timestamp;
  final String type; // 'bolus', 'basal', 'temp_basal'
  final double dose; // U
  final String? note;

  DeliveryRecord({
    this.id,
    required this.timestamp,
    required this.type,
    required this.dose,
    this.note,
  });
}

/// 临时基础率
class TempBasal {
  final double rate; // U/h
  final int durationMinutes; // 持续时间（分钟）
  final DateTime startTime;

  const TempBasal({
    required this.rate,
    required this.durationMinutes,
    required this.startTime,
  });

  int get remainingMinutes {
    final elapsed = DateTime.now().difference(startTime).inMinutes;
    return (durationMinutes - elapsed).clamp(0, durationMinutes);
  }

  bool get isActive => remainingMinutes > 0;
}
