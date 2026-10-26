import 'package:flutter/material.dart';

import 'net_image.dart';

/// The center's logo, or the platform's own mark when there is no logo (or it
/// fails to load). Used wherever the app says which center this is,
/// so a center's identity - name, logo, colours - shows up everywhere.
class OrgAvatar extends StatelessWidget {
  const OrgAvatar({super.key, required this.name, this.logoUrl, this.brandColor, this.size = 44, this.onDark = false});

  final String name;
  final String? logoUrl;

  /// Hex ("#rrggbb") of the center's colour (kept for callers; the platform mark has its own colours).
  final String? brandColor;
  final double size;

  /// On a coloured header (the mark has its own light background).
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size / 3.2);
    Widget fallback() => ClipRRect(
          borderRadius: radius,
          child: Image.asset('assets/brand/icon-source.png', width: size, height: size, fit: BoxFit.cover),
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
