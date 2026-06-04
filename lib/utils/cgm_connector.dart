import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:insulin_app/models/models.dart';

/// CGM 血糖趋势
enum CGMTrend {
  rapidRise,
  rise,
  stable,
  fall,
  rapidFall,
  unknown,
}

extension CGMTrendExtension on CGMTrend {
  String get displayName {
    switch (this) {
      case CGMTrend.rapidRise: return '快速上升';
      case CGMTrend.rise: return '上升';
      case CGMTrend.stable: return '稳定';
      case CGMTrend.fall: return '下降';
      case CGMTrend.rapidFall: return '快速下降';
      case CGMTrend.unknown: return '波动';
    }
  }

  String get arrow {
    switch (this) {
      case CGMTrend.rapidRise: return '↑↑';
      case CGMTrend.rise: return '↑';
      case CGMTrend.stable: return '→';
      case CGMTrend.fall: return '↓';
      case CGMTrend.rapidFall: return '↓↓';
      case CGMTrend.unknown: return '⇅';
    }
  }

  int get arrowValue {
    switch (this) {
      case CGMTrend.rapidRise: return 2;
      case CGMTrend.rise: return 1;
      case CGMTrend.stable: return 0;
      case CGMTrend.fall: return 3;
      case CGMTrend.rapidFall: return 4;
      case CGMTrend.unknown: return 5;
    }
  }

  String get trendKey {
    switch (this) {
      case CGMTrend.rapidRise: return 'rapidRise';
      case CGMTrend.rise: return 'rise';
      case CGMTrend.stable: return 'stable';
      case CGMTrend.fall: return 'fall';
      case CGMTrend.rapidFall: return 'rapidFall';
      case CGMTrend.unknown: return 'unknown';
    }
  }

  static CGMTrend fromTrendKey(String key) {
    switch (key) {
      case 'rapidRise': return CGMTrend.rapidRise;
      case 'rise': return CGMTrend.rise;
      case 'stable': return CGMTrend.stable;
      case 'fall': return CGMTrend.fall;
      case 'rapidFall': return CGMTrend.rapidFall;
      default: return CGMTrend.unknown;
    }
  }
}

/// CGM 设备品牌
enum CGMDeviceBrand {
  none,
  mock,
  dexcom,
  libre,
  sona,
  sinnova,
  wellins,
  microtech,
}

extension CGMDeviceBrandExtension on CGMDeviceBrand {
  String get displayName {
    switch (this) {
      case CGMDeviceBrand.none: return '未连接';
      case CGMDeviceBrand.mock: return '模拟数据（演示）';
      case CGMDeviceBrand.dexcom: return '德康 Dexcom G6/G7';
      case CGMDeviceBrand.libre: return '雅培瞬感 FreeStyle Libre';
      case CGMDeviceBrand.sona: return '硅基动感';
      case CGMDeviceBrand.sinnova: return '三诺爱看';
      case CGMDeviceBrand.wellins: return '鱼跃';
      case CGMDeviceBrand.microtech: return '微泰';
    }
  }

  String get shortName {
    switch (this) {
      case CGMDeviceBrand.none: return 'none';
      case CGMDeviceBrand.mock: return 'mock';
      case CGMDeviceBrand.dexcom: return 'dexcom';
      case CGMDeviceBrand.libre: return 'libre';
      case CGMDeviceBrand.sona: return 'sona';
      case CGMDeviceBrand.sinnova: return 'sinnova';
      case CGMDeviceBrand.wellins: return 'wellins';
      case CGMDeviceBrand.microtech: return 'microtech';
    }
  }

  static CGMDeviceBrand fromShortName(String name) {
    for (final b in CGMDeviceBrand.values) {
      if (b.shortName == name) return b;
    }
    return CGMDeviceBrand.none;
  }

  /// 是否需要账号密码
  bool get needsCredentials {
    switch (this) {
      case CGMDeviceBrand.none:
      case CGMDeviceBrand.mock:
        return false;
      default:
        return true;
    }
  }
}

// ========== 抽象连接器接口 ==========

/// CGM 连接器抽象接口
abstract class CGMConnector {
  CGMDeviceBrand get brand;
  String get displayName;
  bool get isConnected;

  Future<bool> connect(Map<String, String> credentials);
  Future<void> disconnect();

  /// 实时血糖流（每5分钟推送一次）
  Stream<CGMRecord> get glucoseStream;

  /// 获取历史记录
  Future<List<CGMRecord>> getHistory({DateTime? since, DateTime? until});

  /// 获取当前血糖值
  Future<CGMRecord?> getCurrentReading();
}

