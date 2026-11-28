import 'package:flutter/material.dart';
import '../../core/i18n/i18n.dart';
import '../../core/widgets/motion.dart';

/// Shown while the signed-in user's centers are loading, so no screen is ever
/// built without an active center. The logo opens up, and a sprout grows below it.
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
            GrowIn(
              rise: 20,
              duration: const Duration(milliseconds: 620),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset('assets/brand/icon-source.png', width: 84, height: 84),
              ),
            ),
            const SizedBox(height: 18),
            GrowIn(
              delay: const Duration(milliseconds: 140),
              child: Text(tr(context).common.appName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 24),
            const SproutLoader(size: 40),
          ],
        ),
      ),
    );
  }
}
