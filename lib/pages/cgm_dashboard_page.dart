import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:glucare_app/database/local_db.dart';
import 'package:glucare_app/models/models.dart';
import 'package:glucare_app/utils/cgm_connector.dart';

/// CGM 实时仪表盘页面
/// 显示当前血糖、趋势、24小时曲线、TIR、AGP
class CGMDashboardPage extends StatefulWidget {
  const CGMDashboardPage({super.key});

  @override
  State<CGMDashboardPage> createState() => _CGMDashboardPageState();
}

class _CGMDashboardPageState extends State<CGMDashboardPage>
    with AutomaticKeepAliveClientMixin {
  final AppDatabase _db = AppDatabase();
  final DateFormat _timeFormat = DateFormat('HH:mm');

  // CGM 连接器
  CGMConnector? _connector;
  CGMDeviceConfig _cgmConfig = CGMDeviceConfig();
  bool _isConnecting = false;
  String _connectionStatus = '未连接';

  // 实时数据
  CGMRecord? _currentReading;
  List<CGMRecord> _history = [];
  StreamSubscription<CGMRecord>? _streamSub;

  // 统计
  double? _tir; // Time In Range
  int _lowCount = 0; // 低血糖次数
  int _highCount = 0; // 高血糖次数
  double? _avgGlucose;
  double? _gmi; // 预估糖化血红蛋白
  double? _glucoseSd; // 血糖标准差

  // 预警
  String? _alert;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    _cgmConfig = await _db.getCGMConfig();
    if (_cgmConfig.deviceType != 'none' && _cgmConfig.isConnected) {
      await _initConnector();
    }
    await _loadHistory();
  }

  Future<void> _initConnector() async {
    final brand = CGMDeviceBrandExtension.fromShortName(_cgmConfig.deviceType);
    _connector = CGMConnectorFactory.create(brand);

    final creds = <String, String>{};
    if (_cgmConfig.username != null) creds['username'] = _cgmConfig.username!;
    if (_cgmConfig.password != null) creds['password'] = _cgmConfig.password!;

    setState(() {
      _isConnecting = true;
      _connectionStatus = '正在连接...';
    });

    final ok = await _connector!.connect(creds);
    if (ok) {
      setState(() {
        _isConnecting = false;
        _connectionStatus = '已连接 (${_cgmConfig.displayName})';
      });
      _startListening();
    } else {
      setState(() {
        _isConnecting = false;
        _connectionStatus = '连接失败，使用本地数据';
      });
    }
  }

  void _startListening() {
    _streamSub?.cancel();
    _streamSub = _connector?.glucoseStream.listen((record) {
      if (mounted) {
        setState(() {
          _currentReading = record;
        });
        // 保存到本地数据库
        _db.insertCGMRecord(record);
        _checkAlerts(record);
        _updateStats();
      }
    });
  }

  void _checkAlerts(CGMRecord record) {
    setState(() {
      if (record.glucose < 3.9) {
        _alert = '⚠️ 低血糖！当前 ${record.glucose.toStringAsFixed(1)} mmol/L，请立即补糖！';
      } else if (record.glucose > 13.9) {
        _alert = '⚠️ 高血糖！当前 ${record.glucose.toStringAsFixed(1)} mmol/L，建议追加校正剂量';
      } else if (record.glucose < 5.0) {
        _alert = '⚠️ 血糖偏低 (${record.glucose.toStringAsFixed(1)})，建议进食';
      } else {
        _alert = null;
      }
    });
  }

  Future<void> _loadHistory() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 1));
    final cgmRecords = await _db.getCGMRecords(startDate: start, endDate: now);

    // 模拟历史：如果数据库没有CGM数据且未连接真实设备，生成模拟数据
    if (cgmRecords.isEmpty && _connector == null) {
      final mock = MockCGMConnector();
      await mock.connect({});
      final mockHistory = await mock.getHistory(since: start, until: now);
      setState(() => _history = mockHistory);
      _updateStatsFromList(mockHistory);
    } else {
      setState(() => _history = cgmRecords);
      _updateStatsFromList(cgmRecords);
    }
  }

  void _updateStats() {
    final allRecords = List<CGMRecord>.from(_history);
    if (_currentReading != null) allRecords.add(_currentReading!);
    _updateStatsFromList(allRecords);
  }

  void _updateStatsFromList(List<CGMRecord> records) {
    if (records.isEmpty) return;

    final sorted = List<CGMRecord>.from(records);
    sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final recent24h = sorted.where((r) =>
        r.timestamp.isAfter(DateTime.now().subtract(const Duration(hours: 24)))).toList();

    if (recent24h.isEmpty) return;

    double sum = 0;
    double sumSq = 0;
    _lowCount = 0;
    _highCount = 0;

    for (final r in recent24h) {
      sum += r.glucose;
      sumSq += r.glucose * r.glucose;
      if (r.glucose < 3.9) _lowCount++;
      if (r.glucose > 10.0) _highCount++;
    }

    _avgGlucose = sum / recent24h.length;
    _glucoseSd = math.sqrt((sumSq / recent24h.length) - (_avgGlucose! * _avgGlucose!));

    // TIR: 3.9-10.0 mmol/L
    final inRange = recent24h.where((r) => r.glucose >= 3.9 && r.glucose <= 10.0).length;
    _tir = (inRange / recent24h.length) * 100;

    // GMI (预估糖化): 12.71 + 4.70587 * 平均血糖(mmol/L)
    _gmi = 12.71 + 4.70587 * _avgGlucose!;
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _connector?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CGM 动态血糖'),
        actions: [
          // 连接状态指示
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildConnectionBadge(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/cgm_settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== 当前血糖大卡片 =====
            _buildCurrentGlucoseCard(),

            const SizedBox(height: 16),

            // ===== 预警区域 =====
            if (_alert != null) _buildAlertCard(),

            // ===== 统计卡片 =====
            _buildStatsRow(),

            const SizedBox(height: 16),

            // ===== 24h 趋势图 =====
            const Text('24小时血糖趋势',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildTrendChart(),

            const SizedBox(height: 16),

            // ===== AGP 时间分布 =====
            const Text('AGP 血糖分布',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildAGPChart(),

            const SizedBox(height: 16),

            // ===== TIR 详情 =====
            _buildTIRCard(),

            const SizedBox(height: 16),

            // ===== 趋势说明 =====
            if (_currentReading != null)
              _buildTrendDetail(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ==================== 子组件 ====================

  Widget _buildConnectionBadge() {
    Color color;
    String text;

    if (_isConnecting) {
      color = Colors.orange;
      text = '连接中';
    } else if (_connector?.isConnected == true) {
      color = Colors.green;
      text = '已连接';
    } else if (_cgmConfig.deviceType == 'none' || _cgmConfig.deviceType == 'mock') {
      color = Colors.grey;
      text = '模拟';
    } else {
      color = Colors.red;
      text = '离线';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: color, shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _buildCurrentGlucoseCard() {
    final reading = _currentReading;
    final lastHistory = _history.isNotEmpty ? _history.first : null;
    final display = reading ?? lastHistory;

    if (display == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text('暂无CGM数据', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 8),
              Text(_connectionStatus,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    final glucoseColor = _glucoseColor(display.glucose);
    final isFresh = DateTime.now().difference(display.timestamp).inMinutes < 10;

    return Card(
      color: glucoseColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 当前血糖值
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  display.glucose.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: glucoseColor,
                    height: 1.0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    ' mmol/L',
                    style: TextStyle(fontSize: 16, color: glucoseColor.withOpacity(0.7)),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    display.trendIcon,
                    style: TextStyle(fontSize: 32, color: glucoseColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 趋势描述
            Text(
              display.trendDescription,
              style: TextStyle(fontSize: 14, color: glucoseColor.withOpacity(0.8)),
            ),

            const SizedBox(height: 4),

            // 更新时间
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  isFresh
                      ? '刚刚更新'
                      : '${DateTime.now().difference(display.timestamp).inMinutes}分钟前',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(width: 16),
                Text(
                  '来源: ${_deviceSourceName(display.source)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_alert!, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statColumn('平均血糖', _avgGlucose?.toStringAsFixed(1) ?? '--', 'mmol/L', Colors.blue),
            _statColumn('预估HbA1c', _gmi?.toStringAsFixed(1) ?? '--', '%', Colors.purple),
            _statColumn('TIR', _tir?.toStringAsFixed(0) ?? '--', '%', Colors.green),
            _statColumn('标准差', _glucoseSd?.toStringAsFixed(1) ?? '--', '', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(unit, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildTrendChart() {
    if (_history.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: Text('暂无数据')),
        ),
      );
    }

    // 取最近24小时的数据，按时间正序
    final recent = _history
        .where((r) => r.timestamp.isAfter(DateTime.now().subtract(const Duration(hours: 24))))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (recent.isEmpty) {
      return const Card(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text('暂无24小时数据'))));
    }

    final minTime = recent.first.timestamp.millisecondsSinceEpoch.toDouble();
    final maxTime = recent.last.timestamp.millisecondsSinceEpoch.toDouble();
    final timeRange = maxTime - minTime;

    final spots = recent.map((r) {
      final x = ((r.timestamp.millisecondsSinceEpoch.toDouble() - minTime) / timeRange) * 24;
      return FlSpot(x, r.glucose);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 2.0,
              maxY: 16.0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 2,
                getDrawingHorizontalLine: (value) {
                  Color color;
                  if (value >= 3.9 && value <= 10.0) {
                    color = Colors.green.withOpacity(0.15);
                  } else {
                    color = Colors.red.withOpacity(0.1);
                  }
                  return FlLine(color: color, strokeWidth: 1);
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 4,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 4,
                    getTitlesWidget: (value, meta) {
                      final idx = (value / 24 * recent.length).round().clamp(0, recent.length - 1);
                      final t = recent[idx].timestamp;
                      return Text(
                        '${t.hour}:00',
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // 目标范围填充
                LineChartBarData(
                  spots: [FlSpot(0, 3.9), FlSpot(24, 3.9)],
                  isStepLineChart: true,
                  color: Colors.transparent,
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withOpacity(0.05),
                    cutOffY: 10.0,
                    applyCutOffY: true,
                  ),
                ),
                // 血糖曲线
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: Colors.blue,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final idx = (spot.x / 24 * recent.length).round().clamp(0, recent.length - 1);
                      final t = recent[idx].timestamp;
                      return LineTooltipItem(
                        '${t.hour}:${t.minute.toString().padLeft(2, '0')}\n${spot.y.toStringAsFixed(1)} mmol/L',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAGPChart() {
    if (_history.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(40), child: Text('暂无数据')));
    }

    // 按小时分组统计
    final hourlyData = <int, List<double>>{};
    for (final r in _history) {
      final hour = r.timestamp.hour;
      hourlyData.putIfAbsent(hour, () => []);
      hourlyData[hour]!.add(r.glucose);
    }

    final spots = <BarChartGroupData>[];
    for (var h = 0; h < 24; h++) {
      final values = hourlyData[h];
      if (values == null || values.isEmpty) continue;

      values.sort();
      final median = values[values.length ~/ 2];
      final p25 = values[(values.length * 0.25).round().clamp(0, values.length - 1)];
      final p75 = values[(values.length * 0.75).round().clamp(0, values.length - 1)];

      spots.add(BarChartGroupData(
        x: h,
        barRods: [
          BarChartRodData(
            toY: median,
            color: median >= 3.9 && median <= 10.0 ? Colors.green : Colors.orange,
            width: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: p75,
              color: Colors.blue.withOpacity(0.15),
            ),
          ),
        ],
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                )),
                const SizedBox(width: 4),
                const Text(' IQR范围', style: TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(width: 16),
                Container(width: 10, height: 10, decoration: BoxDecoration(
                  color: Colors.green, borderRadius: BorderRadius.circular(2),
                )),
                const SizedBox(width: 4),
                const Text(' 中位数', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 3,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}:00',
                              style: const TextStyle(fontSize: 9, color: Colors.grey));
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: spots,
                  maxY: 16,
                  minY: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTIRCard() {
    final inRange = _tir ?? 0;
    final below = ((100 - inRange) * (_lowCount / math.max(_lowCount + _highCount, 1))).clamp(0, 100 - inRange);
    final above = (100 - inRange - below).clamp(0, 100 - inRange);

    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('目标范围时间 (TIR)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            // TIR 进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 24,
                child: Row(
                  children: [
                    Flexible(
                      flex: _lowCount,
                      child: Container(color: Colors.red.shade300),
                    ),
                    Flexible(
                      flex: (inRange).round(),
                      child: Container(color: Colors.green),
                    ),
                    Flexible(
                      flex: _highCount,
                      child: Container(color: Colors.orange.shade300),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _tirLegend('低血糖 ${_lowCount}次', Colors.red.shade300),
                const SizedBox(width: 16),
                _tirLegend('达标 ${inRange.toStringAsFixed(0)}%', Colors.green),
                const SizedBox(width: 16),
                _tirLegend('高血糖 ${_highCount}次', Colors.orange.shade300),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'GMI (预估HbA1c): ${_gmi?.toStringAsFixed(1) ?? '--'}%'
              '  ·  血糖变异系数: ${_avgGlucose != null && _glucoseSd != null ? (_glucoseSd! / _avgGlucose! * 100).toStringAsFixed(0) : '--'}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tirLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildTrendDetail() {
    if (_currentReading == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('趋势说明', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _trendAction('当前趋势', _currentReading!.trendDescription),
            _trendAction('建议频率', _currentReading!.glucose < 3.9 ? '立即测量毛细血管血糖' : '每5分钟自动监测'),
            if (_currentReading!.glucose > 10.0)
              _trendAction('下一步', '考虑校正剂量，检查酮体'),
            if (_currentReading!.glucose < 5.0)
              _trendAction('下一步', '准备快速升糖食物，防止低血糖'),
          ],
        ),
      ),
    );
  }

  Widget _trendAction(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Color _glucoseColor(double g) {
    if (g < 3.9) return Colors.red;
    if (g < 5.0) return Colors.orange;
    if (g <= 10.0) return Colors.green;
    return Colors.red;
  }

  String _deviceSourceName(String source) {
    switch (source) {
      case 'dexcom': return '德康';
      case 'libre': return '雅培';
      case 'mock': return '模拟';
      default: return source;
    }
  }
}
