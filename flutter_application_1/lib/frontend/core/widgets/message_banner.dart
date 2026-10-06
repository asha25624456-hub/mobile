import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum MessageTone { error, success, info }

/// กล่องข้อความแจ้งผลลัพธ์ (ผิดพลาด / สำเร็จ / แจ้งให้ทราบ)
class MessageBanner extends StatelessWidget {
  final String message;
  final MessageTone tone;

  const MessageBanner(this.message, {super.key, this.tone = MessageTone.error});

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    final IconData icon;

    switch (tone) {
      case MessageTone.success:
        background = AppColors.okBg;
        foreground = AppColors.okText;
        icon = Icons.check_circle_outline;
        break;
      case MessageTone.info:
        background = AppColors.infoBg;
        foreground = AppColors.infoText;
        icon = Icons.info_outline;
        break;
      case MessageTone.error:
        background = AppColors.errorBg;
        foreground = AppColors.errorText;
        icon = Icons.error_outline;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: foreground, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
