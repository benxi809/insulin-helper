/// GluCare 入口
import 'package:flutter/material.dart';
import 'package:glucare_app/app_state.dart';
import 'package:glucare_app/theme/app_colors.dart';
import 'package:glucare_app/pages/home_page.dart';
import 'package:glucare_app/pages/calculator_page.dart';
import 'package:glucare_app/pages/cgm_dashboard_page.dart';
import 'package:glucare_app/pages/settings_page.dart';
import 'package:glucare_app/pages/report_page.dart';
import 'package:glucare_app/pages/insulin_advisor_page.dart';
import 'package:glucare_app/pages/patient_profile_page.dart';
import 'package:glucare_app/pages/camera_food_page.dart';
import 'package:glucare_app/pages/food_picker_page.dart';
import 'package:glucare_app/pages/history_page.dart';
import 'package:glucare_app/pages/cgm_settings_page.dart';
import 'package:glucare_app/pages/ai_glasses_settings_page.dart';
import 'package:glucare_app/utils/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  final notifService = NotificationService();

  // 启动初始化（不阻塞）
  appState.init();
  notifService.init();

  runApp(GluCareApp(appState: appState, notificationService: notifService));
}

class GluCareApp extends StatelessWidget {
  final AppState appState;
  final NotificationService notificationService;

  const GluCareApp({
    super.key,
    required this.appState,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        if (!appState.initialized) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: AppColors.primary,
              brightness: Brightness.light,
              scaffoldBackgroundColor: AppColors.background,
            ),
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo_splash.png',
                      width: 160,
                      height: 214,
                    ),
                    const SizedBox(height: 32),
                    const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          );
        }

        return MaterialApp(
          title: 'GluCare',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: AppColors.primary,
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.background,
            fontFamily: 'PingFang SC',
          ),
          home: const BottomNavShell(),
          routes: {
            '/settings': (_) => const SettingsPage(),
            '/report': (_) => const ReportPage(),
            '/cgm_dashboard': (_) => const CGMDashboardPage(),
            '/calculator': (_) => const CalculatorPage(),
            '/recommendation': (_) => const InsulinAdvisorPage(),
            '/patient_profile': (_) => const PatientProfilePage(),
            '/camera_food': (_) => const CameraFoodPage(),
            '/food_picker': (_) => const FoodPickerPage(),
            '/history': (_) => const HistoryPage(),
            '/cgm_settings': (_) => const CGMSettingsPage(),
            '/ai_glasses_settings': (_) => const AIGlassesSettingsPage(),
          },
        );
      },
    );
  }
}

/// 底部导航壳
class BottomNavShell extends StatefulWidget {
  const BottomNavShell({super.key});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    CalculatorPage(),
    CGMDashboardPage(),
    InsulinAdvisorPage(),
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
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '首页'),
          NavigationDestination(icon: Icon(Icons.calculate_outlined), label: '计算器'),
          NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), label: 'CGM'),
          NavigationDestination(icon: Icon(Icons.recommend_outlined), label: '推荐'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: '报告'),
        ],
      ),
    );
  }
}
