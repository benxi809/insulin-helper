/// 报警系统
///
/// 实现分级报警管理：
/// - 1级报警（黄色）：提醒类，需要用户注意但不紧急
/// - 2级报警（红色）：紧急类，需要立即处理
///
/// 报警类别：
/// - 药量不足/用尽
/// - 电池电量低
/// - 输注阻塞
/// - 连接异常
/// - 系统故障

import 'dart:async';
import 'package:flutter/material.dart';

/// 报警级别
enum AlertSeverity {
  /// 信息提示
  info,
  /// 一级警告（黄色）
  level1,
  /// 二级紧急（红色）
  level2,
}

/// 报警事件
class AlertEvent {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final String category;
  bool acknowledged;
  VoidCallback? onAcknowledge;

  AlertEvent({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    required this.category,
    this.acknowledged = false,
    this.onAcknowledge,
  });
}

/// 报警系统 — 单例
class AlertSystem {
  static final AlertSystem _instance = AlertSystem._internal();
  factory AlertSystem() => _instance;
  AlertSystem._internal();

  final List<AlertEvent> _activeAlerts = [];
  final List<AlertEvent> _alertHistory = [];
  final List<ValueChanged<AlertEvent>> _listeners = [];

  /// 当前活跃报警列表
  List<AlertEvent> get activeAlerts => List.unmodifiable(_activeAlerts);

  /// 历史报警记录
  List<AlertEvent> get alertHistory => List.unmodifiable(_alertHistory);

  /// 是否有未处理的报警
  bool get hasActiveAlerts => _activeAlerts.isNotEmpty;

  /// 最高报警级别
  AlertSeverity get highestSeverity {
    if (_activeAlerts.any((a) => a.severity == AlertSeverity.level2)) {
      return AlertSeverity.level2;
    }
    if (_activeAlerts.any((a) => a.severity == AlertSeverity.level1)) {
      return AlertSeverity.level1;
    }
    return AlertSeverity.info;
  }

  /// 添加报警监听
  void addListener(ValueChanged<AlertEvent> listener) {
    _listeners.add(listener);
  }

  /// 移除报警监听
  void removeListener(ValueChanged<AlertEvent> listener) {
    _listeners.remove(listener);
  }

  void _notify(AlertEvent event) {
    for (final l in _listeners) {
      l(event);
    }
  }

  /// 触发报警
  AlertEvent triggerAlert({
    required String title,
    required String message,
    required AlertSeverity severity,
    String category = 'system',
  }) {
    final event = AlertEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      severity: severity,
      timestamp: DateTime.now(),
      category: category,
    );

    _activeAlerts.add(event);
    _alertHistory.add(event);
    _notify(event);
    return event;
  }

  /// 确认/消除报警
  void acknowledgeAlert(String alertId) {
    final idx = _activeAlerts.indexWhere((a) => a.id == alertId);
    if (idx != -1) {
      _activeAlerts[idx].acknowledged = true;
      _activeAlerts.removeAt(idx);
    }
    // 也在历史中标记
    final histIdx = _alertHistory.indexWhere((a) => a.id == alertId);
    if (histIdx != -1) {
      _alertHistory[histIdx].acknowledged = true;
    }
  }

  /// 清除所有活跃报警
  void clearAll() {
    for (final alert in _activeAlerts) {
      alert.acknowledged = true;
    }
    _activeAlerts.clear();
  }

  /// 创建药物用尽报警
  AlertEvent createReservoirAlert(double remaining) {
    if (remaining <= 0) {
      return triggerAlert(
        title: '药物已用尽',
        message: '药桶已空，输注已停止。请立即更换药筒！',
        severity: AlertSeverity.level2,
        category: 'reservoir',
      );
    }
    return triggerAlert(
      title: '药物即将用尽',
      message: '剩余药量 ${remaining.toInt()}U，请准备更换药筒',
      severity: AlertSeverity.level1,
      category: 'reservoir',
    );
  }

  /// 创建输注阻塞报警
  AlertEvent createOcclusionAlert() {
    return triggerAlert(
      title: '输注阻塞',
      message: '检测到输注管路阻塞，请检查管路是否弯折或气泡',
      severity: AlertSeverity.level2,
      category: 'occlusion',
    );
  }

  /// 创建低电量报警
  AlertEvent createLowBatteryAlert(int level) {
    return triggerAlert(
      title: '电池电量低',
      message: '剩余电量 $level%，请尽快充电',
      severity: AlertSeverity.level1,
      category: 'battery',
    );
  }
}