// ========== Mock 连接器 ==========

/// 模拟 CGM 数据连接器（用于演示和开发）
class MockCGMConnector implements CGMConnector {
  @override
  CGMDeviceBrand get brand => CGMDeviceBrand.mock;

  @override
  String get displayName => '模拟数据';

  @override
  bool isConnected = false;

  StreamController<CGMRecord>? _controller;
  Timer? _timer;
  final _random = Random();
  double _currentGlucose = 6.0;
  CGMTrend _currentTrend = CGMTrend.stable;

  @override
  Future<bool> connect(Map<String, String> credentials) async {
    isConnected = true;
    return true;
  }

  @override
  Future<void> disconnect() async {
    isConnected = false;
    _timer?.cancel();
    await _controller?.close();
    _controller = null;
  }

  CGMRecord _generateRecord() {
    // 模拟血糖波动：随机游走 + 均值回归
    final drift = (_random.nextDouble() - 0.5) * 0.3;
    _currentGlucose += drift;

    // 均值回归（向 6.0 靠拢）
    _currentGlucose += (6.0 - _currentGlucose) * 0.02;

    // 偶尔模拟餐后高峰
    final hour = DateTime.now().hour;
    if ((hour == 8 || hour == 12 || hour == 18) && _random.nextDouble() > 0.7) {
      _currentGlucose += 2.0 + _random.nextDouble() * 2.0;
    }

    _currentGlucose = _currentGlucose.clamp(3.0, 16.0);

    // 判断趋势
    final lastTrend = _currentTrend;
    if (drift > 0.15) {
      _currentTrend = CGMTrend.rapidRise;
    } else if (drift > 0.05) {
      _currentTrend = CGMTrend.rise;
    } else if (drift < -0.15) {
      _currentTrend = CGMTrend.rapidFall;
    } else if (drift < -0.05) {
      _currentTrend = CGMTrend.fall;
    } else {
      _currentTrend = CGMTrend.stable;
    }

    // 趋势不能转换太突然
    if ((lastTrend == CGMTrend.rapidRise && _currentTrend == CGMTrend.rapidFall) ||
        (lastTrend == CGMTrend.rapidFall && _currentTrend == CGMTrend.rapidRise)) {
      _currentTrend = CGMTrend.stable;
    }

    return CGMRecord(
      glucose: double.parse(_currentGlucose.toStringAsFixed(1)),
      timestamp: DateTime.now(),
      source: 'mock',
      trend: _currentTrend.trendKey,
      trendArrow: _currentTrend.arrowValue,
    );
  }

  @override
  Stream<CGMRecord> get glucoseStream {
    _controller?.close();
    _controller = StreamController<CGMRecord>.broadcast();

    // 每3秒推送一个模拟值（实际CGM是每5分钟，模拟加速方便测试）
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!isConnected) return;
      _controller!.add(_generateRecord());
    });

    return _controller!.stream;
  }

  @override
  Future<List<CGMRecord>> getHistory({
    DateTime? since,
    DateTime? until,
  }) async {
    final end = until ?? DateTime.now();
    final start = since ?? end.subtract(const Duration(hours: 24));
    final records = <CGMRecord>[];

    // 生成每5分钟一个点的历史数据
    var t = start;
    double glucose = 6.0;
    CGMTrend trend = CGMTrend.stable;

    while (t.isBefore(end)) {
      final drift = (Random(t.millisecondsSinceEpoch).nextDouble() - 0.5) * 0.3;
      glucose += drift;
      glucose += (6.0 - glucose) * 0.02;
      glucose = glucose.clamp(3.0, 16.0);

      final hour = t.hour;
      if (hour == 8 || hour == 12 || hour == 18) {
        glucose += 1.5;
      }

      if (drift > 0.15) trend = CGMTrend.rapidRise;
      else if (drift > 0.05) trend = CGMTrend.rise;
      else if (drift < -0.15) trend = CGMTrend.rapidFall;
      else if (drift < -0.05) trend = CGMTrend.fall;
      else trend = CGMTrend.stable;

      records.add(CGMRecord(
        glucose: double.parse(glucose.toStringAsFixed(1)),
        timestamp: t,
        source: 'mock',
        trend: trend.trendKey,
        trendArrow: trend.arrowValue,
      ));

      t = t.add(const Duration(minutes: 5));
    }

    return records;
  }

  @override
  Future<CGMRecord?> getCurrentReading() async {
    return _generateRecord();
  }
}

// ========== Dexcom 连接器 ==========

