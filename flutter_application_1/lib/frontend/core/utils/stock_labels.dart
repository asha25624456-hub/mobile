import '../../user/models/product.dart';
import '../theme/app_theme.dart';
import 'status_labels.dart';

/// ป้ายสถานะคงเหลือของวัสดุ ใช้กับ StatusChip
/// (แยกจาก requisitionStatusStyle / itemStatusStyle เพราะเป็นสถานะของ "จำนวนคงเหลือ" ไม่ใช่ของใบเบิก)
StatusStyle stockStatusStyle(Product product) {
  if (product.status != 'ACTIVE') {
    return const StatusStyle(
      'งดจำหน่าย',
      AppColors.line,
      AppColors.muted,
    );
  }

  if (product.isOutOfStock) {
    return const StatusStyle('หมดชั่วคราว', AppColors.errorBg, AppColors.errorText);
  }

  if (product.isLowStock) {
    return StatusStyle(
      'ใกล้หมด เหลือ ${product.stockQuantity} ${product.unit}',
      AppColors.warnBg,
      AppColors.warnText,
    );
  }

  return StatusStyle(
    'คงเหลือ ${product.stockQuantity} ${product.unit} (พร้อมเบิก)',
    AppColors.okBg,
    AppColors.okText,
  );
}
