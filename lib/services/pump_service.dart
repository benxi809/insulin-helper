/// 胰岛素泵通信服务 — 模拟实现
///
/// 模拟真实胰岛素泵的蓝牙通信层，提供：
/// - 连接/断开管理
/// - 泵状态读取
/// - 基础率设置/查询
/// - 大剂量输注
/// - 临时基础率
/// - 报警管理
///
/// 实际部署时替换为 BLE 通信实现。

import 'dart:async';
import 'package:insulin_app/models/pump_models.dart';

/// 泵通信服务回调
typedef PumpStatusCallback = void Function(PumpStatus status);
typedef PumpAlertCallback = void Function(PumpAlert alert);

/// 胰岛素泵通信服务
class PumpService {
  static final PumpService _instance = PumpService._internal();
  factory PumpService() => _instance;
  PumpService._internal();

  // ── 连接状态 ──
  PumpConnectionState _connectionState = PumpConnectionState.disconnected;
  PumpConnectionState get connectionState => _connectionState;

  // ── 泵状态 ──
  PumpStatus _status = PumpStatus(
    mode: PumpMode.running,
    connectionState: PumpConnectionState.disconnected,
    currentBasalRate: 0.8,
    reservoirRemaining: 180,
    batteryLevel: 85,
    todayTotalDelivered: 12.5,
    lastDeliveryTime: DateTime.now().subtract(const Duration(minutes: 15)),
  );
  PumpStatus get status => _status;

  // ── 基础率配置 ──
  BasalRateProfile _basalProfile = const BasalRateProfile(
    name: '标准基础率',
    segments: [
      BasalRateSegment(startHour: 0.0, rate: 0.8),
      BasalRateSegment(startHour: 3.0, rate: 1.0),
      BasalRateSegment(startHour: 6.0, rate: 1.2),
      BasalRateSegment(startHour: 9.0, rate: 0.9),
      BasalRateSegment(startHour: 12.0, rate: 0.7),
      BasalRateSegment(startHour: 15.0, rate: 0.8),
      BasalRateSegment(startHour: 18.0, rate: 1.0),
      BasalRateSegment(startHour: 21.0, rate: 0.6),
    ],
  );
  BasalRateProfile get basalProfile => _basalProfile;

  // ── 历史报警 ──
  final List<PumpAlert> _alerts = [];
  List<PumpAlert> get alerts => List.unmodifiable(_alerts);

  // ── 输注历史 ──
  final List<DeliveryRecord> _deliveryHistory = [];
  List<DeliveryRecord> get deliveryHistory => List.unmodifiable(_deliveryHistory);

  // ── 可用泵设备列表 ──
  final List<Map<String, String>> _availablePumps = [
    {'id': 'RS-2401', 'name': '睿昇胰岛素泵 #2401', 'signal': '强'},
    {'id': 'RS-2402', 'name': '睿昇胰岛素泵 #2402', 'signal': '中'},
    {'id': 'RS-2389', 'name': '睿昇胰岛素泵 #2389', 'signal': '弱'},
  ];
  List<Map<String, String>> get availablePumps => List.unmodifiable(_availablePumps);

  // ── 临时基础率 ──
  TempBasal? _currentTempBasal;

  // ── 监听器 ──
  final List<PumpStatusCallback> _statusListeners = [];
  final List<PumpAlertCallback> _alertListeners = [];
  Timer? _simTimer;

  // ── 模拟数据 ──
  int _simTick = 0;

  /// 初始化泵服务
  Future<void> init() async {
    // 启动模拟状态更新
    _simTimer = Timer.periodic(const Duration(seconds: 5), (_) => _simulateTick());
  }

  /// 释放资源
  void dispose() {
    _simTimer?.cancel();
    _statusListeners.clear();
    _alertListeners.clear();
  }

  /// 添加状态监听
  void addStatusListener(PumpStatusCallback listener) {
    _statusListeners.add(listener);
  }

  /// 移除状态监听
  void removeStatusListener(PumpStatusCallback listener) {
    _statusListeners.remove(listener);
  }

