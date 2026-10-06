import 'package:flutter/material.dart';

import '../utils/status_labels.dart';

/// ป้ายสถานะสีต่าง ๆ (ใช้ร่วมกับ requisitionStatusStyle / itemStatusStyle ฯลฯ)
class StatusChip extends StatelessWidget {
  final StatusStyle style;
  final bool small;

  const StatusChip(this.style, {super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          color: style.foreground,
          fontSize: small ? 11 : 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
