import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// แถบหัวแอปสไตล์ "SmartRequisition": โลโก้เหลี่ยมมน + ชื่อแอป/ชื่อหน้าเล็ก ๆ
/// ใช้เป็น title ของ AppBar เพื่อให้ทุกหน้าในแอปดูเป็นชุดเดียวกัน
class BrandTitle extends StatelessWidget {
  final String subtitle;

  const BrandTitle({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SmartRequisition',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                height: 1.1,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11.5,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ปุ่มกระดิ่งแจ้งเตือน พร้อมจุดแดงบอกจำนวนที่ยังไม่อ่าน
class NotificationBellButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const NotificationBellButton({
    super.key,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          color: AppColors.ink,
          onPressed: onTap,
        ),
        if (unreadCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(
                color: AppColors.errorText,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// ไอคอนโปรไฟล์วงกลม แตะเพื่อเปิดหน้าบัญชี
class ProfileAvatarButton extends StatelessWidget {
  final VoidCallback onTap;

  const ProfileAvatarButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, left: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.paper,
          child: Icon(Icons.person, color: AppColors.ink, size: 18),
        ),
      ),
    );
  }
}
