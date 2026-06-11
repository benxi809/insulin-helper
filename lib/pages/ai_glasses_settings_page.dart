import 'package:flutter/material.dart';
import 'package:glucare_app/database/local_db.dart';
import 'package:glucare_app/utils/ai_glasses_connector.dart';

/// AI 眼镜设置页面
/// 选择品牌、输入IP和端口、连接管理、拍照测试
class AIGlassesSettingsPage extends StatefulWidget {
  const AIGlassesSettingsPage({super.key});

  @override
  State<AIGlassesSettingsPage> createState() => _AIGlassesSettingsPageState();
}

class _AIGlassesSettingsPageState extends State<AIGlassesSettingsPage> {
  final AppDatabase _db = AppDatabase();
  late Future<AIGlassesConfig> _configFuture;

  AIGlassesConfig _config = AIGlassesConfig();
  AIGlassesBrand _selectedBrand = AIGlassesBrand.mock;
  bool _loading = true;
  bool _saving = false;
  bool _testingPhoto = false;

  final _ipCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();

  AIGlassesConnector? _connector;

  @override
  void initState() {
    super.initState();
    _configFuture = _loadConfig();
  }

  Future<AIGlassesConfig> _loadConfig() async {
    try {
      _config = await _db.getAIGlassesConfig();
      _selectedBrand = AIGlassesBrandExtension.fromShortName(_config.deviceType);
      _ipCtrl.text = _config.ipAddress ?? '';
      _portCtrl.text = _config.port.toString();
      _apiKeyCtrl.text = _config.apiKey ?? '';
    } catch (e) {
      debugPrint('AI glasses config load error: $e');
    }
    if (mounted) setState(() => _loading = false);
    return _config;
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    _config.deviceType = _selectedBrand.shortName;
    _config.displayName = _selectedBrand.displayName;
    _config.ipAddress = _ipCtrl.text;
    _config.port = int.tryParse(_portCtrl.text) ?? 8080;
    _config.apiKey = _apiKeyCtrl.text;

    await _db.updateAIGlassesConfig(_config);

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI 眼镜配置已保存'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _connect() async {
    setState(() => _saving = true);

    // 先保存配置
    _config.deviceType = _selectedBrand.shortName;
    _config.displayName = _selectedBrand.displayName;
    _config.ipAddress = _ipCtrl.text;
    _config.port = int.tryParse(_portCtrl.text) ?? 8080;
    await _db.updateAIGlassesConfig(_config);

    // 创建连接器并连接
    _connector = AIGlassesConnectorFactory.create(_selectedBrand);
    final creds = <String, String>{
      if (_ipCtrl.text.isNotEmpty) 'ipAddress': _ipCtrl.text,
      'port': _portCtrl.text.isNotEmpty ? _portCtrl.text : '8080',
      if (_apiKeyCtrl.text.isNotEmpty) 'apiKey': _apiKeyCtrl.text,
    };

    final ok = await _connector!.connect(creds);
    if (ok) {
      _config.isConnected = true;
      await _db.updateAIGlassesConfig(_config);

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ AI 眼镜连接成功！'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      }
    } else {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ 连接失败，请检查IP地址和端口'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    await _connector?.disconnect();
    _config.isConnected = false;
    await _db.updateAIGlassesConfig(_config);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已断开连接'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _testTakePhoto() async {
    if (_connector == null || !_config.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先连接眼镜'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _testingPhoto = true);
    final result = await _connector!.takePhoto();
    setState(() => _testingPhoto = false);

    if (mounted) {
      if (result.success && result.imageBytes != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 拍照成功！'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 拍照失败: ${result.error ?? "未知错误"}'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    _portCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AI 眼镜设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== 品牌选择 =====
          const Text('选择 AI 眼镜',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...AIGlassesBrand.values.where((b) => b != AIGlassesBrand.none).map((brand) {
            final selected = brand == _selectedBrand;
            final isMock = brand == AIGlassesBrand.mock;
            return Card(
              color: selected ? Colors.blue.shade50 : null,
              child: RadioListTile<AIGlassesBrand>(
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

          // ===== 网络配置（非Mock才需要） =====
          if (_selectedBrand.needsConfig) ...[
            const Text('网络配置',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _ipCtrl,
              decoration: const InputDecoration(
                labelText: 'IP 地址',
                hintText: '192.168.x.x',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '端口',
                hintText: '8080',
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
              hintText: '用于认证',
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
                  : Icon(_selectedBrand == AIGlassesBrand.mock ? Icons.play_arrow : Icons.link),
              label: Text(_selectedBrand == AIGlassesBrand.mock ? '启动模拟连接' : '连接眼镜'),
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

          const SizedBox(height: 8),

          // ===== 拍照测试按钮（连接后可用） =====
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: (!_config.isConnected || _testingPhoto) ? null : _testTakePhoto,
              icon: _testingPhoto
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.camera_alt),
              label: const Text('拍照测试'),
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
                  const Text('• 选择"模拟数据"可以在没有真实AI眼镜的情况下体验功能', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('• 品牌眼镜需在眼镜端开启局域网HTTP API服务', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('• 拍照功能连接后可用，手动触发眼镜拍照', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('• 雷鸟X2/INMO Air/小米眼镜使用相同的Android HTTP协议', style: TextStyle(fontSize: 13)),
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
