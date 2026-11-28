import 'package:flutter/material.dart';

/// The bottom bar's tabs, all kept alive (each keeps its scroll and state) with only the open
/// one shown; a tab that is switched to fades in rather than appearing at once. Used as the
/// shell route's navigatorContainerBuilder.
class FadingBranches extends StatelessWidget {
  const FadingBranches({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      for (var i = 0; i < children.length; i++)
        _FadingBranch(active: i == currentIndex, child: children[i]),
    ],
  );
}

class _FadingBranch extends StatefulWidget {
  const _FadingBranch({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_FadingBranch> createState() => _FadingBranchState();
}

class _FadingBranchState extends State<_FadingBranch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1,
  );

  @override
  void didUpdateWidget(_FadingBranch old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Offstage(
    offstage: !widget.active,
    child: TickerMode(
      enabled: widget.active,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        child: widget.child,
      ),
    ),
  );
}
