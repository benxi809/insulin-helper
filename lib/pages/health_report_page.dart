import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glucare_app/utils/report_generator.dart';

/// 病情总结页面 — 病情报告 + 调整建议 + 发送医生
class HealthReportPage extends StatefulWidget {
  const HealthReportPage({super.key});

  @override
  State<HealthReportPage> createState() => _HealthReportPageState();
}

class _HealthReportPageState extends State<HealthReportPage> {
  final ReportGenerator _generator = ReportGenerator();
  int _selectedDays = 7;
  String? _summary;
  String? _suggestions;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() => _loading = true);
    try {
      final summary = await _generator.generateSummary(_selectedDays);
      final suggestions = await _generator.generateAdjustmentSuggestions(_selectedDays);
      setState(() {
        _summary = summary;
        _suggestions = suggestions;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _summary = '生成报告失败: $e';
        _loading = false;
      });
    }
  }

  /// 复制报告到剪贴板，用户可自行粘贴到微信发给医生
  void _copyToClipboard() {
    final fullReport = '${_summary ?? ""}\n${_suggestions ?? ""}';
    Clipboard.setData(ClipboardData(text: fullReport));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('报告已复制到剪贴板，请粘贴到微信发送给医生'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// 通过分享功能发送
  Future<void> _shareReport() async {
    // 使用 share_plus 分享文本
    try {
      // Dynamic import in case share_plus is available
      final fullReport = '${_summary ?? ""}\n\n${_suggestions ?? ""}';
      await Clipboard.setData(ClipboardData(text: fullReport));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('报告已复制，请粘贴到微信/短信发送给医生'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('病情总结'),
        actions: [
          // 发送给医生
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '发送给医生',
            onPressed: _copyToClipboard,
          ),
        ],
      ),
      body: Column(
        children: [
          // 时段选择器
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('统计周期: ', style: TextStyle(fontSize: 14)),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 7, label: Text('7天')),
                    ButtonSegment(value: 14, label: Text('14天')),
                    ButtonSegment(value: 30, label: Text('30天')),
                  ],
                  selected: {_selectedDays},
                  onSelectionChanged: (v) {
                    setState(() => _selectedDays = v.first);
                    _generateReport();
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _generateReport,
                  tooltip: '刷新报告',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 报告内容
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _generateReport,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 病情总结
                          if (_summary != null) ...[
                            _reportCard(
                              title: '📋 病情总结',
                              content: _summary!,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 调整建议
                          if (_suggestions != null) ...[
                            _reportCard(
                              title: '📝 用药方案调整建议',
                              content: _suggestions!,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 发送按钮
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Text(
                                    '发送给医生',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '点击下方按钮复制报告，然后粘贴到微信或短信发给医生',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _copyToClipboard,
                                        icon: const Icon(Icons.copy),
                                        label: const Text('复制报告'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      OutlinedButton.icon(
                                        onPressed: _shareReport,
                                        icon: const Icon(Icons.share),
                                        label: const Text('分享'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _reportCard({
    required String title,
    required String content,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
