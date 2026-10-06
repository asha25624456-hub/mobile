import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';

class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final double radius;
  final double iconSize;

  const ProductImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.radius,
    required this.iconSize,
  });

  String? _resolvedUrl() {
    final value = imageUrl?.trim();
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    if (uri.hasScheme) return uri.toString();

    final base = Uri.parse(AppConfig.baseUrl);
    // API image paths may already include the site prefix, e.g.
    // /6620310027/html/apinew/backend/uploads/products/item.jpg.
    // Keep that path and add only the site's origin.
    if (value.startsWith('/')) {
      return base.replace(path: value).toString();
    }

    // web2 resolves relative image names beneath the site's /uploads folder,
    // not beneath /backend. Match that behavior for values such as
    // "photo.jpg" or "uploads/photo.jpg" stored by older admin records.
    final relativePath = value.replaceFirst(RegExp(r'^\.?/?uploads/'), '');
    final uploadsBase = Uri.parse('${AppConfig.uploadsUrl}/');
    return uploadsBase.resolve(relativePath).toString();
  }

  Widget _placeholder() => Container(
        color: AppColors.paper,
        alignment: Alignment.center,
        child: Icon(
          Icons.inventory_2_outlined,
          size: iconSize,
          color: AppColors.muted,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: url == null
            ? _placeholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _placeholder(),
              ),
      ),
    );
  }
}
