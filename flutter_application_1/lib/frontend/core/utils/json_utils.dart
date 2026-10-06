/// แปลงค่าจาก JSON แบบปลอดภัย
/// (PHP/MySQL อาจส่งตัวเลขมาเป็นข้อความ เช่น "5" ขึ้นกับเวอร์ชัน)

int asInt(dynamic value, [int fallback = 0]) {
  return asIntOrNull(value) ?? fallback;
}

int? asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value.toString());
}

String asString(dynamic value, [String fallback = '']) {
  return value == null ? fallback : value.toString();
}

/// คืน null ถ้าไม่มีค่าหรือเป็นข้อความว่าง
String? asStringOrNull(dynamic value) {
  if (value == null) return null;

  final text = value.toString();

  return text.isEmpty ? null : text;
}

bool asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  final text = value?.toString().toLowerCase();

  return text == '1' || text == 'true';
}

DateTime? asDateTime(dynamic value) {
  if (value == null) return null;

  return DateTime.tryParse(value.toString());
}

List<Map<String, dynamic>> asMapList(dynamic value) {
  if (value is! List) return [];

  return value.map((item) => Map<String, dynamic>.from(item as Map)).toList();
}
