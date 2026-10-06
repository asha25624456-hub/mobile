import 'package:flutter/material.dart';

import '../user/pages/user_shell.dart';
import '../user/state/cart_controller.dart';
import 'api/auth_api.dart';
import 'pages/login_page.dart';

/// หน้าแรกหลังล็อกอินสำเร็จ (แอปนี้มีไว้สำหรับผู้เบิกวัสดุเท่านั้น)
Widget homeAfterLogin() => const UserShell();

/// ออกจากระบบ ล้างข้อมูลในเครื่อง แล้วกลับหน้าล็อกอิน
Future<void> signOut(BuildContext context) async {
  final navigator = Navigator.of(context);

  await AuthApi.logout();
  CartController.instance.clear();

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}
