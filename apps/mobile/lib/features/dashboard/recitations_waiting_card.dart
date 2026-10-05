import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/i18n.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/widgets/garden.dart';

/// Recorded recitations waiting for this teacher (any, for an admin): a card that opens the inbox.
class RecitationsWaitingCard extends StatefulWidget {
  const RecitationsWaitingCard({super.key, required this.orgId});

  final String orgId;

  @override
  State<RecitationsWaitingCard> createState() => _RecitationsWaitingCardState();
}

class _RecitationsWaitingCardState extends State<RecitationsWaitingCard> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RecitationsWaitingCard old) {
    super.didUpdateWidget(old);
    if (old.orgId != widget.orgId) _load();
  }

  Future<void> _load() async {
    try {
      final n = await AppSupabase.client.rpc('recitation_inbox_count', params: {'p_org': widget.orgId});
      if (mounted) setState(() => _count = (n as num?)?.toInt() ?? 0);
    } catch (_) {
      // offline: the card simply stays hidden
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();
    return GardenCard(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () async {
        await context.push('/recitations');
        _load();
      },
      child: Row(children: [
        const IconBubble(Icons.graphic_eq_rounded, color: Color(0xFFB26A00), size: 36),
        const SizedBox(width: 10),
        Expanded(child: Text(fmt(tr(context).recite.waitingN, {'n': _count}), style: const TextStyle(fontWeight: FontWeight.w700))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xFFB26A00), borderRadius: BorderRadius.circular(20)),
          child: Text('$_count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}
