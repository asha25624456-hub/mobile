import 'package:flutter/material.dart';

import 'frontend/auth/pages/login_page.dart';
import 'frontend/auth/pages/splash_page.dart';
import 'frontend/core/config/app_config.dart';
import 'frontend/core/session/session_manager.dart';
import 'frontend/core/theme/app_theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Token หมดอายุระหว่างใช้งานหน้าไหนก็ได้ ให้พากลับหน้าล็อกอินทันที
    SessionManager.expiredEvents.addListener(_onSessionExpired);
  }

  @override
  void dispose() {
    SessionManager.expiredEvents.removeListener(_onSessionExpired);
    super.dispose();
  }

  void _onSessionExpired() {
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPage(notice: 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const SplashPage(),
    );
  }
}
