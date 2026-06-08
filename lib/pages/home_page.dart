     1|import 'package:flutter/material.dart';
     2|import 'package:glucare_app/database/local_db.dart';
     3|import 'package:glucare_app/models/models.dart';
     4|
     5|/// 首页 — 血糖记录
     6|class HomePage extends StatefulWidget {
     7|  const HomePage({super.key});
     8|
     9|  @override
    10|  State<HomePage> createState() => _HomePageState();
    11|}
    12|
    13|class _HomePageState extends State<HomePage> {
    14|  final AppDatabase _db = AppDatabase();
    15|  List<GlucoseRecord> _records = [];
    16|  Map<String, dynamic>? _todaySummary;
    17|  UserConfig _config = UserConfig();
    18|  bool _loading = true;
    19|
    20|  @override
    21|  void initState() {
    22|    super.initState();
    23|    _loadData();
    24|  }
    25|
    26|  Future<void> _loadData() async {
    27|    setState(() => _loading = true);
    28|    final records = await _db.getGlucoseRecords(limit: 20);
    29|    final today = DateTime.now();
    30|    final summary = await _db.getDailySummary(today);
    31|    final config = await _db.getConfig();
    32|    if (mounted) {
    33|      setState(() {
    34|        _records = records;
    35|        _todaySummary = summary;
    36|        _config = config;
    37|        _loading = false;
    38|      });
    39|    }
    40|  }
    41|
    42|  Color _glucoseColor(double g) {
    43|    if (g < 3.9) return Colors.red;
    44|    if (g < 5.0) return Colors.orange;
    45|    if (g <= 7.2) return Colors.green;
    46|    if (g <= 10.0) return Colors.orange;
    47|    return Colors.red;
    48|  }
    49|
    50|  void _showAddDialog() {
    51|    final glucoseCtrl = TextEditingController();
    52|    final tagCtrl = ValueNotifier<GlucoseTag>(GlucoseTag.preMeal);
    53|
    54|    showModalBottomSheet(
    55|      context: context,
    56|      isScrollControlled: true,
    57|      shape: const RoundedRectangleBorder(
    58|        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    59|      ),
    60|      builder: (ctx) => Padding(
    61|        padding: EdgeInsets.only(
    62|          left: 24, right: 24, top: 20,
    63|          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
    64|        ),
    65|        child: Column(
    66|          mainAxisSize: MainAxisSize.min,
    67|          crossAxisAlignment: CrossAxisAlignment.start,
    68|          children: [
    69|            const Text('录入血糖', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    70|            const SizedBox(height: 16),
    71|            TextField(
    72|              controller: glucoseCtrl,
    73|              keyboardType: TextInputType.numberWithOptions(decimal: true),
    74|              decoration: const InputDecoration(
    75|                labelText: '血糖值 (mmol/L)',
    76|                border: OutlineInputBorder(),
    77|              ),
    78|              autofocus: true,
    79|            ),
    80|            const SizedBox(height: 12),
    81|            ValueListenableBuilder<GlucoseTag>(
    82|              valueListenable: tagCtrl,
    83|              builder: (_, tag, __) => Row(
    84|                children: GlucoseTag.values.map((t) {
    85|                  final selected = t == tag;
    86|                  return Padding(
    87|                    padding: const EdgeInsets.only(right: 8),
    88|                    child: ChoiceChip(
    89|                      label: Text(t.displayName, style: const TextStyle(fontSize: 13)),
    90|                      selected: selected,
    91|                      onSelected: (_) => tagCtrl.value = t,
    92|                    ),
    93|                  );
    94|                }).toList(),
    95|              ),
    96|            ),
    97|            const SizedBox(height: 20),
    98|            SizedBox(
    99|              width: double.infinity,
   100|              height: 48,
   101|              child: FilledButton(
   102|                onPressed: () async {
   103|                  final val = double.tryParse(glucoseCtrl.text);
   104|                  if (val == null) return;
   105|                  await _db.insertGlucose(GlucoseRecord(
   106|                    glucose: val,
   107|                    timestamp: DateTime.now(),
   108|                    tag: tagCtrl.value,
   109|                  ));
   110|                  Navigator.pop(ctx);
   111|                  _loadData();
   112|                },
   113|                child: const Text('保存', style: TextStyle(fontSize: 16)),
   114|              ),
   115|            ),
   116|          ],
   117|        ),
   118|      ),
   119|    );
   120|  }
   121|
   122|  @override
   123|  Widget build(BuildContext context) {
   124|    return Scaffold(
   125|      appBar: AppBar(
   126|        title: const Text('GluCare'),
   127|        actions: [
   128|          // 患者信息快速入口
   129|          IconButton(
   130|            icon: const Icon(Icons.person),
   131|            onPressed: () => Navigator.pushNamed(context, '/profile'),
   132|            tooltip: '患者信息',
   133|          ),
   134|          IconButton(
   135|            icon: const Icon(Icons.settings),
   136|            onPressed: () => Navigator.pushNamed(context, '/settings'),
   137|          ),
   138|        ],
   139|      ),
   140|      body: _loading
   141|          ? const Center(child: CircularProgressIndicator())
   142|          : RefreshIndicator(
   143|              onRefresh: _loadData,
   144|              child: ListView(
   145|                padding: const EdgeInsets.all(16),
   146|                children: [
   147|                  // 患者信息快捷卡片
   148|                  if (_config.patientName.isNotEmpty) _buildPatientCard(),
   149|                  // 今日摘要卡片
   150|                  _buildTodayCard(),
   151|                  const SizedBox(height: 16),
   152|                  // 下次测量提醒（如果最近30分钟内无记录）
   153|                  if (_records.isNotEmpty) _buildReminder(),
   154|                  const SizedBox(height: 16),
   155|                  // 快捷功能
   156|                  _buildQuickActions(),
   157|                  // 最近记录标题
   158|                  const Text('最近记录',
   159|                      style: TextStyle(fontSize: 14, color: Colors.grey)),
   160|                  const SizedBox(height: 8),
   161|                  // 记录列表
   162|                  ..._records.map((r) => _buildRecordItem(r)),
   163|                  const SizedBox(height: 80),
   164|                ],
   165|              ),
   166|            ),
   167|      floatingActionButton: FloatingActionButton(
   168|        onPressed: _showAddDialog,
   169|        child: const Icon(Icons.add),
   170|      ),
   171|    );
   172|  }
   173|
   174|  Widget _buildPatientCard() {
   175|    final name = _config.patientName;
   176|    final typeStr = _config.diabetesType == 1 ? '1型' : '2型';
   177|    return Card(
   178|      color: Colors.blue.shade50,
   179|      child: ListTile(
   180|        leading: CircleAvatar(
   181|          backgroundColor: Colors.blue.shade200,
   182|          child: Text(
   183|            name.isNotEmpty ? name[0] : '?',
   184|            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
   185|          ),
   186|        ),
   187|        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
   188|        subtitle: Text('$typeStr 糖尿病 · ${_config.age}岁 · HbA1c ${_config.hba1c?.toStringAsFixed(1) ?? '--'}%'),
   189|        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
   190|        onTap: () => Navigator.pushNamed(context, '/profile'),
   191|      ),
   192|    );
   193|  }
   194|
   195|  Widget _buildTodayCard() {
   196|    final s = _todaySummary;
   197|    if (s == null) return const SizedBox.shrink();
   198|
   199|    return Card(
   200|      color: Colors.blue.shade50,
   201|      child: Padding(
   202|        padding: const EdgeInsets.all(16),
   203|        child: Column(
   204|          crossAxisAlignment: CrossAxisAlignment.start,
   205|          children: [
   206|            Row(
   207|              children: [
   208|                const Text('今日概览', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
   209|                const Spacer(),
   210|                Text(
   211|                  '${s['recordCount']}次测量',
   212|                  style: const TextStyle(color: Colors.grey, fontSize: 13),
   213|                ),
   214|              ],
   215|            ),
   216|            const SizedBox(height: 12),
   217|            Row(
   218|              mainAxisAlignment: MainAxisAlignment.spaceAround,
   219|              children: [
   220|                _statItem('最高', s['maxGlucose']?.toStringAsFixed(1) ?? '--', Colors.red),
   221|                _statItem('最低', s['minGlucose']?.toStringAsFixed(1) ?? '--', Colors.green),
   222|                _statItem('平均', s['avgGlucose']?.toStringAsFixed(1) ?? '--', Colors.blue),
   223|                _statItem('胰岛素', '${(s['totalDose'] as double?)?.toStringAsFixed(0) ?? '0'}U', Colors.purple),
   224|              ],
   225|            ),
   226|              if ((s['lowCount'] as int? ?? 0 ) > 0)
   227|              Padding(
   228|                padding: const EdgeInsets.only(top: 8),
   229|                child: Text(
   230|                  '⚠️ 低血糖 ${s['lowCount']} 次',
   231|                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
   232|                ),
   233|              ),
   234|          ],
   235|        ),
   236|      ),
   237|    );
   238|  }
   239|
   240|  Widget _statItem(String label, String value, Color color) {
   241|    return Column(
   242|      children: [
   243|        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
   244|        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
   245|      ],
   246|    );
   247|  }
   248|
   249|  Widget _buildReminder() {
   250|    final last = _records.first;
   251|    final minutesSince = DateTime.now().difference(last.timestamp).inMinutes;
   252|    if (minutesSince < 30) return const SizedBox.shrink();
   253|
   254|    return Card(
   255|      color: Colors.yellow.shade50,
   256|      child: ListTile(
   257|        leading: const Icon(Icons.access_time, color: Colors.orange),
   258|        title: Text('距上次测量已 $minutesSince 分钟'),
   259|        subtitle: const Text('建议按时测量'),
   260|        trailing: IconButton(
   261|          icon: const Icon(Icons.add),
   262|          onPressed: () {
   263|            // 触发新增血糖记录
   264|          },
   265|        ),
   266|      ),
   267|    );
   268|  }
   269|
   270|  Widget _buildQuickActions() {
   271|    return Padding(
   272|      padding: const EdgeInsets.only(bottom: 12),
   273|      child: Row(
   274|        children: [
   275|          Expanded(
   276|            child: ActionChip(
   277|              avatar: const Icon(Icons.camera_alt, size: 18, color: Colors.green),
   278|              label: const Text('拍照识食物', style: TextStyle(fontSize: 13)),
   279|              onPressed: () => Navigator.pushNamed(context, '/camera_food'),
   280|            ),
   281|          ),
   282|          const SizedBox(width: 8),
   283|          Expanded(
   284|            child: ActionChip(
   285|              avatar: const Icon(Icons.restaurant_menu, size: 18, color: Colors.orange),
   286|              label: const Text('碳水库', style: TextStyle(fontSize: 13)),
   287|              onPressed: () => Navigator.pushNamed(context, '/foods'),
   288|            ),
   289|          ),
   290|        ],
   291|      ),
   292|    );
   293|  }
   294|
   295|  Widget _buildRecordItem(GlucoseRecord r) {
   296|    return Card(
   297|      margin: const EdgeInsets.only(bottom: 6),
   298|      child: ListTile(
   299|        dense: true,
   300|        leading: CircleAvatar(
   301|          radius: 16,
   302|          backgroundColor: _glucoseColor(r.glucose).withOpacity(0.2),
   303|          child: Text(
   304|            r.glucose.toStringAsFixed(1),
   305|            style: TextStyle(
   306|              fontSize: 12,
   307|              fontWeight: FontWeight.bold,
   308|              color: _glucoseColor(r.glucose),
   309|            ),
   310|          ),
   311|        ),
   312|        title: Text(
   313|          '${_formatTime(r.timestamp)}  ${r.tag.displayName}',
   314|          style: const TextStyle(fontSize: 14),
   315|        ),
   316|        trailing: IconButton(
   317|          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
   318|          onPressed: () async {
   319|            if (r.id != null) {
   320|              await _db.deleteGlucose(r.id!);
   321|              _loadData();
   322|            }
   323|          },
   324|        ),
   325|      ),
   326|    );
   327|  }
   328|
   329|  String _formatTime(DateTime dt) {
   330|    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
   331|  }
   332|}
   333|