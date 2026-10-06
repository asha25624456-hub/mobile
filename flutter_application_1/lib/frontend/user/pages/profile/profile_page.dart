import 'package:flutter/material.dart';

import '../../../auth/auth_flow.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/confirm_dialog.dart';

class ProfilePage extends StatelessWidget {
  // ---- ค่าสีเฉพาะหน้านี้ (ชุดเดียวกับหน้าอื่น) ----
  static const _brand = Color(0xFF1E40AF);
  static const _brandSoft = Color(0xFFEFF6FF);
  static const _pageBg = Color(0xFFF8FAFC);
  static const _divider = Color(0xFFF1F5F9);
  static const _dangerBorder = Color(0xFFFECACA);
  static const _shadow = BoxShadow(
    color: Color(0x0F0F172A),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'ออกจากระบบ',
      message: 'ต้องการออกจากระบบใช่หรือไม่',
      confirmLabel: 'ออกจากระบบ',
      destructive: true,
    );

    if (confirmed && context.mounted) {
      await signOut(context);
    }
  }

  // ---- ส่วนประกอบ UI ----

  /// การ์ดโปรไฟล์ด้านบน: อวาตาร์ + ชื่อ + ป้ายบทบาท
  Widget _header(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_shadow],
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: _brandSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person_rounded,
              size: 42,
              color: _brand,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _brandSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'ผู้เบิกวัสดุ',
              style: TextStyle(
                color: _brand,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _brandSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: _brand),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = SessionManager.profile;
    final name = profile['name']?.toString() ?? '-';
    final code = profile['employee_code']?.toString() ?? '-';
    final email = profile['email']?.toString() ?? '-';

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text(
          'บัญชีของฉัน',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        centerTitle: true,
        backgroundColor: _pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _header(name),
          const SizedBox(height: 28),
          _sectionTitle('ข้อมูลบัญชี'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [_shadow],
            ),
            child: Column(
              children: [
                _infoRow(
                  icon: Icons.badge_outlined,
                  label: 'รหัสพนักงาน',
                  value: code,
                ),
                const Divider(height: 1, thickness: 1, color: _divider),
                _infoRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'อีเมล',
                  value: email,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('ออกจากระบบ'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.errorText,
              backgroundColor: Colors.white,
              side: const BorderSide(color: _dangerBorder),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}