  /// 添加报警监听
  void addAlertListener(PumpAlertCallback listener) {
    _alertListeners.add(listener);
  }

  /// 移除报警监听
  void removeAlertListener(PumpAlertCallback listener) {
    _alertListeners.remove(listener);
  }

  void _notifyStatus() {
    for (final l in _statusListeners) {
      l(_status);
    }
  }

  void _notifyAlert(PumpAlert alert) {
    for (final l in _alertListeners) {
      l(alert);
    }
  }

  // ── 连接管理 ──

  /// 开始扫描泵设备
  Stream<Map<String, String>> scanPumps() async* {
    _connectionState = PumpConnectionState.connecting;
    _updateConnectionState();

    for (final pump in _availablePumps) {
      await Future.delayed(const Duration(milliseconds: 800));
      yield pump;
    }
  }

  /// 连接到指定泵
  Future<bool> connect(String deviceId) async {
    _connectionState = PumpConnectionState.connecting;
    _updateConnectionState();

    // 模拟连接过程
    await Future.delayed(const Duration(seconds: 2));

    _connectionState = PumpConnectionState.connected;
    _status = _status.copyWith(
      connectionState: PumpConnectionState.connected,
      mode: PumpMode.running,
      currentBasalRate: 0.8,
    );
    _updateConnectionState();
    _notifyStatus();
    return true;
  }

  /// 断开连接
  Future<void> disconnect() async {
    _connectionState = PumpConnectionState.disconnected;
    _status = _status.copyWith(
      connectionState: PumpConnectionState.disconnected,
      mode: PumpMode.paused,
    );
    _updateConnectionState();
    _notifyStatus();
  }

  void _updateConnectionState() {
    _status = _status.copyWith(connectionState: _connectionState);
  }

  // ── 泵控制 ──

  /// 开始大剂量输注
  Future<bool> startBolus(double units, {BolusType type = BolusType.standard}) async {
    if (_status.mode != PumpMode.running && _status.mode != PumpMode.tempBasal) {
      return false;
    }

    _status = _status.copyWith(
      mode: PumpMode.bolusing,
      currentBolus: units,
    );
    _notifyStatus();

    // 模拟输注过程（每U约2秒）
    await Future.delayed(Duration(milliseconds: (units * 2000).round()));

    _status = _status.copyWith(
      mode: PumpMode.running,
      currentBolus: 0,
      reservoirRemaining: (_status.reservoirRemaining - units).clamp(0, 300),
      todayTotalDelivered: _status.todayTotalDelivered + units,
      lastDeliveryTime: DateTime.now(),
    );
    _notifyStatus();

    // 记录输注历史
    _deliveryHistory.add(DeliveryRecord(
      timestamp: DateTime.now(),
      type: 'bolus',
      dose: units,
      note: '${type.name}大剂量',
    ));

    return true;
  }

  /// 取消当前大剂量
  Future<void> cancelBolus() async {
    if (_status.mode != PumpMode.bolusing) return;

    _status = _status.copyWith(mode: PumpMode.running, currentBolus: 0);
    _notifyStatus();
  }

  /// 暂停输注
  Future<void> pause() async {
    _status = _status.copyWith(mode: PumpMode.paused);
    _notifyStatus();
  }

  /// 恢复输注
  Future<void> resume() async {
    _status = _status.copyWith(mode: PumpMode.running);
    _notifyStatus();
  }

  /// 设置临时基础率
  Future<void> setTempBasal(double rate, int durationMinutes) async {
    _currentTempBasal = TempBasal(
      rate: rate,
      durationMinutes: durationMinutes,
      startTime: DateTime.now(),
    );
    _status = _status.copyWith(
      mode: PumpMode.tempBasal,
      tempBasalRate: rate,
      tempBasalRemainingMinutes: durationMinutes,
    );
    _notifyStatus();
  }

  /// 取消临时基础率
  Future<void> cancelTempBasal() async {
    _currentTempBasal = null;
    _status = _status.copyWith(
      mode: PumpMode.running,
      tempBasalRate: null,
      tempBasalRemainingMinutes: null,
    );
    _notifyStatus();
  }

