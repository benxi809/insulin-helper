import 'package:flutter/material.dart';
import 'package:insulin_app/database/local_db.dart';
import 'package:insulin_app/models/models.dart';
import 'package:insulin_app/utils/notification_service.dart';

/// 设置页 — 含提醒设置和患者信息入口
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AppDatabase _db = AppDatabase();
  final NotificationService _notif = NotificationService();
  UserConfig _config = UserConfig();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    _config = await _db.getConfig();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveConfig() async {
    await _db.updateConfig(_config);
    // 同步更新提醒
    await _notif.setupReminders(
      breakfast: _config.reminderBreakfast,
      lunch: _config.reminderLunch,
      dinner: _config.reminderDinner,
      bedtime: _config.reminderBedtime,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已保存')),
      );
    }
  }

  Future<void> _initReminders() async {
    await _notif.init();
    await _notif.requestPermissions();
    await _saveConfig();
  }

  void _editField(String label, double currentValue, Function(double) onSave) {
    final ctrl = TextEditingController(text: currentValue.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('设置 $label'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null && val > 0) {
                onSave(val);
                _saveConfig();
              }
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除所有数据？'),
        content: const Text('这将删除所有血糖记录、注射记录和自定义设置。此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = await _db.database;
      await db.delete('glucose_records');
      await db.delete('insulin_doses');
      await db.delete('user_config');
      await db.insert('user_config', UserConfig().toMap());
      await _notif.cancelAll();
      _loadConfig();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('所有数据已清除')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== 患者信息入口 =====
          _buildConfigTile(
            icon: Icons.person,
            title: '患者信息',
            subtitle: '姓名 · 年龄 · 糖尿病类型 · 诊断记录',
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          const SizedBox(height: 12),

          // ===== 设备连接 =====
          _sectionHeader('设备连接'),
          const SizedBox(height: 4),
          _buildConfigTile(
            icon: Icons.show_chart,
            title: 'CGM 动态血糖仪',
            subtitle: '德康 · 雅培 · 动态血糖监测',
            onTap: () => Navigator.pushNamed(context, '/cgm_settings'),
          ),
          _buildConfigTile(
            icon: Icons.smartphone_outlined,
            title: 'AI 智能眼镜',
            subtitle: '拍照识别食物 · 雷鸟 · INMO',
            onTap: () => Navigator.pushNamed(context, '/ai_glasses_settings'),
          ),
          const SizedBox(height: 12),

          // ===== 胰岛素参数 =====
          _sectionHeader('胰岛素参数'),
          const SizedBox(height: 4),
          _buildConfigTile(
            icon: Icons.speed,
            title: '胰岛素敏感系数 ISF',
            subtitle: '${_config.isf.toStringAsFixed(2)} mmol/L · 每1U胰岛素降低的血糖值',
            onTap: () => _editField('ISF', _config.isf, (v) => setState(() => _config.isf = v)),
          ),
          _buildConfigTile(
            icon: Icons.grain,
            title: '碳水系数 ICR',
            subtitle: '${_config.icr.toStringAsFixed(1)} g/U · 每1U胰岛素覆盖的碳水',
            onTap: () => _editField('ICR', _config.icr, (v) => setState(() => _config.icr = v)),
          ),
          _buildConfigTile(
            icon: Icons.track_changes,
            title: '目标血糖范围',
            subtitle: '${_config.targetGlucoseMin.toStringAsFixed(1)} - ${_config.targetGlucoseMax.toStringAsFixed(1)} mmol/L',
            onTap: () {
              final minCtrl = TextEditingController(text: _config.targetGlucoseMin.toStringAsFixed(1));
              final maxCtrl = TextEditingController(text: _config.targetGlucoseMax.toStringAsFixed(1));
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('目标血糖范围'),
                  content: Row(
                    children: [
                      Expanded(child: TextField(controller: minCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '下限'))),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('—')),
                      Expanded(child: TextField(controller: maxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '上限'))),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                    FilledButton(
                      onPressed: () {
                        final min = double.tryParse(minCtrl.text);
                        final max = double.tryParse(maxCtrl.text);
                        if (min != null && max != null && min < max) {
                          setState(() {
                            _config.targetGlucoseMin = min;
                            _config.targetGlucoseMax = max;
                          });
                          _saveConfig();
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text('保存'),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildConfigTile(
            icon: Icons.biotech,
            title: '胰岛素类型',
            subtitle: _config.insulinType.displayName,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('选择胰岛素类型'),
                  children: InsulinType.values.map((type) {
                    return SimpleDialogOption(
                      onPressed: () {
                        setState(() => _config.insulinType = type);
                        _config.iobDurationHours = type.activeDurationHours;
                        _saveConfig();
                        Navigator.pop(ctx);
                      },
                      child: Text(type.displayName),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          _buildConfigTile(
            icon: Icons.timer,
            title: '胰岛素活性时长',
            subtitle: '${_config.iobDurationHours} 小时',
            onTap: () => _editField('活性时长', _config.iobDurationHours.toDouble(), (v) => setState(() => _config.iobDurationHours = v.round())),
          ),
          _buildConfigTile(
            icon: Icons.warning,
            title: '单次最大剂量',
            subtitle: '${_config.maxDosePerInjection.toStringAsFixed(1)} U',
            onTap: () => _editField('最大剂量', _config.maxDosePerInjection, (v) => setState(() => _config.maxDosePerInjection = v)),
          ),

          const Divider(height: 32),

          // ===== 血糖测量提醒设置 =====
          _sectionHeader('血糖测量提醒'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('早餐前 (7:00)', style: TextStyle(fontSize: 14)),
                  value: _config.reminderBreakfast,
                  onChanged: (v) {
                    setState(() => _config.reminderBreakfast = v);
                    _saveConfig();
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('午餐前 (11:30)', style: TextStyle(fontSize: 14)),
                  value: _config.reminderLunch,
                  onChanged: (v) {
                    setState(() => _config.reminderLunch = v);
                    _saveConfig();
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('晚餐前 (17:30)', style: TextStyle(fontSize: 14)),
                  value: _config.reminderDinner,
                  onChanged: (v) {
                    setState(() => _config.reminderDinner = v);
                    _saveConfig();
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('睡前 (21:00)', style: TextStyle(fontSize: 14)),
                  value: _config.reminderBedtime,
                  onChanged: (v) {
                    setState(() => _config.reminderBedtime = v);
                    _saveConfig();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '开启后将在指定时间推送本地通知提醒测量血糖',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),

          const Divider(height: 32),

          // ===== 首页快捷提醒 =====
          _sectionHeader('首页提醒'),
          const SizedBox(height: 4),
          Card(
            child: SwitchListTile(
              title: const Text('距离上次测量提醒', style: TextStyle(fontSize: 14)),
              subtitle: const Text('超过30分钟无记录时在首页显示提醒', style: TextStyle(fontSize: 12)),
              value: true,
              onChanged: (_) {},
            ),
          ),

          const Divider(height: 32),

          // 危险区域
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmReset,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('清除所有数据', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text('版本 1.0.0 · 数据仅存储本地',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          )),
    );
  }

  Widget _buildConfigTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
