import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';

const _signupUrl = 'https://bustan-alquran.com/signup';
const _seenPrefKey = 'onboarding_seen';

/// Whether the animated intro has already played on this device - checked once
/// at startup (see main.dart) and held here for the router's redirect to read
/// synchronously; the screen flips it the moment the person moves on.
class OnboardingGate {
  OnboardingGate(this.seen);

  static Future<OnboardingGate> load() async {
    final prefs = await SharedPreferences.getInstance();
    return OnboardingGate(prefs.getBool(_seenPrefKey) ?? false);
  }

  bool seen;

  Future<void> markSeen() async {
    seen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenPrefKey, true);
  }
}

class _Slide {
  const _Slide({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}

List<_Slide> get _slides => [
  _Slide(
    icon: Icons.menu_book_rounded,
    title: currentStrings.auth.ob1,
    body: currentStrings.auth.ob1Body,
  ),
  _Slide(
    icon: Icons.chat_bubble_rounded,
    title: currentStrings.auth.ob2,
    body: currentStrings.auth.ob2Body,
  ),
  _Slide(
    icon: Icons.emoji_events_rounded,
    title: currentStrings.auth.ob3,
    body: currentStrings.auth.ob3Body,
  ),
];

/// The very first thing a new install shows: three animated slides
/// explaining the app, then a choice between signing in (in the app) and
/// registering a new center (web only - a center is created from the
/// dashboard, not the phone).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.gate});

  final OnboardingGate gate;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish(String route) async {
    await widget.gate.markSeen();
    if (mounted) context.go(route);
  }

  Future<void> _openSignup() async {
    await widget.gate.markSeen();
    final ok = await launchUrl(Uri.parse(_signupUrl), mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(fmt(tr(context).auth.openSignup, {'_signupUrl': _signupUrl}))));
    }
    context.go('/login');
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    } else {
      _finish('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = kDefaultBrandColor;
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => _finish('/login'),
                child: Text(tr(context).auth.skip, style: TextStyle(color: Colors.grey.shade500)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i], brand: brand),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? brand : brand.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(backgroundColor: brand, minimumSize: const Size.fromHeight(52)),
                    child: Text(isLast ? tr(context).auth.signInBtn : tr(context).auth.next),
                  ),
                ),
                if (isLast) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _openSignup,
                    child: Text(tr(context).auth.registerCenter, style: TextStyle(color: Colors.grey.shade600)),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.brand});

  final _Slide slide;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(slide.title),
            tween: Tween(begin: 0.7, end: 1),
            duration: const Duration(milliseconds: 550),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(color: brand.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(slide.icon, size: 64, color: brand),
            ),
          ),
          const SizedBox(height: 36),
          TweenAnimationBuilder<double>(
            key: ValueKey('${slide.title}-text'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 450),
            builder: (context, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, (1 - t) * 14), child: child)),
            child: Column(children: [
              Text(slide.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text(slide.body, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.5, color: Colors.grey.shade600, height: 1.6)),
            ]),
          ),
        ],
      ),
    );
  }
}
