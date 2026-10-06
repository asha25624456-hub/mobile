import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/status_labels.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_chip.dart';
import '../models/requisition.dart';

class RequisitionTile extends StatelessWidget {
  final Requisition requisition;
  final VoidCallback onTap;

  const RequisitionTile({super.key, required this.requisition, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = requisitionStatusStyle(requisition.status);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  requisition.requestNo,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              StatusChip(style),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${requisition.totalItems} รายการ · ${requisition.totalQuantity} ชิ้น',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          if (requisition.createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'สร้างเมื่อ ${formatDateTime(requisition.createdAt!)}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
