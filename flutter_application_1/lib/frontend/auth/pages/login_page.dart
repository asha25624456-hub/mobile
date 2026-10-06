import 'package:flutter/material.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/message_banner.dart';
import '../api/auth_api.dart';
import '../auth_flow.dart';
import 'register_page.dart';

/// เข้าสู่ระบบสำหรับผู้เบิกวัสดุ
/// (ฝั่งผู้ดูแลระบบใช้งานผ่านหน้าเว็บ Admin แยกต่างหาก ไม่มีในแอปนี้)
class LoginPage extends StatefulWidget {
  /// ข้อความแจ้งด้านบนฟอร์ม เช่น "เซสชันหมดอายุ"
  final String? notice;

  const LoginPage({super.key, this.notice});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ---- ค่าสีเฉพาะหน้านี้ (ย้ายไป AppColors ได้ภายหลัง) ----
  static const _brand = Color(0xFF1E40AF);
  static const _pageBg = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE2E8F0);

  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;
  String? _notice;
  MessageTone _noticeTone = MessageTone.info;

  @override
  void initState() {
    super.initState();
    _notice = widget.notice;
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });

    try {
      final employeeCode = _idController.text.trim();
      final password = _passwordController.text;

      await AuthApi.loginUser(employeeCode: employeeCode, password: password);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => homeAfterLogin()),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = errorMessageOf(e);
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openRegister() async {
    final employeeCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );

    if (employeeCode == null || !mounted) return;

    setState(() {
      _error = null;
      _noticeTone = MessageTone.success;
      _notice = 'สมัครสมาชิกสำเร็จ เข้าสู่ระบบด้วยรหัสผ่านที่ตั้งไว้ได้เลย';
      _idController.text = employeeCode;
      _passwordController.clear();
    });
  }

  // ---- ส่วนประกอบ UI ----

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
      prefixIcon: Icon(icon, size: 20, color: AppColors.muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: _pageBg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: outline(_border),
      enabledBorder: outline(_border),
      disabledBorder: outline(_border),
      focusedBorder: outline(_brand, 1.6),
      errorBorder: outline(const Color(0xFFDC2626)),
      focusedErrorBorder: outline(const Color(0xFFDC2626), 1.6),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      );

  Widget _brandHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _brand,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            AppConfig.appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _brandHeader(),
                  const SizedBox(height: 40),
                  const Text(
                    'เข้าสู่ระบบ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ใช้รหัสพนักงานและรหัสผ่านที่ลงทะเบียนไว้',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_notice != null) ...[
                            MessageBanner(_notice!, tone: _noticeTone),
                            const SizedBox(height: 20),
                          ],
                          if (_error != null) ...[
                            MessageBanner(_error!),
                            const SizedBox(height: 20),
                          ],
                          _fieldLabel('รหัสพนักงาน'),
                          TextFormField(
                            controller: _idController,
                            enabled: !_loading,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: _fieldDecoration(
                              hint: 'กรอกรหัสพนักงาน',
                              icon: Icons.badge_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'กรอกรหัสพนักงาน';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _fieldLabel('รหัสผ่าน'),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_loading,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: _fieldDecoration(
                              hint: 'กรอกรหัสผ่าน',
                              icon: Icons.lock_outline,
                              suffix: IconButton(
                                tooltip:
                                    _obscure ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: AppColors.muted,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรอกรหัสผ่าน';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          PrimaryButton(
                            label: 'เข้าสู่ระบบ',
                            loading: _loading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'ยังไม่มีบัญชี?',
                        style: TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: _loading ? null : _openRegister,
                        style: TextButton.styleFrom(
                          foregroundColor: _brand,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('สมัครสมาชิก'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}