/// 德康 Dexcom G6/G7 连接器（通过 Dexcom Share API）
class DexcomCGMConnector implements CGMConnector {
  @override
  CGMDeviceBrand get brand => CGMDeviceBrand.dexcom;

  @override
  String get displayName => '德康 Dexcom';

  @override
  bool isConnected = false;

  String? _sessionId;
  String? _accountId;
  Timer? _pollTimer;
  StreamController<CGMRecord>? _controller;
  String _username = '';
  String _password = '';

  // Dexcom Share API 端点
  static const String _baseUrl = 'https://share2.dexcom.com/ShareWebServices/Services';

  @override
  Future<bool> connect(Map<String, String> credentials) async {
    _username = credentials['username'] ?? '';
    _password = credentials['password'] ?? '';

    if (_username.isEmpty || _password.isEmpty) return false;

    try {
      // 1. 获取 Session ID
      final loginResponse = await http.post(
        Uri.parse('$_baseUrl/General/LoginPublisherAccountById'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'accountName': _username,
          'password': _password,
          'applicationId': 'd89443d2-327c-4a6f-89e5-496bbb0317db',
        }),
      );

      if (loginResponse.statusCode != 200) return false;

      _sessionId = loginResponse.body.trim();
      isConnected = true;

      // 启动轮询
      _startPolling();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      final reading = await getCurrentReading();
      if (reading != null && _controller != null && !_controller!.isClosed) {
        _controller!.add(reading);
      }
    });
  }

  @override
  Future<void> disconnect() async {
    isConnected = false;
    _pollTimer?.cancel();
    _sessionId = null;
    _accountId = null;
    await _controller?.close();
    _controller = null;
  }

  CGMTrend _trendFromDexcom(int direction) {
    switch (direction) {
      case 1: return CGMTrend.rapidRise;
      case 2: return CGMTrend.rise;
      case 3: return CGMTrend.rise;
      case 4: return CGMTrend.stable;
      case 5: return CGMTrend.fall;
      case 6: return CGMTrend.fall;
      case 7: return CGMTrend.rapidFall;
      default: return CGMTrend.unknown;
    }
  }

  @override
  Stream<CGMRecord> get glucoseStream {
    _controller?.close();
    _controller = StreamController<CGMRecord>.broadcast();
    return _controller!.stream;
  }

  @override
  Future<CGMRecord?> getCurrentReading() async {
    if (_sessionId == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/Publisher/ReadPublisherLatestGlucoseValues'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sessionId': _sessionId,
          'minutes': 10,
          'maxCount': 1,
        }),
      );

      if (response.statusCode != 200) return null;

      final List<dynamic> data = json.decode(response.body);
      if (data.isEmpty) return null;

      final entry = data[0] as Map<String, dynamic>;
      final value = entry['Value'];
      final trend = _trendFromDexcom(entry['Trend'] as int? ?? 4);

      return CGMRecord(
        glucose: (value as num).toDouble() / 18, // mg/dL → mmol/L
        timestamp: DateTime.now(),
        source: 'dexcom',
        trend: trend.trendKey,
        trendArrow: trend.arrowValue,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CGMRecord>> getHistory({
    DateTime? since,
    DateTime? until,
  }) async {
    if (_sessionId == null) return [];

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/Publisher/ReadPublisherLatestGlucoseValues'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sessionId': _sessionId,
          'minutes': 1440,
          'maxCount': 288,
        }),
      );

      if (response.statusCode != 200) return [];

      final List<dynamic> data = json.decode(response.body);
      final records = <CGMRecord>[];

      for (final entry in data) {
        final e = entry as Map<String, dynamic>;
        final value = e['Value'] as num;
        final trend = _trendFromDexcom(e['Trend'] as int? ?? 4);
        final ts = DateTime.tryParse(e['WT'] as String? ?? '') ?? DateTime.now();

        records.add(CGMRecord(
          glucose: value.toDouble() / 18,
          timestamp: ts,
          source: 'dexcom',
          trend: trend.trendKey,
          trendArrow: trend.arrowValue,
        ));
      }

      return records;
    } catch (_) {
      return [];
    }
  }
}

// ========== LibreLinkUp 连接器 ==========

/// 雅培瞬感 FreeStyle Libre 连接器（通过 LibreLinkUp API）
class LibreLinkUpConnector implements CGMConnector {
  @override
  CGMDeviceBrand get brand => CGMDeviceBrand.libre;

  @override
  String get displayName => '雅培瞬感 Libre';

  @override
  bool isConnected = false;

  String? _token;
  String? _patientId;
  Timer? _pollTimer;
  StreamController<CGMRecord>? _controller;
  String _email = '';
  String _password = '';

