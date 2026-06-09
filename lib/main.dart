import 'package:flutter/material.dart';
import 'package:insulin_app/app_state.dart';
import 'package:insulin_app/pages/home_page.dart';
import 'package:insulin_app/pages/calculator_page.dart';
import 'package:insulin_app/pages/report_page.dart';
import 'package:insulin_app/pages/food_picker_page.dart';
import 'package:insulin_app/pages/settings_page.dart';
import 'package:insulin_app/pages/patient_profile_page.dart';
import 'package:insulin_app/pages/camera_food_page.dart';
import 'package:insulin_app/pages/cgm_dashboard_page.dart';
import 'package:insulin_app/pages/cgm_settings_page.dart';
import 'package:insulin_app/pages/ai_glasses_settings_page.dart';
import 'package:insulin_app/pages/insulin_advisor_page.dart';
import 'package:insulin_app/utils/notification_service.dart';
import 'package:insulin_app/services/pump_service.dart';

// 胰岛素泵控制页面
import 'package:insulin_app/pages/pump_running_page.dart';
import 'package:insulin_app/pages/pump_settings_page.dart';
import 'package:insulin_app/pages/pump_connect_page.dart';
import 'package:insulin_app/pages/pump_scan_page.dart';
import 'package:insulin_app/pages/pump_verify_page.dart';
import 'package:insulin_app/pages/pump_bolus_page.dart';
import 'package:insulin_app/pages/pump_temp_basal_page.dart';
import 'package:insulin_app/pages/basal_rate_page.dart';
import 'package:insulin_app/pages/therapy_params_page.dart';
import 'package:insulin_app/pages/pump_alerts_page.dart';
import 'package:insulin_app/pages/history_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  appState.init();

  // 初始化泵服务
  final pumpService = PumpService();
  pumpService.init();

  // 初始化通知服务
  final notifService = NotificationService();
  notifService.init();

  runApp(InsulinApp(
    appState: appState,
    notificationService: notifService,
    pumpService: pumpService,
  ));
}

class InsulinApp extends StatelessWidget {
  final AppState appState;
  final NotificationService notificationService;
  final PumpService pumpService;

  const InsulinApp({
    super.key,
    required this.appState,
    required this.notificationService,
    required this.pumpService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        if (!appState.initialized) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return MaterialApp(
          title: 'Insulin Helper',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.blue,
            useMaterial3: true,
            appBarTheme: const AppBarTheme(centerTitle: true),
          ),
          home: const MainShell(),
          routes: {
            // 原有路由
            '/foods': (context) => const FoodPickerPage(),
            '/settings': (context) => const SettingsPage(),
            '/profile': (context) => const PatientProfilePage(),
            '/camera_food': (context) => const CameraFoodPage(),
            '/cgm_settings': (context) => const CGMSettingsPage(),
            '/ai_glasses_settings': (context) => const AIGlassesSettingsPage(),

            // 胰岛素泵控制页面路由
            '/pump_running': (context) => const PumpRunningPage(),
            '/pump_settings': (context) => const PumpSettingsPage(),
            '/pump_connect': (context) => const PumpConnectPage(),
            '/pump_scan': (context) => const PumpScanPage(),
            '/pump_verify': (context) => const PumpVerifyPage(),
            '/pump_bolus': (context) => const BolusPage(),
            '/pump_temp_basal': (context) => const TempBasalPage(),
            '/pump_basal': (context) => const BasalRatePage(),
            '/pump_therapy_params': (context) => const TherapyParamsPage(),
            '/pump_alerts': (context) => const PumpAlertsPage(),
            '/pump_history': (context) => const HistoryPage(),
          },
        );
      },
    );
  }
}

/// 主外壳 — 底部导航栏 + 5个Tab页面
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 1; // 默认从计算器页开始

  final List<Widget> _pages = const [
    HomePage(),
    CalculatorPage(),
    CGMDashboardPage(),    // CGM 实时血糖
    InsulinAdvisorPage(),  // 智能推荐（基础率+饮食）
    ReportPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '记录',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: '计算器',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'CGM',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: '推荐',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '报告',
          ),
        ],
      ),
    );
  }
}
