import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/i18n/i18n.dart';
import '../../core/offline/sync_service.dart';
import '../../core/widgets/ui.dart' show forwardChevron;

List<String> get _days => currentStrings.labels.weekdays;

/// Admin: the weekly family digest (on/off, day, hour) - saved on its own, like the web card.
class DigestTile extends StatelessWidget {
  const DigestTile({super.key, required this.orgId});

  final String orgId;

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    Map<String, dynamic> s;
    try {
      s = await SyncService.instance.raw('digest:$orgId', () => AppSupabase.client.rpc('get_digest_settings', params: {'p_org': orgId})) as Map<String, dynamic>;
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(currentStrings.set.loadOne)));
      return;
    }
    if (!context.mounted) return;
    var enabled = s['enabled'] == true;
    var dow = (s['dow'] as num).toInt();
    var hour = (s['hour'] as num).toInt();
    var smart = s['smart'] == true;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(tr(context).set.digestTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(tr(context).set.digestHint, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(tr(context).set.digestEnable), value: enabled, onChanged: (v) => setSheet(() => enabled = v)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr(context).weekly.smartToggle, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(tr(context).weekly.smartHint, style: const TextStyle(fontSize: 12)),
              value: smart,
              onChanged: (v) => setSheet(() => smart = v),
            ),
            DropdownButtonFormField<int>(
              initialValue: dow,
              decoration: InputDecoration(labelText: tr(context).set.day),
              items: [for (var i = 0; i < 7; i++) DropdownMenuItem(value: i, child: Text(_days[i]))],
              onChanged: (v) => setSheet(() => dow = v ?? dow),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: hour,
              decoration: InputDecoration(labelText: tr(context).set.hour),
              items: [for (var h = 0; h < 24; h++) DropdownMenuItem(value: h, child: Text('${h.toString().padLeft(2, '0')}:00'))],
              onChanged: (v) => setSheet(() => hour = v ?? hour),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr(context).common.save)),
          ]),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await AppSupabase.client.rpc('set_digest_settings', params: {'p_org': orgId, 'p_enabled': enabled, 'p_dow': dow, 'p_hour': hour, 'p_smart': smart});
      messenger.showSnackBar(SnackBar(content: Text(currentStrings.set.digestSaved)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e is PostgrestException ? e.message : currentStrings.set.saveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.mark_email_read_rounded),
      title: Text(tr(context).set.digestTitle),
      subtitle: Text(tr(context).set.digestSub),
      trailing: Icon(forwardChevron(context)),
      onTap: () => _open(context),
    );
  }
}

/// Admin: remind teachers to record attendance (on/off + hour), stored as center settings.
class AttendanceReminderTile extends StatelessWidget {
  const AttendanceReminderTile({super.key, required this.orgId});

  final String orgId;

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    var enabled = true;
    var hour = 11;
    try {
      final rows = await AppSupabase.client
          .from('organization_settings')
          .select('key, value')
          .eq('organization_id', orgId)
          .inFilter('key', ['attendance_reminder_enabled', 'attendance_reminder_hour']) as List;
      for (final r in rows) {
        if (r['key'] == 'attendance_reminder_enabled') enabled = r['value'] != 'false';
        if (r['key'] == 'attendance_reminder_hour') hour = int.tryParse('${r['value']}') ?? 11;
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(currentStrings.set.loadOne)));
      return;
    }
    if (!context.mounted) return;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(tr(context).set.attTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(tr(context).set.attHint, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(tr(context).set.attEnable), value: enabled, onChanged: (v) => setSheet(() => enabled = v)),
            DropdownButtonFormField<int>(
              initialValue: hour.clamp(0, 20),
              decoration: InputDecoration(labelText: tr(context).set.afterHour),
              items: [for (var h = 0; h <= 20; h++) DropdownMenuItem(value: h, child: Text('${h.toString().padLeft(2, '0')}:00'))],
              onChanged: (v) => setSheet(() => hour = v ?? hour),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr(context).common.save)),
          ]),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await AppSupabase.client.from('organization_settings').upsert([
        {'organization_id': orgId, 'key': 'attendance_reminder_enabled', 'value': enabled ? 'true' : 'false'},
        {'organization_id': orgId, 'key': 'attendance_reminder_hour', 'value': '$hour'},
      ], onConflict: 'organization_id,key');
      messenger.showSnackBar(SnackBar(content: Text(currentStrings.set.attSaved)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e is PostgrestException ? e.message : currentStrings.set.saveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.alarm_rounded),
      title: Text(tr(context).set.attTitle2),
      subtitle: Text(tr(context).set.attSub),
      trailing: Icon(forwardChevron(context)),
      onTap: () => _open(context),
    );
  }
}
