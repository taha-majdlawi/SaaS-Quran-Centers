import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/i18n.dart';

import '../widgets/app_drawer.dart';
import '../widgets/ui.dart';
import 'outbox.dart';
import 'sync_service.dart';

String _time(DateTime t) {
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}  ${l.day}/${l.month}';
}

/// What is waiting on this phone: the queue, what failed and why, and a manual
/// "upload now".
class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    final items = sync.mine;

    return Scaffold(
      appBar: AppBar(
        leading: DrawerLeading(),title: Text(tr(context).sync.title)),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(sync.pendingCount + sync.failedCount == 0 ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sync.pendingCount + sync.failedCount == 0 ? tr(context).sync.allUp : fmt(tr(context).sync.counts, {'waiting': sync.pendingCount, 'failed': sync.failedCount}),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ]),
                  if (sync.lastSync != null) Padding(padding: EdgeInsets.only(top: 4), child: Text(fmt(tr(context).sync.lastSync, {'time': _time(sync.lastSync!)}), style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
                  if (sync.usingCache)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(tr(context).sync.cached, style: TextStyle(color: Colors.orange.shade800, fontSize: 12)),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: sync.flushing ? null : sync.flush,
                    icon: sync.flushing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync_rounded),
                    label: Text(tr(context).sync.uploadNow),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: EmptyState(icon: Icons.cloud_done_rounded, title: tr(context).sync.nothing, subtitle: tr(context).sync.nothingHint),
            ),
          for (final item in items) _ItemTile(item: item, sync: sync),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.sync});

  final OutboxItem item;
  final SyncService sync;

  @override
  Widget build(BuildContext context) {
    final failed = item.status == 'failed';
    return Card(
      color: failed ? Colors.red.shade50 : null,
      child: ListTile(
        leading: Icon(failed ? Icons.error_outline_rounded : Icons.schedule_rounded, color: failed ? Colors.red : Colors.orange.shade800),
        title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(failed ? fmt(tr(context).sync.rejected, {'error': item.error ?? ''}) : fmt(tr(context).sync.queued, {'time': _time(item.createdAt), 'n': item.attempts})),
        isThreeLine: failed,
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'retry') {
              await sync.retry(item);
              return;
            }
            if (v == 'discard') {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text(tr(context).sync.discardTitle),
                  content: Text(tr(context).sync.discardBody),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr(c).common.cancel)),
                    TextButton(onPressed: () => Navigator.pop(c, true), child: Text(tr(c).common.delete)),
                  ],
                ),
              );
              if (ok == true) await sync.discard(item);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'retry', child: Text(tr(context).sync.retry)),
            PopupMenuItem(value: 'discard', child: Text(tr(context).common.delete)),
          ],
        ),
      ),
    );
  }
}

/// One thin strip while something waits to upload (or old data is shown).
/// Tapping it opens the sync center. Placed by [StatusBanners], which owns the
/// status-bar inset and decides whether anything is shown.
class SyncStrip extends StatelessWidget {
  const SyncStrip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    final waiting = sync.pendingCount;
    final failed = sync.failedCount;

    final text = failed > 0
        ? fmt(tr(context).sync.stripFailed, {'n': failed})
        : waiting > 0
            ? fmt(tr(context).sync.stripWaiting, {'n': waiting})
            : tr(context).sync.stripOffline;
    final color = failed > 0 ? Colors.red.shade700 : Colors.orange.shade800;

    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(children: [
            Icon(sync.flushing ? Icons.sync_rounded : Icons.cloud_off_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
          ]),
        ),
      ),
    );
  }
}
