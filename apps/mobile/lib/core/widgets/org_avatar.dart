import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'net_image.dart';

/// The center's logo, or its first letter on the brand colour when there is no
/// logo (or it fails to load). Used wherever the app says which center this is,
/// so a center's identity - name, logo, colours - shows up everywhere.
class OrgAvatar extends StatelessWidget {
  const OrgAvatar({super.key, required this.name, this.logoUrl, this.brandColor, this.size = 44, this.onDark = false});

  final String name;
  final String? logoUrl;

  /// Hex ("#rrggbb") of the center's colour; falls back to the theme's primary.
  final String? brandColor;
  final double size;

  /// On a coloured header the fallback tile is white with a coloured letter.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size / 3.2);
    final brand = brandColor == null ? Theme.of(context).colorScheme.primary : parseBrandColor(brandColor);
    final letter = name.trim().isEmpty ? 'ب' : name.trim().characters.first;

    Widget fallback() => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: onDark ? Colors.white : brand, borderRadius: radius),
          alignment: Alignment.center,
          child: Text(letter, style: TextStyle(color: onDark ? brand : Colors.white, fontSize: size * 0.44, fontWeight: FontWeight.w800)),
        );

    final url = logoUrl;
    if (url == null || url.isEmpty) return fallback();
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
        child: NetImage(url, width: size, height: size, placeholder: fallback(), error: fallback()),
      ),
    );
  }
}
