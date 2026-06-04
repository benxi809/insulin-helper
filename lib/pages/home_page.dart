import 'package:flutter/material.dart';
import 'package:insulin_app/database/local_db.dart';
import 'package:insulin_app/models/models.dart';

/// 首页 — 血糖记录
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AppDatabase _db = AppDatabase();
  List<GlucoseRecord> _records = [];
  Map<String, dynamic>? _todaySummary;
  UserConfig _config = UserConfig();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final records = await _db.getGlucoseRecords(limit: 20);
    final today = DateTime.now();
    final summary = await _db.getDailySummary(today);
    final config = await _db.getConfig();
    if (mounted) {
      setState(() {
        _records = records;
        _todaySummary = summary;
        _config = config;
        _loading = false;
      });
    }
  }

  Color _glucoseColor(double g) {
    if (g < 3.9) return Colors.red;
    if (g < 5.0) return Colors.orange;
    if (g <= 7.2) return Colors.green;
    if (g <= 10.0) return Colors.orange;
    return Colors.red;
  }

  void _showAddDialog() {
    final glucoseCtrl = TextEditingController();
    final tagCtrl = ValueNotifier<GlucoseTag>(GlucoseTag.preMeal);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('录入血糖', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: glucoseCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '血糖值 (mmol/L)',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<GlucoseTag>(
              valueListenable: tagCtrl,
              builder: (_, tag, __) => Row(
                children: GlucoseTag.values.map((t) {
                  final selected = t == tag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t.displayName, style: const TextStyle(fontSize: 13)),
                      selected: selected,
                      onSelected: (_) => tagCtrl.value = t,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () async {
                  final val = double.tryParse(glucoseCtrl.text);
                  if (val == null) return;
                  await _db.insertGlucose(GlucoseRecord(
                    glucose: val,
                    timestamp: DateTime.now(),
                    tag: tagCtrl.value,
                  ));
                  Navigator.pop(ctx);
                  _loadData();
                },
                child: const Text('保存', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insulin Helper'),
        actions: [
          // 患者信息快速入口
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            tooltip: '患者信息',
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
                  // 患者信息快捷卡片
                  if (_config.patientName.isNotEmpty) _buildPatientCard(),
                  // 今日摘要卡片
                  _buildTodayCard(),
                  const SizedBox(height: 16),
                  // 下次测量提醒（如果最近30分钟内无记录）
                  if (_records.isNotEmpty) _buildReminder(),
                  const SizedBox(height: 16),
                  // 快捷功能
                  _buildQuickActions(),
                  // 最近记录标题
                  const Text('最近记录',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  // 记录列表
                  ..._records.map((r) => _buildRecordItem(r)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPatientCard() {
    final name = _config.patientName;
    final typeStr = _config.diabetesType == 1 ? '1型' : '2型';
    return Card(
      color: Colors.blue.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade200,
          child: Text(
            name.isNotEmpty ? name[0] : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$typeStr 糖尿病 · ${_config.age}岁 · HbA1c ${_config.hba1c?.toStringAsFixed(1) ?? '--'}%'),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => Navigator.pushNamed(context, '/profile'),
      ),
    );
  }

  Widget _buildTodayCard() {
    final s = _todaySummary;
    if (s == null) return const SizedBox.shrink();

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('今日概览', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  '${s['recordCount']}次测量',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('最高', s['maxGlucose']?.toStringAsFixed(1) ?? '--', Colors.red),
                _statItem('最低', s['minGlucose']?.toStringAsFixed(1) ?? '--', Colors.green),
                _statItem('平均', s['avgGlucose']?.toStringAsFixed(1) ?? '--', Colors.blue),
                _statItem('胰岛素', '${(s['totalDose'] as double?)?.toStringAsFixed(0) ?? '0'}U', Colors.purple),
              ],
            ),
              if ((s['lowCount'] as int? ?? 0 ) > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '⚠️ 低血糖 ${s['lowCount']} 次',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildReminder() {
    final last = _records.first;
    final minutesSince = DateTime.now().difference(last.timestamp).inMinutes;
    if (minutesSince < 30) return const SizedBox.shrink();

    return Card(
      color: Colors.yellow.shade50,
      child: ListTile(
        leading: const Icon(Icons.access_time, color: Colors.orange),
        title: Text('距上次测量已 $minutesSince 分钟'),
        subtitle: const Text('建议按时测量'),
        trailing: IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            // 触发新增血糖记录
          },
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: ActionChip(
              avatar: const Icon(Icons.camera_alt, size: 18, color: Colors.green),
              label: const Text('拍照识食物', style: TextStyle(fontSize: 13)),
              onPressed: () => Navigator.pushNamed(context, '/camera_food'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ActionChip(
              avatar: const Icon(Icons.restaurant_menu, size: 18, color: Colors.orange),
              label: const Text('碳水库', style: TextStyle(fontSize: 13)),
              onPressed: () => Navigator.pushNamed(context, '/foods'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(GlucoseRecord r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: _glucoseColor(r.glucose).withOpacity(0.2),
          child: Text(
            r.glucose.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _glucoseColor(r.glucose),
            ),
          ),
        ),
        title: Text(
          '${_formatTime(r.timestamp)}  ${r.tag.displayName}',
          style: const TextStyle(fontSize: 14),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
          onPressed: () async {
            if (r.id != null) {
              await _db.deleteGlucose(r.id!);
              _loadData();
            }
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
