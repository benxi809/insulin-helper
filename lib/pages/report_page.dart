import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:glucare_app/database/local_db.dart';
import 'package:glucare_app/models/models.dart';

/// 报告页 — 数据图表与导出（含CGM数据）
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final AppDatabase _db = AppDatabase();
  Map<String, dynamic>? _summary;
  bool _loading = true;

  final List<DateTime> _recentDays = List.generate(
    7,
    (i) => DateTime.now().subtract(Duration(days: i)),
  );

  final Map<String, Map<String, dynamic>> _dailySummaries = {};

  // CGM 数据
  List<CGMRecord> _cgmRecords = [];
  double? _cgmAvgGlucose;
  double? _cgmTIR;
  int _cgmLowCount = 0;
  int _cgmHighCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final todaySummary = await _db.getDailySummary(DateTime.now());
    for (final day in _recentDays) {
      final ds = await _db.getDailySummary(day);
      _dailySummaries[_dateKey(day)] = ds;
    }

    // 加载 CGM 数据
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    _cgmRecords = await _db.getCGMRecords(startDate: weekAgo);
    _calcCGMStats();

    if (mounted) {
      setState(() {
        _summary = todaySummary;
        _loading = false;
      });
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _dateLabel(DateTime d) => '${d.month}/${d.day}';

  String get _weekLabel {
    final end = _recentDays.first;
    final start = _recentDays.last;
    return '${start.month}/${start.day} - ${end.month}/${end.day}';
  }

  void _calcCGMStats() {
    if (_cgmRecords.isEmpty) return;

    double sum = 0;
    _cgmLowCount = 0;
    _cgmHighCount = 0;

    for (final r in _cgmRecords) {
      sum += r.glucose;
      if (r.glucose < 3.9) _cgmLowCount++;
      if (r.glucose > 10.0) _cgmHighCount++;
    }

    _cgmAvgGlucose = sum / _cgmRecords.length;
    final inRange = _cgmRecords.where((r) => r.glucose >= 3.9 && r.glucose <= 10.0).length;
    _cgmTIR = (inRange / _cgmRecords.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('报告'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('导出功能将在后续版本实现')),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(_weekLabel,
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _statCard(
                              '平均血糖',
                              '${(_summary?['avgGlucose'] ?? '--')}',
                              'mmol/L',
                              Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _statCard(
                              '日均胰岛素',
                              ((_summary?['totalDose'] as double?)?.toStringAsFixed(0) ?? '--'),
                              'U',
                              Colors.purple)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('血糖趋势（7天）',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  _buildTrendChart(),
                  const SizedBox(height: 20),
                  // CGM 统计（如果有数据）
                  if (_cgmRecords.isNotEmpty) ...[
                    const Text('CGM 动态血糖（7天）',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    _buildCGMStatsCard(),
                    const SizedBox(height: 20),
                  ],
                  _buildStats(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download),
                      label: const Text('导出报告（PDF/CSV）'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _statCard(
      String label, String value, String unit, MaterialColor color) {
    return Card(
      color: color.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: color.shade700)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color.shade700)),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(unit,
                      style:
                          TextStyle(fontSize: 13, color: color.shade400)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _recentDays.reversed.map((day) {
                final key = _dateKey(day);
                final avg =
                    (_dailySummaries[key]?['avgGlucose'] as double?) ?? 0;
                final maxH = (avg / 15.0).clamp(0.05, 1.0);
                final isToday =
                    _dateKey(day) == _dateKey(DateTime.now());

                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        Text(avg > 0 ? avg.toStringAsFixed(1) : '',
                            style: const TextStyle(
                                fontSize: 9, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Container(
                          height: 100 * maxH,
                          decoration: BoxDecoration(
                            color: isToday
                                ? Colors.blue
                                : Colors.blue.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_dateLabel(day),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCGMStatsCard() {
    final gmi = _cgmAvgGlucose != null ? 12.71 + 4.70587 * _cgmAvgGlucose! : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _statCGMItem('CGM平均', '${_cgmAvgGlucose?.toStringAsFixed(1) ?? '--'}', 'mmol/L', Colors.blue)),
                Expanded(child: _statCGMItem('TIR', '${_cgmTIR?.toStringAsFixed(0) ?? '--'}', '%', Colors.green)),
                Expanded(child: _statCGMItem('GMI', '${gmi?.toStringAsFixed(1) ?? '--'}', '%', Colors.purple)),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('低血糖 $_cgmLowCount 次', style: TextStyle(fontSize: 12, color: Colors.red.shade600)),
                const SizedBox(width: 16),
                Text('高血糖 $_cgmHighCount 次', style: TextStyle(fontSize: 12, color: Colors.orange.shade600)),
                const Spacer(),
                Text('${_cgmRecords.length} 个读数', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCGMItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text('$unit $label', style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('本周统计',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            _statLine('目标达标率', '5.0-7.2 mmol/L', '68%'),
            const Divider(height: 16),
            _statLine('低血糖次数', '< 3.9',
                '${_summary?['lowCount'] ?? 0} 次'),
            const Divider(height: 16),
            _statLine('测量次数', '',
                '${_summary?['recordCount'] ?? 0} 次'),
          ],
        ),
      ),
    );
  }

  Widget _statLine(String label, String detail, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        if (detail.isNotEmpty)
          Text(detail,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
