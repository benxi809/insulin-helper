import 'package:flutter/material.dart';
import 'package:glucare_app/app_state.dart';
import 'package:glucare_app/database/local_db.dart';
import 'package:glucare_app/models/models.dart';
import 'package:glucare_app/pages/medication_form_page.dart';
import 'package:glucare_app/utils/notification_service.dart';

/// 用药管理页面 — 药品列表 + 今日打卡
class MedicationPage extends StatefulWidget {
  const MedicationPage({super.key});

  @override
  State<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<MedicationPage> {
  final AppDatabase _db = AppDatabase();
  final NotificationService _notif = NotificationService();
  List<Medication> _medications = [];
  Map<String, dynamic> _todayStats = {};
  List<Map<String, dynamic>> _todayLogs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final meds = await _db.getMedications();
      final stats = await _db.getTodayMedicationStats();
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // 获取带药品信息的打卡记录
      final logs = await _db.getMedicationLogsWithDetails(
        startDate: todayStart,
        endDate: todayEnd,
      );

      // 更新通知提醒
      final activeMeds = meds.where((m) => m.isActive).toList();
      if (activeMeds.isNotEmpty) {
        await _notif.setupAllMedicationReminders(
          activeMeds.map((m) => m.toMap()).toList(),
        );
      }

      setState(() {
        _medications = meds;
        _todayStats = stats;
        _todayLogs = logs;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: $e')),
        );
      }
    }
  }

  Future<void> _addMedication() async {
    final result = await Navigator.push<Medication>(
      context,
      MaterialPageRoute(builder: (_) => const MedicationFormPage()),
    );
    if (result != null) {
      await _db.insertMedication(result);
      _loadData();
    }
  }

  Future<void> _editMedication(Medication med) async {
    final result = await Navigator.push<Medication>(
      context,
      MaterialPageRoute(builder: (_) => MedicationFormPage(medication: med)),
    );
    if (result != null) {
      await _db.updateMedication(result);
      _loadData();
    }
  }

  Future<void> _deleteMedication(Medication med) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${med.name}」吗？\n相关的打卡记录也会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm == true && med.id != null) {
      await _db.deleteMedication(med.id!);
      _loadData();
    }
  }

  /// 标记用餐打卡状态
  Future<void> _markLog(int logId, MedicationStatus status) async {
    // 先从_todayLogs找到当前记录
    final logIdx = _todayLogs.indexWhere((l) => l['id'] == logId);
    if (logIdx == -1) return;

    final log = _todayLogs[logIdx];
    final updated = MedicationLog(
      id: log['id'] as int?,
      medicationId: log['medicationId'] as int,
      scheduledTime: DateTime.parse(log['scheduledTime'] as String),
      takenTime: status == MedicationStatus.taken ? DateTime.now() : null,
      status: status,
      note: log['note'] as String?,
    );
    await _db.updateMedicationLog(updated);
    _loadData();
  }

  /// 根据血糖数据判断是否需要开药提醒
  Future<List<String>> _checkRefillReminders() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final records = await _db.getGlucoseRecords(
      startDate: sevenDaysAgo,
      endDate: now,
    );

    final reminders = <String>[];

    // 检查持续高血糖：空腹 > 7.0 连续3天
    final highDays = <DateTime>{};
    for (final r in records) {
      if (r.tag == GlucoseTag.fasting && r.glucose > 7.0) {
        highDays.add(DateTime(r.timestamp.year, r.timestamp.month, r.timestamp.day));
      }
    }
    if (highDays.length >= 3) {
      reminders.add('⚠️ 近7天有${highDays.length}天空腹血糖偏高(>7.0mmol/L)，建议联系医生调整用药方案。');
    }

    // 检查低血糖风险
    final lowCount = records.where((r) => r.glucose < 3.9).length;
    if (lowCount >= 2) {
      reminders.add('⚠️ 近7天发生${lowCount}次低血糖(<3.9mmol/L)，请关注是否有用药过量风险。');
    }

    return reminders;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final completionRate = (_todayStats['completionRate'] as double? ?? 0) * 100;
    final total = _todayStats['total'] as int? ?? 0;
    final taken = _todayStats['taken'] as int? ?? 0;
    final missed = _todayStats['missed'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('用药管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加药品',
            onPressed: _addMedication,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 今日完成率卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '今日用药',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '$taken/$total',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: completionRate >= 80 ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: completionRate / 100,
                        minHeight: 12,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          completionRate >= 80 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statChip('已服', taken, Colors.green),
                        _statChip('漏服', missed, Colors.red),
                        _statChip('待服', total - taken - missed, Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 开药提醒卡片（如果触发的话）
            FutureBuilder<List<String>>(
              future: _checkRefillReminders(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              '用药提醒',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...snapshot.data!.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(r, style: const TextStyle(fontSize: 13)),
                        )),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 药品列表
            const Text(
              '我的药品',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            if (_medications.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.medication_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        '还没有添加药品',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: _addMedication,
                        child: const Text('添加第一个药品'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._medications.map((med) => _medicationCard(med)),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _medicationCard(Medication med) {
    final times = med.doseTimes;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: med.isActive ? Colors.blue[100] : Colors.grey[100],
          child: Icon(
            Icons.medication,
            color: med.isActive ? Colors.blue : Colors.grey,
          ),
        ),
        title: Text(
          med.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: med.isActive ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${med.dose}${med.unit} · ${_frequencyLabel(med.frequency)}'),
            Text(
              times.map((t) => t).join('  '),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') _editMedication(med);
            if (v == 'delete') _deleteMedication(med);
            if (v == 'toggle') {
              final updated = Medication(
                id: med.id,
                name: med.name,
                dose: med.dose,
                unit: med.unit,
                frequency: med.frequency,
                sortOrder: med.sortOrder,
                doseTimesJson: med.doseTimesJson,
                isActive: !med.isActive,
                createdAt: med.createdAt,
              );
              _db.updateMedication(updated).then((_) => _loadData());
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'toggle',
              child: Text(med.isActive ? '停用' : '启用'),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Text('编辑'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        onTap: () => _editMedication(med),
      ),
    );
  }

  String _frequencyLabel(String freq) {
    switch (freq) {
      case 'daily': return '每天';
      case 'every_other_day': return '隔天';
      case 'weekly': return '每周';
      default: return freq;
    }
  }
}
