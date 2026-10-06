import 'package:flutter/material.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/message_banner.dart';
import '../api/auth_api.dart';

/// สมัครสมาชิกผู้เบิกวัสดุ สำเร็จแล้วคืนรหัสพนักงานกลับไปหน้าล็อกอิน
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ---- ค่าสีเฉพาะหน้านี้ (ชุดเดียวกับหน้าเข้าสู่ระบบ) ----
  static const _brand = Color(0xFF1E40AF);
  static const _pageBg = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE2E8F0);
  static const _danger = Color(0xFFDC2626);

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await AuthApi.registerUser(
        employeeCode: _codeController.text.trim(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pop(
        user['employee_code']?.toString() ?? _codeController.text.trim(),
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

  // ---- ส่วนประกอบ UI ----

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
    String? helper,
  }) {
    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
      helperText: helper,
      helperStyle: const TextStyle(color: AppColors.muted, fontSize: 12.5),
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
      errorBorder: outline(_danger),
      focusedErrorBorder: outline(_danger, 1.6),
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

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      );

  Widget _visibilityToggle() => IconButton(
        tooltip: _obscure ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
        icon: Icon(
          _obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          size: 20,
          color: AppColors.muted,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'สมัครสมาชิก',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ลงทะเบียนผู้เบิกวัสดุ โดยกรอกข้อมูลตามทะเบียนพนักงานของคุณ',
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
                          if (_error != null) ...[
                            MessageBanner(_error!),
                            const SizedBox(height: 20),
                          ],

                          // ---- ข้อมูลพนักงาน ----
                          _sectionTitle('ข้อมูลพนักงาน'),
                          const SizedBox(height: 16),
                          _fieldLabel('รหัสพนักงาน'),
                          TextFormField(
                            controller: _codeController,
                            enabled: !_loading,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: _fieldDecoration(
                              hint: 'กรอกรหัสพนักงาน',
                              icon: Icons.badge_outlined,
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return 'กรอกรหัสพนักงาน';
                              if (text.length > 50) {
                                return 'รหัสพนักงานต้องไม่เกิน 50 ตัวอักษร';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _fieldLabel('ชื่อ-นามสกุล'),
                          TextFormField(
                            controller: _nameController,
                            enabled: !_loading,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: _fieldDecoration(
                              hint: 'กรอกชื่อ-นามสกุล',
                              icon: Icons.person_outline,
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return 'กรอกชื่อ-นามสกุล';
                              if (text.length > 150) {
                                return 'ชื่อต้องไม่เกิน 150 ตัวอักษร';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _fieldLabel('อีเมล'),
                          TextFormField(
                            controller: _emailController,
                            enabled: !_loading,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: _fieldDecoration(
                              hint: 'name@example.com',
                              icon: Icons.mail_outline,
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return 'กรอกอีเมล';
                              if (!_emailPattern.hasMatch(text)) {
                                return 'รูปแบบอีเมลไม่ถูกต้อง';
                              }
                              if (text.length > 150) {
                                return 'อีเมลต้องไม่เกิน 150 ตัวอักษร';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),
                          const Divider(height: 1, color: _border),
                          const SizedBox(height: 24),

                          // ---- ตั้งรหัสผ่าน ----
                          _sectionTitle('ตั้งรหัสผ่าน'),
                          const SizedBox(height: 16),
                          _fieldLabel('รหัสผ่าน'),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_loading,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.next,
                            decoration: _fieldDecoration(
                              hint: 'กรอกรหัสผ่าน',
                              icon: Icons.lock_outline,
                              helper: 'อย่างน้อย 8 ตัวอักษร',
                              suffix: _visibilityToggle(),
                            ),
                            validator: (value) {
                              final text = value ?? '';
                              if (text.isEmpty) return 'กรอกรหัสผ่าน';
                              if (text.length < 8) {
                                return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                              }
                              if (text.length > 72) {
                                return 'รหัสผ่านต้องไม่เกิน 72 ตัวอักษร';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _fieldLabel('ยืนยันรหัสผ่าน'),
                          TextFormField(
                            controller: _confirmController,
                            enabled: !_loading,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: _fieldDecoration(
                              hint: 'กรอกรหัสผ่านอีกครั้ง',
                              icon: Icons.lock_outline,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรอกรหัสผ่านอีกครั้ง';
                              }
                              if (value != _passwordController.text) {
                                return 'รหัสผ่านไม่ตรงกัน';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          PrimaryButton(
                            label: 'สมัครสมาชิก',
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
                        'มีบัญชีอยู่แล้ว?',
                        style: TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                      TextButton(
                        onPressed:
                            _loading ? null : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: _brand,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('เข้าสู่ระบบ'),
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