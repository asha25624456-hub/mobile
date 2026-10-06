import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../models/status_log.dart';

class _Step {
  final String label;
  final Set<String> reachedAtStatuses;

  const _Step(this.label, this.reachedAtStatuses);
}

const _steps = [
  _Step('ส่งคำขอเบิกแล้ว', {'PENDING', 'APPROVED', 'ISSUED'}),
  _Step('อนุมัติแล้ว', {'APPROVED', 'ISSUED'}),
  _Step('เบิกวัสดุแล้ว', {'ISSUED'}),
];

/// เส้นเวลาสถานะใบเบิก อ่านจากสถานะปัจจุบัน + ใช้เวลาจากประวัติสถานะถ้ามี
/// ไม่แสดงเมื่อใบเบิกถูกปฏิเสธ/ยกเลิก (ใช้ RequisitionStatusBanner แทน)
class RequisitionTimeline extends StatelessWidget {
  final String currentStatus;
  final List<StatusLog> logs;

  const RequisitionTimeline({
    super.key,
    required this.currentStatus,
    this.logs = const [],
  });

  DateTime? _timeFor(Set<String> statuses) {
    for (final log in logs) {
      if (statuses.contains(log.toStatus)) {
        return log.createdAt;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // หาขั้นล่าสุดที่ไปถึงแล้ว เพื่อไฮไลต์เป็นขั้น "กำลังดำเนินการ"
    var currentIndex = -1;
    for (var i = 0; i < _steps.length; i++) {
      if (_steps[i].reachedAtStatuses.contains(currentStatus)) currentIndex = i;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _steps.length; i++)
          _TimelineRow(
            label: _steps[i].label,
            time: _timeFor(_steps[i].reachedAtStatuses),
            state: i < currentIndex
                ? _StepState.done
                : i == currentIndex
                    ? _StepState.current
                    : _StepState.pending,
            isLast: i == _steps.length - 1,
          ),
      ],
    );
  }
}

enum _StepState { done, current, pending }

class _TimelineRow extends StatelessWidget {
  final String label;
  final DateTime? time;
  final _StepState state;
  final bool isLast;

  const _TimelineRow({
    required this.label,
    required this.time,
    required this.state,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    final Widget icon;

    switch (state) {
      case _StepState.done:
        dotColor = AppColors.okText;
        icon = const Icon(Icons.check, size: 13, color: Colors.white);
        break;
      case _StepState.current:
        dotColor = AppColors.ink;
        icon = const SizedBox(
          width: 8,
          height: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        );
        break;
      case _StepState.pending:
        dotColor = AppColors.line;
        icon = const SizedBox.shrink();
    }

    final textColor = state == _StepState.pending ? AppColors.muted : AppColors.ink;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: icon,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: state == _StepState.done ? AppColors.okText : AppColors.line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: state == _StepState.pending
                          ? FontWeight.w600
                          : FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      formatDateTime(time!),
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// แถบแจ้งผลเมื่อใบเบิกถูกปฏิเสธหรือยกเลิก (แทนเส้นเวลา)
class RequisitionStatusBanner extends StatelessWidget {
  final String status;

  const RequisitionStatusBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isRejected = status == 'REJECTED';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isRejected
                  ? 'คำขอเบิกนี้ถูกปฏิเสธ ติดต่อผู้อนุมัติหากต้องการรายละเอียดเพิ่มเติม'
                  : 'คำขอเบิกนี้ถูกยกเลิกแล้ว',
              style: const TextStyle(color: AppColors.errorText, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
