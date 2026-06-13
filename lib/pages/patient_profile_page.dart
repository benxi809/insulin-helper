import 'package:flutter/material.dart';
import 'package:glucare_app/database/local_db.dart';
import 'package:glucare_app/models/models.dart';

/// 患者信息页面 — 查看和编辑患者治疗相关信息
class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({super.key});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final AppDatabase _db = AppDatabase();
  UserConfig _config = UserConfig();
  bool _loading = true;
  bool _saving = false;

  // 控制器
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _hba1cCtrl;
  late TextEditingController _regimenCtrl;
  late TextEditingController _targetGlucoseMinCtrl;
  late TextEditingController _targetGlucoseMaxCtrl;
  late TextEditingController _isfCtrl;
  late TextEditingController _icrCtrl;
  late TextEditingController _maxDoseCtrl;
  late TextEditingController _targetHba1cCtrl;

  DateTime? _diagnosisDate;
  int _diabetesType = 1;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _ageCtrl = TextEditingController();
    _weightCtrl = TextEditingController();
    _hba1cCtrl = TextEditingController();
    _regimenCtrl = TextEditingController();
    _targetGlucoseMinCtrl = TextEditingController();
    _targetGlucoseMaxCtrl = TextEditingController();
    _isfCtrl = TextEditingController();
    _icrCtrl = TextEditingController();
    _maxDoseCtrl = TextEditingController();
    _targetHba1cCtrl = TextEditingController();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      _config = await _db.getConfig();
      if (mounted) {
        setState(() {
          _nameCtrl.text = _config.patientName;
          _ageCtrl.text = _config.age.toString();
          _weightCtrl.text = _config.weight.toStringAsFixed(1);
          _hba1cCtrl.text = _config.hba1c?.toStringAsFixed(1) ?? '';
          _regimenCtrl.text = _config.medicationRegimen;
          _targetGlucoseMinCtrl.text = _config.targetGlucoseMin.toStringAsFixed(1);
          _targetGlucoseMaxCtrl.text = _config.targetGlucoseMax.toStringAsFixed(1);
          _isfCtrl.text = _config.isf.toStringAsFixed(2);
          _icrCtrl.text = _config.icr.toStringAsFixed(1);
          _maxDoseCtrl.text = _config.maxDosePerInjection.toStringAsFixed(1);
          _targetHba1cCtrl.text = _config.targetHba1c?.toString() ?? '7';
          _diagnosisDate = _config.diagnosisDate;
          _diabetesType = _config.diabetesType;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('PatientProfilePage._loadConfig error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _saving = true);

    _config.patientName = _nameCtrl.text;
    _config.age = int.tryParse(_ageCtrl.text) ?? 30;
    _config.weight = double.tryParse(_weightCtrl.text) ?? 65.0;
    _config.hba1c = double.tryParse(_hba1cCtrl.text);
    _config.medicationRegimen = _regimenCtrl.text;
    _config.targetGlucoseMin = double.tryParse(_targetGlucoseMinCtrl.text) ?? 5.0;
    _config.targetGlucoseMax = double.tryParse(_targetGlucoseMaxCtrl.text) ?? 7.2;
    _config.isf = double.tryParse(_isfCtrl.text) ?? 2.5;
    _config.icr = double.tryParse(_icrCtrl.text) ?? 12.0;
    _config.maxDosePerInjection = double.tryParse(_maxDoseCtrl.text) ?? 20.0;
    _config.targetHba1c = int.tryParse(_targetHba1cCtrl.text);
    _config.diagnosisDate = _diagnosisDate;
    _config.diabetesType = _diabetesType;

    await _db.updateConfig(_config);

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('患者信息已保存'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _diagnosisDate ?? DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );
    if (date != null) setState(() => _diagnosisDate = date);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _hba1cCtrl.dispose();
    _regimenCtrl.dispose();
    _targetGlucoseMinCtrl.dispose();
    _targetGlucoseMaxCtrl.dispose();
    _isfCtrl.dispose();
    _icrCtrl.dispose();
    _maxDoseCtrl.dispose();
    _targetHba1cCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('患者信息'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveConfig,
                  tooltip: '保存',
                ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== 基本信息 =====
          _sectionHeader('基本信息'),
          const SizedBox(height: 8),
          _buildTextField('患者姓名', _nameCtrl, hint: '请输入姓名'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTextField('年龄', _ageCtrl,
                    keyboardType: TextInputType.number, hint: '岁'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField('体重 (kg)', _weightCtrl,
                    keyboardType: TextInputType.number, hint: '公斤'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildDiabetesTypeSelector(),
          const SizedBox(height: 10),
          _buildDatePicker(),
          const SizedBox(height: 10),
          _buildTextField('用药方案', _regimenCtrl, hint: '如：每日多次注射（MDI）'),
          const SizedBox(height: 20),

          // ===== 口服药物 =====
          _sectionHeader('口服药物'),
          const SizedBox(height: 8),
          ..._config.oralMedications.asMap().entries.map((entry) {
            final i = entry.key;
            final med = entry.value;
            return Card(
              key: ValueKey('oral_med_$i'),
              margin: const EdgeInsets.only(bottom: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.medication, size: 18, color: Colors.blue),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: med.name),
                            decoration: const InputDecoration(
                              labelText: '药物名称',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            style: const TextStyle(fontSize: 14),
                            onChanged: (v) => med.name = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() {
                              _config.oralMedications.removeAt(i);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: med.dosage),
                            decoration: const InputDecoration(
                              labelText: '剂量（如 500mg）',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            style: const TextStyle(fontSize: 14),
                            onChanged: (v) => med.dosage = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: med.frequency),
                            decoration: const InputDecoration(
                              labelText: '频次（如 每日两次）',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            style: const TextStyle(fontSize: 14),
                            onChanged: (v) => med.frequency = v,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _config.oralMedications.add(OralMedication());
              });
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('添加口服药'),
          ),
          const SizedBox(height: 20),

          // ===== 血糖控制目标 =====
          _sectionHeader('血糖控制目标'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField('目标血糖下限',
                    _targetGlucoseMinCtrl,
                    keyboardType: TextInputType.number, hint: 'mmol/L'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('—', style: TextStyle(fontSize: 18)),
              ),
              Expanded(
                child: _buildTextField('目标血糖上限',
                    _targetGlucoseMaxCtrl,
                    keyboardType: TextInputType.number, hint: 'mmol/L'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTextField('糖化血红蛋白 HbA1c', _hba1cCtrl,
                    keyboardType: TextInputType.number, hint: '%'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField('目标 HbA1c', _targetHba1cCtrl,
                    keyboardType: TextInputType.number, hint: '%'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ===== 胰岛素参数 =====
          _sectionHeader('胰岛素参数'),
          const SizedBox(height: 8),
          _buildTextField('胰岛素敏感系数 ISF', _isfCtrl,
              keyboardType: TextInputType.number,
              hint: 'mmol/L · 每1U降低血糖'),
          const SizedBox(height: 10),
          _buildTextField('碳水系数 ICR', _icrCtrl,
              keyboardType: TextInputType.number,
              hint: 'g/U · 每1U覆盖碳水'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTextField('单次最大剂量', _maxDoseCtrl,
                    keyboardType: TextInputType.number, hint: 'U'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: ListTile(
                    title: Text(
                      _config.insulinType.displayName,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text('胰岛素类型', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    dense: true,
                    onTap: () => _showInsulinTypePicker(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          // 保存按钮
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _saving ? null : _saveConfig,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? '保存中...' : '保存所有信息'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ));
  }

  Widget _buildTextField(String label, TextEditingController ctrl,
      {TextInputType? keyboardType, String? hint}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 15),
    );
  }

  Widget _buildDiabetesTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            const Text('糖尿病类型：', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1型')),
                ButtonSegment(value: 2, label: Text('2型')),
              ],
              selected: {_diabetesType},
              onSelectionChanged: (v) => setState(() => _diabetesType = v.first),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Card(
      child: ListTile(
        title: Text(
          _diagnosisDate != null
              ? '诊断日期：${_diagnosisDate!.year}-${_diagnosisDate!.month.toString().padLeft(2, '0')}-${_diagnosisDate!.day.toString().padLeft(2, '0')}'
              : '诊断日期：未设置',
          style: const TextStyle(fontSize: 15),
        ),
        trailing: const Icon(Icons.calendar_today, color: Colors.blue),
        onTap: _pickDate,
      ),
    );
  }

  void _showInsulinTypePicker() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择胰岛素类型'),
        children: InsulinType.values.map((type) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _config.insulinType = type);
              Navigator.pop(ctx);
            },
            child: Text(type.displayName),
          );
        }).toList(),
      ),
    );
  }
}
