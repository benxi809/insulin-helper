import 'package:flutter/material.dart';
import 'package:insulin_app/models/models.dart';

/// 新增/编辑药品表单页面
class MedicationFormPage extends StatefulWidget {
  final Medication? medication; // null = 新增, non-null = 编辑

  const MedicationFormPage({super.key, this.medication});

  @override
  State<MedicationFormPage> createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends State<MedicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _doseController;
  late TextEditingController _unitController;
  late List<TimeOfDay> _doseTimes;
  late String _frequency;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final med = widget.medication;
    _nameController = TextEditingController(text: med?.name ?? '');
    _doseController = TextEditingController(
      text: med != null ? med.dose.toString() : '',
    );
    _unitController = TextEditingController(text: med?.unit ?? 'U');
    _frequency = med?.frequency ?? 'daily';
    _isActive = med?.isActive ?? true;

    // 解析已有时间点
    _doseTimes = [];
    if (med != null) {
      for (final t in med.doseTimes) {
        final parts = t.split(':');
        if (parts.length == 2) {
          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          _doseTimes.add(TimeOfDay(hour: h, minute: m));
        }
      }
    }
    if (_doseTimes.isEmpty) {
      _doseTimes.addAll([
        const TimeOfDay(hour: 7, minute: 0),
        const TimeOfDay(hour: 12, minute: 0),
        const TimeOfDay(hour: 18, minute: 0),
      ]);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _doseTimes[index],
    );
    if (picked != null) {
      setState(() => _doseTimes[index] = picked);
    }
  }

  void _addTimeSlot() {
    setState(() => _doseTimes.add(const TimeOfDay(hour: 8, minute: 0)));
  }

  void _removeTimeSlot(int index) {
    if (_doseTimes.length > 1) {
      setState(() => _doseTimes.removeAt(index));
    }
  }

  String _timeToJson() {
    final list = _doseTimes
        .map((t) =>
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
        .toList();
    return '[${list.map((s) => '"$s"').join(',')}]';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final dose = double.tryParse(_doseController.text.trim()) ?? 0;
    final unit = _unitController.text.trim();

    if (name.isEmpty || dose <= 0) return;

    final medication = Medication(
      id: widget.medication?.id,
      name: name,
      dose: dose,
      unit: unit,
      frequency: _frequency,
      doseTimesJson: _timeToJson(),
      isActive: _isActive,
    );

    Navigator.pop(context, medication);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.medication != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '编辑药品' : '添加药品'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 药品名称
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '药品名称',
                hintText: '如：门冬胰岛素、二甲双胍',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? '请输入药品名称' : null,
            ),
            const SizedBox(height: 16),

            // 剂量 + 单位 行
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _doseController,
                    decoration: const InputDecoration(
                      labelText: '单次剂量',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.speed),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val <= 0) return '请输入有效剂量';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: '单位',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 频率
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: const InputDecoration(
                labelText: '用药频率',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat),
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('每天')),
                DropdownMenuItem(value: 'every_other_day', child: Text('隔天')),
                DropdownMenuItem(value: 'weekly', child: Text('每周')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _frequency = v);
              },
            ),
            const SizedBox(height: 24),

            // 服用时间点
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '服用时间点',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: _addTimeSlot,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加时间'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_doseTimes.length, (index) {
              final time = _doseTimes[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeTimeSlot(index),
                  ),
                  onTap: () => _pickTime(index),
                ),
              );
            }),
            const SizedBox(height: 24),

            // 启用开关
            SwitchListTile(
              title: const Text('启用此药品提醒'),
              subtitle: Text(_isActive ? '提醒已开启' : '提醒已关闭'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              secondary: Icon(
                _isActive ? Icons.notifications_active : Icons.notifications_off,
                color: _isActive ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