  static const String _baseUrl = 'https://api-eu.libreview.io';

  @override
  Future<bool> connect(Map<String, String> credentials) async {
    _email = credentials['username'] ?? '';
    _password = credentials['password'] ?? '';

    if (_email.isEmpty || _password.isEmpty) return false;

    try {
      final loginResponse = await http.post(
        Uri.parse('$_baseUrl/llu/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'product': 'llu.ios',
          'version': '4.7.0',
        },
        body: json.encode({
          'email': _email,
          'password': _password,
        }),
      );

      if (loginResponse.statusCode != 200) return false;

      final data = json.decode(loginResponse.body);
      _token = data['data']['authToken'] as String?;
      if (_token == null) return false;

      // 获取患者ID
      final patientResponse = await http.get(
        Uri.parse('$_baseUrl/llu/connections'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (patientResponse.statusCode != 200) return false;

      final patientData = json.decode(patientResponse.body);
      final connections = patientData['data'] as List?;
      if (connections == null || connections.isEmpty) return false;

      _patientId = connections[0]['patientId'] as String?;
      isConnected = true;

      _startPolling();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      final reading = await getCurrentReading();
      if (reading != null && _controller != null && !_controller!.isClosed) {
        _controller!.add(reading);
      }
    });
  }

  @override
  Future<void> disconnect() async {
    isConnected = false;
    _pollTimer?.cancel();
    _token = null;
    _patientId = null;
    await _controller?.close();
    _controller = null;
  }

  CGMTrend _trendFromLibre(int? slope) {
    if (slope == null) return CGMTrend.unknown;
    if (slope > 3) return CGMTrend.rapidRise;
    if (slope > 1) return CGMTrend.rise;
    if (slope < -3) return CGMTrend.rapidFall;
    if (slope < -1) return CGMTrend.fall;
    return CGMTrend.stable;
  }

  @override
  Stream<CGMRecord> get glucoseStream {
    _controller?.close();
    _controller = StreamController<CGMRecord>.broadcast();
    return _controller!.stream;
  }

  @override
  Future<CGMRecord?> getCurrentReading() async {
    if (_token == null || _patientId == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/llu/connections/$_patientId/graph'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      final entries = data['data'] as List?;
      if (entries == null || entries.isEmpty) return null;

      final latest = entries.last as Map<String, dynamic>;
      final value = (latest['ValueInMgPerDl'] as num?)?.toDouble() ?? 0;

      // Libre 返回 mg/dL，转为 mmol/L
      final glucose = value / 18;

      final trend = _trendFromLibre(latest['slope'] as int?);

      return CGMRecord(
        glucose: double.parse(glucose.toStringAsFixed(1)),
        timestamp: DateTime.now(),
        source: 'libre',
        trend: trend.trendKey,
        trendArrow: trend.arrowValue,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CGMRecord>> getHistory({
    DateTime? since,
    DateTime? until,
  }) async {
    if (_token == null || _patientId == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/llu/connections/$_patientId/graph'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      final entries = data['data'] as List?;
      if (entries == null) return [];

      final records = <CGMRecord>[];
      for (final entry in entries) {
        final e = entry as Map<String, dynamic>;
        final value = (e['ValueInMgPerDl'] as num?)?.toDouble() ?? 0;
        final ts = DateTime.tryParse(e['Timestamp'] as String? ?? '') ?? DateTime.now();
        final trend = _trendFromLibre(e['slope'] as int?);

        records.add(CGMRecord(
          glucose: double.parse((value / 18).toStringAsFixed(1)),
          timestamp: ts,
          source: 'libre',
          trend: trend.trendKey,
          trendArrow: trend.arrowValue,
        ));
      }

      return records;
    } catch (_) {
      return [];
    }
  }
}

// ========== 工厂类 ==========

/// CGM 连接器工厂
class CGMConnectorFactory {
  static CGMConnector create(CGMDeviceBrand brand) {
    switch (brand) {
      case CGMDeviceBrand.mock:
        return MockCGMConnector();
      case CGMDeviceBrand.dexcom:
        return DexcomCGMConnector();
      case CGMDeviceBrand.libre:
        return LibreLinkUpConnector();
      case CGMDeviceBrand.none:
        return MockCGMConnector(); // fallback to mock for UI testing
      default:
        // 国产CGM暂时用Mock占位
        return MockCGMConnector();
    }
  }

  /// 获取所有可选品牌列表（不含 none）
  static List<CGMDeviceBrand> get availableBrands {
    return CGMDeviceBrand.values.where((b) => b != CGMDeviceBrand.none).toList();
  }
}
