import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../tenant/organization.dart';

/// The org's logo if `logo_url` is set, otherwise a colored circle with the
/// name's first letter - same fallback shape the login screen used to hard-
/// code for the platform brand, now per-organization.
class OrgAvatar extends StatelessWidget {
  const OrgAvatar({super.key, required this.organization, this.size = 40});

  final Organization organization;
  final double size;

  @override
  Widget build(BuildContext context) {
    final logoUrl = organization.logoUrl;
    if (logoUrl == null || logoUrl.isEmpty) {
      return _InitialAvatar(organization: organization, size: size);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
      child: CachedNetworkImage(
        imageUrl: logoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => _InitialAvatar(organization: organization, size: size),
        errorWidget: (context, url, error) => _InitialAvatar(organization: organization, size: size),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.organization, required this.size});
  final Organization organization;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = organization.name.isNotEmpty ? organization.name.substring(0, 1) : 'ب';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: organization.primaryColorValue, borderRadius: BorderRadius.circular(size / 4)),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(color: Colors.white, fontSize: size * 0.42, fontWeight: FontWeight.bold),
      ),
    );
  }
}
