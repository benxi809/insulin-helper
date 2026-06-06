import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// 食物识别结果
class FoodRecognitionResult {
  final String foodName;
  final double? estimatedCarbsGrams; // 估算每份碳水 (g)
  final double? confidence; // 置信度 0-1
  final String? description;

  FoodRecognitionResult({
    required this.foodName,
    this.estimatedCarbsGrams,
    this.confidence,
    this.description,
  });
}

/// 食物识别器
/// 使用免费 AI API 识别食物照片
class FoodRecognizer {
  /// 使用 OpenAI GPT-4o-mini 视觉能力识别食物
  /// [imageBytes] 图片字节数据
  /// [apiKey] OpenAI API Key
  static Future<FoodRecognitionResult> recognizeWithOpenAI({
    required Uint8List imageBytes,
    required String apiKey,
  }) async {
    final base64Image = base64Encode(imageBytes);

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: json.encode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                '你是一个食物识别与营养分析助手。请识别图片中的食物，返回JSON格式结果。'
                '只返回JSON，不要其他文字。\n'
                '格式：{"foodName":"食物名称","estimatedCarbsPerPortion":每份碳水克数(数字或null),"description":"简短描述","confidence":0-1置信度}\n'
                '如果无法识别，foodName返回"未知食物"，confidence为0。'
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
              }
            ]
          }
        ],
        'max_tokens': 300,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('API请求失败: ${response.statusCode} ${response.body}');
    }

    final data = json.decode(utf8.decode(response.bodyBytes));
    final content = data['choices']?[0]?['message']?['content'] as String?;
    if (content == null) throw Exception('API响应异常');

    return _parseResult(content);
  }

  /// 使用 Google Gemini Flash 免费API识别食物
  /// [imageBytes] 图片字节数据
  /// [apiKey] Gemini API Key
  static Future<FoodRecognitionResult> recognizeWithGemini({
    required Uint8List imageBytes,
    required String apiKey,
  }) async {
    final base64Image = base64Encode(imageBytes);

    final response = await http.post(
      Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': base64Image,
                }
              },
              {
                'text':
                    '识别这张图片中的食物。请只返回JSON格式：{"foodName":"食物名称","estimatedCarbsPerPortion":每份碳水克数(数字或null),"description":"简短描述","confidence":0-1}'
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API失败: ${response.statusCode} ${response.body}');
    }

    final data = json.decode(utf8.decode(response.bodyBytes));
    final content =
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (content == null) throw Exception('Gemini响应异常');

    return _parseResult(content);
  }

  /// 从文字中提取JSON结果
  static FoodRecognitionResult _parseResult(String content) {
    final jsonStart = content.indexOf('{');
    final jsonEnd = content.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1) {
      return FoodRecognitionResult(foodName: content.trim(), confidence: 0);
    }

    final jsonStr = content.substring(jsonStart, jsonEnd + 1);
    try {
      final result = json.decode(jsonStr) as Map<String, dynamic>;
      return FoodRecognitionResult(
        foodName: result['foodName'] as String? ?? '未知食物',
        estimatedCarbsGrams:
            (result['estimatedCarbsPerPortion'] as num?)?.toDouble(),
        confidence: (result['confidence'] as num?)?.toDouble(),
        description: result['description'] as String?,
      );
    } catch (_) {
      return FoodRecognitionResult(foodName: content.trim(), confidence: 0);
    }
  }
}
