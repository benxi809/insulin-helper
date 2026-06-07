import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:insulin_app/utils/food_recognizer.dart';
import 'package:insulin_app/utils/ai_glasses_connector.dart';
import 'package:insulin_app/database/local_db.dart';

/// 食物拍照识别页面
class CameraFoodPage extends StatefulWidget {
  const CameraFoodPage({super.key});

  @override
  State<CameraFoodPage> createState() => _CameraFoodPageState();
}

class _CameraFoodPageState extends State<CameraFoodPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _apiKeyCtrl = TextEditingController();

  XFile? _imageFile;
  bool _analyzing = false;
  FoodRecognitionResult? _result;
  String? _error;
  bool _glassesFromCamera = false; // 是否来自眼镜拍照

  // AI 眼镜状态
  AIGlassesConfig _glassesConfig = AIGlassesConfig();
  bool _loadingGlasses = false;

  // 用户可配置的API密钥（可以通过设置页传入，这里作为fallback）
  String? _apiKey;
  bool _useGemini = true; // 默认使用Google Gemini（免费额度）

  @override
  void initState() {
    super.initState();
    // 从环境变量或共享配置读取
    _apiKeyCtrl.text = '';
    _loadGlassesConfig();
  }

  Future<void> _loadGlassesConfig() async {
    try {
      _glassesConfig = await AppDatabase().getAIGlassesConfig();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  /// 从AI眼镜拍照
  Future<void> _captureFromGlasses() async {
    if (!_glassesConfig.isConnected) {
      setState(() => _error = 'AI眼镜未连接，请先在设置中连接');
      return;
    }

    setState(() {
      _loadingGlasses = true;
      _error = null;
    });

    final brand = AIGlassesBrandExtension.fromShortName(_glassesConfig.deviceType);
    final connector = AIGlassesConnectorFactory.create(brand);
    final result = await connector.takePhoto();

    if (result.success && result.imageBytes != null) {
      // 模拟模式下，直接触发识别（因为没有真实图片）
      if (brand == AIGlassesBrand.mock) {
        setState(() {
          _loadingGlasses = false;
          _glassesFromCamera = true;
          _result = FoodRecognitionResult(
            foodName: '模拟识别：炒青菜',
            estimatedCarbsGrams: 85.0,
            confidence: 0.95,
            description: '通过AI眼镜拍摄（模拟数据）',
          );
        });
      } else {
        // 真实眼镜：保存临时文件再进行识别
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/glasses_photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(result.imageBytes!);
        setState(() {
          _imageFile = XFile(tempFile.path);
          _loadingGlasses = false;
          _glassesFromCamera = true;
        });
      }
    } else {
      setState(() {
        _loadingGlasses = false;
        _error = result.error ?? '眼镜拍照失败';
      });
    }
  }

  /// AI 眼镜拍照按钮
  Widget _buildGlassesButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loadingGlasses ? null : _captureFromGlasses,
        icon: _loadingGlasses
            ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(
                Icons.smartphone_outlined,
                color: _glassesConfig.isConnected ? Colors.green : null,
              ),
        label: Text(
          _loadingGlasses
              ? '正在拍照...'
              : _glassesConfig.isConnected
                  ? '从AI眼镜拍照'
                  : 'AI眼镜（未连接）',
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: _glassesConfig.isConnected ? Colors.green : null,
          side: BorderSide(
            color: _glassesConfig.isConnected ? Colors.green : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() {
          _imageFile = file;
          _result = null;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = '选择图片失败: $e');
    }
  }

  Future<void> _analyze() async {
    if (_imageFile == null) return;

    final apiKey = _apiKeyCtrl.text.trim();
    if (apiKey.isEmpty) {
      setState(() => _error = '请先在右上角设置 API Key');
      return;
    }

    setState(() {
      _analyzing = true;
      _error = null;
      _result = null;
    });

    try {
      final bytes = await _imageFile!.readAsBytes();

      FoodRecognitionResult result;
      if (_useGemini) {
        result = await FoodRecognizer.recognizeWithGemini(
          imageBytes: bytes,
          apiKey: apiKey,
        );
      } else {
        result = await FoodRecognizer.recognizeWithOpenAI(
          imageBytes: bytes,
          apiKey: apiKey,
        );
      }

      if (mounted) {
        setState(() {
          _result = result;
          _analyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '识别失败: $e';
          _analyzing = false;
        });
      }
    }
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API 设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _apiKeyCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: '输入 OpenAI 或 Gemini API Key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('使用: '),
                const SizedBox(width: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Gemini (免费)'),
                      icon: Icon(Icons.auto_awesome, size: 16),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('OpenAI'),
                      icon: Icon(Icons.bolt, size: 16),
                    ),
                  ],
                  selected: {_useGemini},
                  onSelectionChanged: (v) =>
                      setState(() => _useGemini = v.first),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 返回结果给上一页
  void _returnResult(double? carbs) {
    Navigator.pop(context, carbs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拍照识食物'),
        actions: [
          IconButton(
            icon: const Icon(Icons.key),
            onPressed: _showApiKeyDialog,
            tooltip: 'API 设置',
          ),
        ],
      ),
      body: Column(
        children: [
          // 图片预览区域
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: Colors.grey.shade100,
              child: _imageFile == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant,
                              size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('拍照或选择照片识别食物',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(_imageFile!.path),
                          fit: BoxFit.contain,
                        ),
                        if (_analyzing)
                          Container(
                            color: Colors.black45,
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                      color: Colors.white),
                                  SizedBox(height: 12),
                                  Text('正在识别食物...',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),

          // 识别结果
          if (_result != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(_result!.foodName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      if (_result!.confidence != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${(_result!.confidence! * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                  if (_result!.description != null) ...[
                    const SizedBox(height: 4),
                    Text(_result!.description!,
                        style: TextStyle(color: Colors.grey.shade700)),
                  ],
                  if (_result!.estimatedCarbsGrams != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('估算碳水: ',
                            style: TextStyle(fontSize: 16)),
                        Text(
                          '${_result!.estimatedCarbsGrams!.toStringAsFixed(1)} g/份',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          _returnResult(_result!.estimatedCarbsGrams),
                      icon: const Icon(Icons.check),
                      label: const Text('使用此结果'),
                    ),
                  ),
                ],
              ),
            ),

          // 错误信息
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ],
              ),
            ),

          // 底部操作按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 从AI眼镜拍照
                  _buildGlassesButton(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _analyzing ? null : () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('相册'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _analyzing ? null : () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('拍照'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                      ),
                      if (_imageFile != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _analyzing ? null : _analyze,
                            icon: const Icon(Icons.search),
                            label: const Text('识别'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
