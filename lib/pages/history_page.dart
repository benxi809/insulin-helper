/// 历史查询页面
///
/// 参考设计图：20历史查询、历史查询标准界面
/// 功能：
/// - 按类型筛选（全部、大剂量、基础率、报警）
/// - 按日期分组
/// - 查看详情

import 'package:flutter/material.dart';
import 'package:insulin_app/theme/app_colors.dart';
import 'package:insulin_app/theme/app_spacing.dart';
import 'package:insulin_app/theme/app_typography.dart';
import 'package:insulin_app/widgets/widgets.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final PumpService _pumpService = PumpService();

  String _selectedFilter = '全部';
  final List<String> _filters = ['全部', '大剂量', '基础率', '报警'];

  @override
  Widget build(BuildContext context) {
    final deliveries = _pumpService.deliveryHistory;
    final alerts = _pumpService.alerts;

    // 合并并按时间排序
    final allItems = _buildHistoryItems(deliveries, alerts);

    return AppScaffold(
      title: '历史查询',
      showBack: true,
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),

          // ── 筛选标签 ──
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: _filters.map((f) {
                final selected = f == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f, style: const TextStyle(fontSize: 13)),
                    selected: selected,
                    onSelected: (v) => setState(() => _selectedFilter = f),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── 列表 ──
          if (allItems.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 48, color: AppColors.textTertiary),
                    SizedBox(height: 12),
                    Text('暂无历史记录', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: allItems.length,
                itemBuilder: (context, index) {
                  final item = allItems[index];
                  return _buildHistoryCard(item);
                },
              ),
            ),
        ],
      ),
    );
  }

  List<HistoryItem> _buildHistoryItems(
      List<DeliveryRecord> deliveries, List<PumpAlert> alerts) {
    final items = <HistoryItem>[];

    for (final d in deliveries) {
      final match = _selectedFilter == '全部' ||
          (_selectedFilter == '大剂量' && d.type == 'bolus') ||
          (_selectedFilter == '基础率' && (d.type == 'basal' || d.type == 'temp_basal'));
      if (match) {
        items.add(HistoryItem(
          timestamp: d.timestamp,
          title: d.type == 'bolus' ? '大剂量输注' : d.type == 'temp_basal' ? '临时基础率' : '基础输注',
          subtitle: '${d.dose.toStringAsFixed(1)} U${d.note != null ? ' · ${d.note}' : ''}',
          icon: d.type == 'bolus' ? Icons.medical_services : Icons.speed,
          iconColor: d.type == 'bolus' ? AppColors.bolusDose : AppColors.primary,
        ));
      }
    }

    for (final a in alerts) {
      final match = _selectedFilter == '全部' || _selectedFilter == '报警';
      if (match) {
        items.add(HistoryItem(
          timestamp: a.timestamp,
          title: a.title,
          subtitle: a.message,
          icon: a.level == 2 ? Icons.error : Icons.warning_amber_rounded,
          iconColor: a.level == 2 ? AppColors.danger : AppColors.warning,
        ));
      }
    }

    // 按时间倒序
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Widget _buildHistoryCard(HistoryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: item.iconColor.withValues(alpha: 0.15),
          child: Icon(item.icon, color: item.iconColor, size: 20),
        ),
        title: Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${_formatTime(item.timestamp)}  ${item.subtitle}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class HistoryItem {
  final DateTime timestamp;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  HistoryItem({
    required this.timestamp,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });
}
