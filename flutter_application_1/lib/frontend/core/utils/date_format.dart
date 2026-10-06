/// แสดงวันที่แบบไทย (พ.ศ.) ถ้าอยากใช้ ค.ศ. แก้ที่ formatDate ที่เดียว

String _two(int value) => value.toString().padLeft(2, '0');

String formatDate(DateTime date) {
  return '${_two(date.day)}/${_two(date.month)}/${date.year + 543}';
}

String formatDateTime(DateTime date) {
  return '${formatDate(date)} ${_two(date.hour)}:${_two(date.minute)}';
}

/// รูปแบบที่ Backend รับ (yyyy-MM-dd)
String toApiDate(DateTime date) {
  return '${date.year}-${_two(date.month)}-${_two(date.day)}';
}
