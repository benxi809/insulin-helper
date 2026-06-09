/// 基础率设置页面
///
/// 参考设计图：17基础率设置、33基础率编辑、16-1收缩态、16-2命名、13更换曲线
/// 功能：
/// - 时间-剂量表格展示
/// - 编辑模式（添加/修改/删除时段）
/// - 基础率曲线命名
/// - 日总量统计

import 'package:flutter/material.dart';
import 'package:insulin_app/models/pump_models.dart';
import 'package:insulin_app/services/pump_service.dart';
import 'package:insulin_app/theme/app_colors.dart';
import 'package:insulin_app/theme/app_spacing.dart';
import 'package:insulin_app/theme/app_typography.dart';
import 'package:insulin_app/widgets/widgets.dart';

class BasalRatePage extends StatefulWidget {
  const BasalRatePage({super.key});

  @override
  State<BasalRatePage> createState() => _BasalRatePageState();
}

class _BasalRatePageState extends State<BasalRatePage> {
  final PumpService _pumpService = PumpService();
  late BasalRateProfile _profile;
  bool _loading = true;
  bool _editMode = false;
  final TextEditingController _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _profile = _pumpService.basalProfile;
    _nameCtrl.text = _profile.name;
    _loading = false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final updatedProfile = BasalRateProfile(
      name: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : '未命名基础率',
      segments: List.from(_profile.segments),
    );
    await _pumpService.sendBasalProfile(updatedProfile);
    setState(() => _profile = updatedProfile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('基础率已保存'), duration: Duration(seconds: 2)),
      );
    }
  }

  void _addSegment() {
    // 在最后添加新的时段
    final lastHour = _profile.segments.isNotEmpty ? _profile.segments.last.startHour + 1 : 0;
    if (lastHour >= 24) return;

    setState(() {
      _profile = BasalRateProfile(
        name: _profile.name,
        segments: [
          ..._profile.segments,
          BasalRateSegment(startHour: lastHour.clamp(0, 23), rate: 0.8),
        ],
      );
    });
  }

  void _editSegment(int index) {
    final seg = _profile.segments[index];
    final hourCtrl = TextEditingController(text: seg.startHour.toStringAsFixed(1));
    final rateCtrl = TextEditingController(text: seg.rate.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑基础率时段'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hourCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '起始时间 (小时)', isDense: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rateCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '基础率 (U/h)', isDense: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _profile = BasalRateProfile(
                  name: _profile.name,
                  segments: _profile.segments.where((s) => s != seg).toList(),
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: AppColors.danger)),
          ),
          const Spacer(),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final hour = double.tryParse(hourCtrl.text);
              final rate = double.tryParse(rateCtrl.text);
              if (hour != null && rate != null && hour >= 0 && hour < 24) {
                final updated = <BasalRateSegment>[];
                for (int i = 0; i < _profile.segments.length; i++) {
                  if (i == index) {
                    updated.add(BasalRateSegment(startHour: hour, rate: rate));
                  } else {
                    updated.add(_profile.segments[i]);
                  }
                }
                setState(() {
                  _profile = BasalRateProfile(
                    name: _profile.name,
                    segments: updated,
                  );
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return AppScaffold(
      title: '基础率设置',
      showBack: true,
      actions: [
        IconButton(
          icon: Icon(_editMode ? Icons.check : Icons.edit),
          onPressed: () {
            setState(() => _editMode = !_editMode);
            if (!_editMode) _saveProfile();
          },
          tooltip: _editMode ? '完成编辑' : '编辑',
        ),
      ],
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),

          // ── 名称编辑 ──
          _buildNameSection(),

          const SizedBox(height: AppSpacing.md),

          // ── 日总量统计 ──
          _buildTotalSummary(),

          const SizedBox(height: AppSpacing.md),

          // ── 时段表格 ──
          _buildSegmentsTable(),

          if (_editMode) ...[
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: '添加时段',
              icon: Icons.add,
              onPressed: _profile.segments.length < 24 ? _addSegment : null,
            ),
          ],

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildNameSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          const Icon(Icons.label_outline, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _editMode
                ? TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: '基础率名称',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  )
                : Text(
                    _profile.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
          ),
          if (!_editMode)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textTertiary),
              onPressed: () => setState(() => _editMode = true),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: DataCard(
        title: '24小时基础总量',
        value: _profile.totalDailyBasal.toStringAsFixed(2),
        unit: 'U',
        icon: Icons.inventory_2,
        compact: true,
      ),
    );
  }

  Widget _buildSegmentsTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 表头
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  const Expanded(child: Text('时段', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  const Expanded(child: Text('起始', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  const Expanded(
                    child: Text('剂量 (U/h)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.right),
                  ),
                  if (_editMode) const SizedBox(width: 40),
                ],
              ),
            ),
            // 数据行
            ...List.generate(_profile.segments.length, (index) {
              final seg = _profile.segments[index];
              final nextHour = index + 1 < _profile.segments.length
                  ? _profile.segments[index + 1].startHour
                  : 24.0;
              final duration = nextHour - seg.startHour;

              return InkWell(
                onTap: _editMode ? () => _editSegment(index) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
                  decoration: index < _profile.segments.length - 1
                      ? const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.dividerLight)))
                      : null,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '时段 ${index + 1}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          seg.timeDisplay,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          seg.rate.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      if (_editMode)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.edit_outlined, size: 16, color: AppColors.textTertiary),
                        ),
                    ],
                  ),
                ),
              );
            }),
            // 表尾 — 合计
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
                color: AppColors.primaryLight,
              ),
              child: Row(
                children: [
                  const Expanded(child: Text('合计', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Expanded(
                    child: Text(
                      '${_profile.segments.length}个时段',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${_profile.totalDailyBasal.toStringAsFixed(2)} U/天',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  if (_editMode) const SizedBox(width: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
