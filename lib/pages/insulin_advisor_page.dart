import 'package:flutter/material.dart';
import 'package:glucare_app/database/local_db.dart';
import 'package:glucare_app/models/models.dart';
import 'package:glucare_app/calculators/basal_estimator.dart';

/// 基础率估算 + 饮食推荐页面
class InsulinAdvisorPage extends StatefulWidget {
  const InsulinAdvisorPage({super.key});

  @override
  State<InsulinAdvisorPage> createState() => _InsulinAdvisorPageState();
}

class _InsulinAdvisorPageState extends State<InsulinAdvisorPage> {
  final AppDatabase _db = AppDatabase();
  bool _loading = true;
  UserConfig _config = UserConfig();
  List<CGMRecord> _cgmRecords = [];

  // 计算结果
  BasalProfile? _basalProfile;
  List<MealSuggestion> _mealSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      _config = await _db.getConfig();

      // 获取CGM历史数据（最近3天）
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      _cgmRecords = await _db.getCGMRecords(startDate: threeDaysAgo);
    } catch (e) {
      debugPrint('InsulinAdvisorPage._loadData error: $e');
    }

    if (mounted) {
      setState(() => _loading = false);
      _analyze();
    }
  }

  void _analyze() {
    // 基础率估算
    _basalProfile = BasalEstimator.estimate(
      cgmRecords: _cgmRecords,
      config: _config,
    );

    // 获取当前血糖（最新CGM记录或者用最后一次毛细血管血糖）
    final latestCGM = _cgmRecords.isNotEmpty ? _cgmRecords.first : null;
    final currentGlucose = latestCGM?.glucose ?? _config.targetGlucoseMax;

    // 最近趋势（最后5个点）
    final recentTrend = _cgmRecords.take(5).toList();

    // 饮食推荐
    _mealSuggestions = MealAdvisor.recommend(
      currentGlucose: currentGlucose,
      config: _config,
      recentTrend: recentTrend,
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能推荐'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '刷新分析',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== 当前状态摘要 =====
            _buildStatusSummary(),

            const SizedBox(height: 20),

            // ===== 饮食推荐 =====
            const Text('饮食建议',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._mealSuggestions.map((s) => _buildMealCard(s)),

            const SizedBox(height: 24),

            // ===== 基础率推荐 =====
            const Text('基础率推荐',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '每日基础总量: ${_basalProfile?.totalDailyBasal.toStringAsFixed(1) ?? '--'} U'
              '  ·  ${_cgmRecords.length} 个数据点',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (_basalProfile != null) _buildBasalTable(),

            const SizedBox(height: 12),

            // ===== 分析说明 =====
            if (_basalProfile != null)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('分析说明',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(_basalProfile!.analysis,
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),

            // ===== 建议列表 =====
            if (_basalProfile != null && _basalProfile!.suggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('调整建议',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ..._basalProfile!.suggestions.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 13)),
                            Expanded(child: Text(s, style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSummary() {
    final latestCGM = _cgmRecords.isNotEmpty ? _cgmRecords.first : null;
    final glucose = latestCGM?.glucose;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('当前状态', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    glucose != null
                        ? '血糖 ${glucose.toStringAsFixed(1)} mmol/L'
                        : '暂无CGM数据',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: glucose != null ? _glucoseColor(glucose) : Colors.grey,
                    ),
                  ),
                  if (latestCGM != null) ...{
                    Text(
                      '${latestCGM.trendIcon} ${latestCGM.trendDescription}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  },
                ],
              ),
            ),
            Column(
              children: [
                Text('CGM数据', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('${_cgmRecords.length} 条',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(MealSuggestion meal) {
    Color headerColor;
    IconData icon;

    if (meal.mealType == '紧急处理') {
      headerColor = Colors.red;
      icon = Icons.warning;
    } else if (meal.mealType == '预警') {
      headerColor = Colors.orange;
      icon = Icons.info_outline;
    } else {
      headerColor = Colors.green;
      icon = Icons.restaurant;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: headerColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, color: headerColor, size: 18),
                const SizedBox(width: 8),
                Text(meal.mealType,
                    style: TextStyle(fontWeight: FontWeight.bold, color: headerColor)),
                const Spacer(),
                if (meal.recommendedCarbs > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: headerColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${meal.recommendedCarbs.toStringAsFixed(0)}g 碳水',
                      style: TextStyle(fontSize: 11, color: headerColor, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
          // 内容
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.suggestion, style: const TextStyle(fontSize: 14)),
                if (meal.foodExamples.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('推荐食物:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  ...meal.foodExamples.map((f) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 4, color: Colors.grey.shade400),
                        const SizedBox(width: 6),
                        Text(f, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  )),
                ],
                if (meal.reason.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(meal.reason,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasalTable() {
    if (_basalProfile == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 表头
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 12),
                  Expanded(flex: 2, child: Text('时段', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('基础率', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('说明', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const Divider(height: 1),
            // 数据行
            ..._basalProfile!.segments.map((seg) => Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(seg.timeLabel, style: const TextStyle(fontSize: 12)),
                  ),
                  Expanded(
                    child: Text(
                      '${seg.rate.toStringAsFixed(2)} U/h',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: seg.rate > 0 ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      seg.reason.length > 12 ? '${seg.reason.substring(0, 12)}...' : seg.reason,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color _glucoseColor(double g) {
    if (g < 3.9) return Colors.red;
    if (g < 5.0) return Colors.orange;
    if (g <= 10.0) return Colors.green;
    return Colors.red;
  }
}
