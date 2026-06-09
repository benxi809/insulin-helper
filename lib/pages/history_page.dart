/// 历史记录页面 — 血糖记录查询
import 'package:flutter/material.dart';
import 'package:insulin_app/models/models.dart';
import 'package:insulin_app/state/app_state.dart';
import 'package:insulin_app/theme/app_colors.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final AppState _appState = AppState();
  List<GlucoseRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _loading = true);
    _records = await _appState.db.getGlucoseRecords(limit: 100);
    if (mounted) setState(() => _loading = false);
  }

  Color _glucoseColor(double g) {
    if (g < 3.9) return AppColors.danger;
    if (g < 5.0) return AppColors.warning;
    if (g <= 7.2) return AppColors.success;
    if (g <= 10.0) return AppColors.warning;
    return AppColors.danger;
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecords,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 48, color: AppColors.textTertiary),
                      const SizedBox(height: 12),
                      const Text('暂无记录', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final r = _records[index];
                    final gColor = _glucoseColor(r.glucose);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: gColor.withValues(alpha: 0.15),
                          child: Text(
                            r.glucose.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: gColor,
                            ),
                          ),
                        ),
                        title: Text(
                          _formatTime(r.timestamp),
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          r.note ?? '',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          '${r.glucose.toStringAsFixed(1)} mmol/L',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: gColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
