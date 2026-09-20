import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      appBar: AppBar(title: const Text('المزامنة')),
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
                        sync.pendingCount + sync.failedCount == 0 ? 'كل شيء مرفوع' : 'بانتظار الرفع: ${sync.pendingCount} · تحتاج مراجعة: ${sync.failedCount}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ]),
                  if (sync.lastSync != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('آخر رفع ناجح: ${_time(sync.lastSync!)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
                  if (sync.usingCache)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('تُعرض بيانات محفوظة سابقًا لأن الاتصال غير متاح', style: TextStyle(color: Colors.orange.shade800, fontSize: 12)),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: sync.flushing ? null : sync.flush,
                    icon: sync.flushing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync_rounded),
                    label: const Text('ارفع الآن'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: EmptyState(icon: Icons.cloud_done_rounded, title: 'لا يوجد شيء في الانتظار', subtitle: 'ما تسجّله دون اتصال يظهر هنا حتى يُرفع.'),
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
        subtitle: Text(failed ? 'رُفض من الخادم: ${item.error ?? ''}' : 'سُجّل ${_time(item.createdAt)} · محاولات: ${item.attempts}'),
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
                  title: const Text('حذف من الانتظار؟'),
                  content: const Text('لن يُرفع هذا السجل أبدًا.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                    TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
                  ],
                ),
              );
              if (ok == true) await sync.discard(item);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'retry', child: Text('أعد المحاولة')),
            const PopupMenuItem(value: 'discard', child: Text('حذف')),
          ],
        ),
      ),
    );
  }
}

/// A thin strip under the status bar while something waits to upload (or old
/// data is shown). Tapping it opens the sync center.
class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    final waiting = sync.pendingCount;
    final failed = sync.failedCount;
    if (waiting == 0 && failed == 0 && !sync.usingCache) return const SizedBox.shrink();

    final text = failed > 0
        ? 'بعض السجلات رُفضت ($failed) — اضغط للمراجعة'
        : waiting > 0
            ? 'بانتظار الرفع: $waiting — يُرفع تلقائيًا عند عودة الاتصال'
            : 'لا يوجد اتصال — تُعرض بيانات محفوظة';
    final color = failed > 0 ? Colors.red.shade700 : Colors.orange.shade800;

    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(children: [
              Icon(sync.flushing ? Icons.sync_rounded : Icons.cloud_off_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
            ]),
          ),
        ),
      ),
    );
  }
}
