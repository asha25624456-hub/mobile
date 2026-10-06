import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ชิปเลือกหมวดหมู่ (ทั้งหมด / อุปกรณ์ไอที / เครื่องเขียน ฯลฯ)
class CategoryChip extends StatelessWidget {
  static const _brand = Color(0xFF1E40AF);
  static const _brandSoft = Color(0xFFEFF6FF);
  static const _textIdle = Color(0xFF475569);

  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? _brandSoft : Colors.white,
          borderRadius: radius,
          border: Border.all(
            color: selected ? _brand : AppColors.line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? _brand : _textIdle,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}