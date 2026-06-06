import 'package:flutter/material.dart';
import 'package:insulin_app/database/local_db.dart';
import 'package:insulin_app/models/models.dart';
import 'package:insulin_app/utils/cgm_connector.dart';

/// CGM 设备设置页面
/// 选择品牌、输入账号密码、连接管理
class CGMSettingsPage extends StatefulWidget {
  const CGMSettingsPage({super.key});

  @override
  State<CGMSettingsPage> createState() => _CGMSettingsPageState();
}

class _CGMSettingsPageState extends State<CGMSettingsPage> {
  final AppDatabase _db = AppDatabase();
  late Future<CGMDeviceConfig> _configFuture;

  CGMDeviceConfig _config = CGMDeviceConfig();
  CGMDeviceBrand _selectedBrand = CGMDeviceBrand.mock;
  bool _loading = true;
  bool _saving = false;

  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _configFuture = _loadConfig();
  }

  Future<CGMDeviceConfig> _loadConfig() async {
    try {
      _config = await _db.getCGMConfig();
      _selectedBrand = CGMDeviceBrandExtension.fromShortName(_config.deviceType);
      _usernameCtrl.text = _config.username ?? '';
      _passwordCtrl.text = _config.password ?? '';
      _apiKeyCtrl.text = _config.apiKey ?? '';
    } catch (e) {
      // 加载失败时使用默认值
      debugPrint('CGM config load error: $e');
    }
    if (mounted) setState(() => _loading = false);
    return _config;
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    _config.deviceType = _selectedBrand.shortName;
    _config.displayName = _selectedBrand.displayName;
    _config.username = _usernameCtrl.text;
    _config.password = _passwordCtrl.text;
    _config.apiKey = _apiKeyCtrl.text;

    await _db.updateCGMConfig(_config);

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CGM 配置已保存'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _connect() async {
    setState(() => _saving = true);

    // 先保存配置
    _config.deviceType = _selectedBrand.shortName;
    _config.displayName = _selectedBrand.displayName;
    _config.username = _usernameCtrl.text;
    _config.password = _passwordCtrl.text;
    await _db.updateCGMConfig(_config);

    // 连接
    final connector = CGMConnectorFactory.create(_selectedBrand);
    final creds = <String, String>{
      if (_usernameCtrl.text.isNotEmpty) 'username': _usernameCtrl.text,
      if (_passwordCtrl.text.isNotEmpty) 'password': _passwordCtrl.text,
      if (_apiKeyCtrl.text.isNotEmpty) 'apiKey': _apiKeyCtrl.text,
    };

    final ok = await connector.connect(creds);
    if (ok) {
      _config.isConnected = true;
      await _db.updateCGMConfig(_config);

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ CGM 连接成功！'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ 连接失败，请检查账号密码'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    _config.isConnected = false;
    await _db.updateCGMConfig(_config);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已断开连接'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('CGM 设备设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== 品牌选择 =====
          const Text('选择 CGM 设备',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...CGMDeviceBrand.values.where((b) => b != CGMDeviceBrand.none).map((brand) {
            final selected = brand == _selectedBrand;
            final isMock = brand == CGMDeviceBrand.mock;
            return Card(
              color: selected ? Colors.blue.shade50 : null,
              child: RadioListTile<CGMDeviceBrand>(
                value: brand,
                groupValue: _selectedBrand,
                title: Row(
                  children: [
                    Text(brand.displayName, style: const TextStyle(fontSize: 14)),
                    if (isMock)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('演示', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ),
                  ],
                ),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedBrand = v);
                },
              ),
            );
          }),

          const SizedBox(height: 20),

          // ===== 配置表单（非Mock才需要） =====
          if (_selectedBrand.needsCredentials) ...[
            const Text('设备账号',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: '账号 / 邮箱',
                hintText: '输入 CGM 云平台账号',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 通用 API Key 字段
          TextField(
            controller: _apiKeyCtrl,
            decoration: const InputDecoration(
              labelText: 'API Key (可选)',
              hintText: '用于扩展功能',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),

          const SizedBox(height: 24),

          // ===== 连接状态 =====
          if (_config.isConnected)
            Card(
              color: Colors.green.shade50,
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text('已连接 (${_config.displayName})'),
                trailing: TextButton(
                  onPressed: _disconnect,
                  child: const Text('断开', style: TextStyle(color: Colors.red)),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ===== 操作按钮 =====
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _saving ? null : _connect,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_selectedBrand == CGMDeviceBrand.mock ? Icons.play_arrow : Icons.link),
              label: Text(_selectedBrand == CGMDeviceBrand.mock ? '启动模拟数据' : '连接设备'),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('保存配置'),
            ),
          ),

          const SizedBox(height: 24),

          // ===== 说明 =====
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 使用说明',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('• 选择"模拟数据"可以在没有真实CGM设备的情况下体验所有功能', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('• 德康(Dexcom)需Dexcom Share账号和密码', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('• 雅培(Libre)需LibreLinkUp账号和密码', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('• 国产CGM连接器将在后续更新中添加', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
