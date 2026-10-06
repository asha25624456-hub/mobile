import 'package:flutter/material.dart';

class StatusStyle {
  final String label;
  final Color background;
  final Color foreground;

  const StatusStyle(this.label, this.background, this.foreground);
}

const _grey = Color(0xFFE9ECF1);
const _greyText = Color(0xFF465063);

/// สถานะของใบเบิก (requisitions.status)
StatusStyle requisitionStatusStyle(String status) {
  switch (status) {
    case 'PENDING':
      return const StatusStyle('รอดำเนินการ', Color(0xFFFFF3CD), Color(0xFF7A5B00));
    case 'APPROVED':
      return const StatusStyle('อนุมัติแล้ว', Color(0xFFDCEBFF), Color(0xFF0B4A9E));
    case 'REJECTED':
      return const StatusStyle('ไม่อนุมัติ', Color(0xFFFDECEA), Color(0xFFB3261E));
    case 'ISSUED':
      return const StatusStyle('เบิกแล้ว', Color(0xFFD5EDE3), Color(0xFF14533B));
    case 'CANCELLED':
      return const StatusStyle('ยกเลิก', _grey, _greyText);
    default:
      return StatusStyle(status, _grey, _greyText);
  }
}

/// สถานะของรายการวัสดุในใบเบิก (requisition_items.status)
StatusStyle itemStatusStyle(String status) {
  switch (status) {
    case 'PENDING':
      return const StatusStyle('รออนุมัติ', Color(0xFFFFF3CD), Color(0xFF7A5B00));
    case 'APPROVED':
      return const StatusStyle('อนุมัติ', Color(0xFFDCEBFF), Color(0xFF0B4A9E));
    case 'REJECTED':
      return const StatusStyle('ไม่อนุมัติ', Color(0xFFFDECEA), Color(0xFFB3261E));
    case 'PICKING':
      return const StatusStyle('กำลังหยิบ', Color(0xFFE6E4FF), Color(0xFF3B33A8));
    case 'PICKED':
      return const StatusStyle('หยิบแล้ว', Color(0xFFDDF3E4), Color(0xFF1E6B3A));
    case 'ISSUED':
      return const StatusStyle('จ่ายแล้ว', Color(0xFFD5EDE3), Color(0xFF14533B));
    default:
      return StatusStyle(status, _grey, _greyText);
  }
}

/// สถานะการรับวัสดุ (pickups.status)
StatusStyle pickupStatusStyle(String status) {
  switch (status) {
    case 'WAITING':
      return const StatusStyle('รอจัดเตรียม', Color(0xFFFFF3CD), Color(0xFF7A5B00));
    case 'READY':
      return const StatusStyle('พร้อมรับวัสดุ', Color(0xFFDDF3E4), Color(0xFF1E6B3A));
    case 'PICKED_UP':
      return const StatusStyle('รับวัสดุแล้ว', Color(0xFFD5EDE3), Color(0xFF14533B));
    case 'CANCELLED':
      return const StatusStyle('ยกเลิก', _grey, _greyText);
    default:
      return StatusStyle(status, _grey, _greyText);
  }
}
