import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A picture from the network, kept on the device after the first load, so
/// lists and screens opened again show it at once (and offline).
///
/// [cacheKey] names the picture when its link changes between loads (signed
/// links to private files): the same file is then not downloaded twice.
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.width, this.height, this.fit = BoxFit.cover, this.cacheKey, this.placeholder, this.error});

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? cacheKey;

  /// Shown while loading; defaults to a soft grey box.
  final Widget? placeholder;

  /// Shown when the picture can't be loaded; defaults to a broken-image icon.
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return CachedNetworkImage(
      imageUrl: url,
      cacheKey: cacheKey,
      width: width,
      height: height,
      fit: fit,
      // decode at the size it is shown, not the full photo - less memory, smoother lists
      memCacheWidth: width != null && width!.isFinite ? (width! * dpr).round() : null,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, _) => placeholder ?? Container(width: width, height: height, color: Colors.black.withValues(alpha: 0.05)),
      errorWidget: (context, _, _) => error ?? const Center(child: Icon(Icons.broken_image_rounded)),
    );
  }
}
