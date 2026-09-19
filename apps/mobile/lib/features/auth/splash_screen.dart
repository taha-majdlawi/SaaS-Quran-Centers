import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Shown while the signed-in user's centers are loading, so no screen is ever
/// built without an active center.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: kDefaultBrandColor,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: const Text('ب', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 18),
            const Text('بستان القرآن', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 28),
            const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3)),
          ],
        ),
      ),
    );
  }
}
