import 'package:flutter/material.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/config/app_config.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_tag.dart';
import '../api/auth_api.dart';
import '../auth_flow.dart';
import 'login_page.dart';

/// หน้าเปิดแอป: ตรวจว่ามี session เดิมที่ยังใช้ได้ไหม แล้วเลือกหน้าถัดไป
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await SessionManager.restore();

    Widget next = const LoginPage();

    if (SessionManager.isLoggedIn) {
      try {
        await AuthApi.fetchUser(handleExpiry: false);
        next = homeAfterLogin();
      } on SessionExpiredException {
        await SessionManager.clear();
      } catch (_) {
        // เชื่อมต่อ Server ไม่ได้ตอนเปิดแอป: เข้าแอปต่อ
        // หน้าต่าง ๆ จะแสดงปุ่มลองใหม่เอง (ถ้า Token หมดอายุจะถูกพากลับมาล็อกอิน)
        next = homeAfterLogin();
      }
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTag(AppConfig.appName),
            SizedBox(height: 24),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