  // ── 基础率配置 ──

  /// 更新基础率配置
  Future<void> updateBasalProfile(BasalRateProfile profile) async {
    _basalProfile = profile;
    _status = _status.copyWith(currentBasalRate: profile.getRateAt(DateTime.now().hour + DateTime.now().minute / 60.0));
    _notifyStatus();
  }

  /// 读取泵上的基础率配置
  Future<BasalRateProfile> readBasalProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _basalProfile;
  }

  /// 发送基础率配置到泵
  Future<bool> sendBasalProfile(BasalRateProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _basalProfile = profile;
    _status = _status.copyWith(currentBasalRate: profile.getRateAt(DateTime.now().hour + DateTime.now().minute / 60.0));
    _notifyStatus();
    return true;
  }

  // ── 报警管理 ──

  /// 确认报警
  Future<void> acknowledgeAlert(int alertId) async {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx != -1) {
      _alerts[idx] = _alerts[idx].copyWith(acknowledged: true);
    }
    _status = _status.copyWith(alertLevel: 0, alertMessage: null);
    _notifyStatus();
  }

  /// 清除所有报警
  Future<void> clearAllAlerts() async {
    _alerts.clear();
    _status = _status.copyWith(alertLevel: 0, alertMessage: null);
    _notifyStatus();
  }

  /// 检查药量状态
  Future<PumpAlert?> checkReservoir() async {
    if (_status.reservoirRemaining <= 20 && _status.reservoirRemaining > 0) {
      final alert = PumpAlert(
        id: DateTime.now().millisecondsSinceEpoch,
        title: '药物即将用尽',
        message: '剩余药量 ${_status.reservoirRemaining.toInt()}U，请准备更换药筒',
        level: 1,
        timestamp: DateTime.now(),
        category: 'reservoir',
      );
      _alerts.add(alert);
      _status = _status.copyWith(alertLevel: 1, alertMessage: alert.title);
      _notifyAlert(alert);
      _notifyStatus();
      return alert;
    }
    if (_status.reservoirRemaining <= 0) {
      final alert = PumpAlert(
        id: DateTime.now().millisecondsSinceEpoch,
        title: '药物已用尽',
        message: '药桶已空，输注已停止。请立即更换药筒！',
        level: 2,
        timestamp: DateTime.now(),
        category: 'reservoir',
      );
      _alerts.add(alert);
      _status = _status.copyWith(alertLevel: 2, alertMessage: alert.title, mode: PumpMode.alerting);
      _notifyAlert(alert);
      _notifyStatus();
      return alert;
    }
    return null;
  }

  // ── 模拟数据更新 ──

  void _simulateTick() {
    _simTick++;

    // 模拟药量缓慢减少
    if (_status.mode == PumpMode.running || _status.mode == PumpMode.tempBasal) {
      final now = DateTime.now();
      final hour = now.hour + now.minute / 60.0;
      final basalRate = _currentTempBasal?.rate ?? _basalProfile.getRateAt(hour);
      // 每5秒消耗约 basalRate/720 U
      final consumed = basalRate / 720;
      final newReservoir = (_status.reservoirRemaining - consumed).clamp(0.0, 300.0);
      _status = _status.copyWith(
        reservoirRemaining: newReservoir,
        todayTotalDelivered: _status.todayTotalDelivered + consumed,
        currentBasalRate: basalRate,
      );

      // 检查药量报警
      if (newReservoir <= 20 && _simTick % 12 == 0) {
        checkReservoir();
      }

      // 更新临时基础率剩余时间
      if (_currentTempBasal != null) {
        _status = _status.copyWith(
          tempBasalRemainingMinutes: _currentTempBasal!.remainingMinutes,
        );
        if (!_currentTempBasal!.isActive) {
          _currentTempBasal = null;
          _status = _status.copyWith(
            mode: PumpMode.running,
            tempBasalRate: null,
            tempBasalRemainingMinutes: null,
          );
        }
      }

      _notifyStatus();
    }
  }
}
