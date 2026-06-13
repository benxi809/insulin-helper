/// 首页 — 血糖概览
import 'package:flutter/material.dart';
import 'package:glucare_app/app_state.dart';
import 'package:glucare_app/theme/app_colors.dart';
import 'package:glucare_app/widgets/widgets.dart';
import 'package:glucare_app/models/models.dart';
import 'package:glucare_app/database/local_db.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserConfig _config = UserConfig();
  List<GlucoseRecord> _recentGlucose = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _config = await AppDatabase().getConfig();
      _recentGlucose = await AppDatabase().getGlucoseRecords(limit: 5);
    } catch (e) {
      debugPrint('HomePage._loadData error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Color _glucoseColor(double g) {
    if (g < 3.9) return AppColors.danger;
    if (g < 5.0) return AppColors.warning;
    if (g <= 7.2) return AppColors.success;
    if (g <= 10.0) return AppColors.warning;
    return AppColors.danger;
  }

  double? get _latestGlucose =>
      _recentGlucose.isNotEmpty ? _recentGlucose.first.glucose : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('GluCare'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/patient_profile'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
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
                  _buildGlucoseCard(),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  const SizedBox(height: 16),
                  _buildInsightCard(),
                  const SizedBox(height: 16),
                  if (_recentGlucose.isNotEmpty) _buildRecentGlucoseSection(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildGlucoseCard() {
    final latestGlucose = _latestGlucose;
    final glucoseStr = latestGlucose?.toStringAsFixed(1) ?? '--';
    final gColor = latestGlucose != null
        ? _glucoseColor(latestGlucose)
        : AppColors.textTertiary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('当前血糖', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                glucoseStr,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(' mmol/L', style: TextStyle(color: Colors.white70, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem(Icons.access_time, '空腹', _config.targetGlucoseMin.toStringAsFixed(1)),
              _statItem(Icons.restaurant, '餐后', _config.targetGlucoseMax.toStringAsFixed(1)),
              _statItem(Icons.timeline, '每日记录', '${_recentGlucose.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('快捷操作', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _actionChip(context, Icons.add, '记录血糖', () => Navigator.pushNamed(context, '/camera_food'))),
                const SizedBox(width: 8),
                Expanded(child: _actionChip(context, Icons.calculate, '剂量计算', () => Navigator.pushNamed(context, '/calculator'))),
                const SizedBox(width: 8),
                Expanded(child: _actionChip(context, Icons.search, '食物搜索', () => Navigator.pushNamed(context, '/food_picker'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('今日洞察', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _insightTile(Icons.show_chart, '最高', '7.8', AppColors.warning)),
                const SizedBox(width: 8),
                Expanded(child: _insightTile(Icons.show_chart, '最低', '4.2', AppColors.success)),
                const SizedBox(width: 8),
                Expanded(child: _insightTile(Icons.trending_up, '平均值', '6.1', AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Text('${DateTime.now().month}月${DateTime.now().day}日 · 共${_recentGlucose.length}次记录',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightTile(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
      ],
    );
  }

  Widget _buildRecentGlucoseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text('最近记录', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 8),
        ..._recentGlucose.take(4).map((r) => Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: _glucoseColor(r.glucose).withValues(alpha: 0.2),
                  child: Text(
                    r.glucose.toStringAsFixed(1),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _glucoseColor(r.glucose)),
                  ),
                ),
                title: Text(
                  '${r.timestamp.hour.toString().padLeft(2, '0')}:${r.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  r.note ?? '',
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  '${r.glucose.toStringAsFixed(1)} mmol/L',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _glucoseColor(r.glucose),
                  ),
                ),
              ),
            )),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/report'),
            icon: const Icon(Icons.bar_chart, size: 16),
            label: const Text('查看完整报告'),
          ),
        ),
      ],
    );
  }
}
