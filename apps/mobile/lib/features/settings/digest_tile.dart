import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';

const _days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

/// Admin: the weekly family digest (on/off, day, hour) - saved on its own, like the web card.
class DigestTile extends StatelessWidget {
  const DigestTile({super.key, required this.orgId});

  final String orgId;

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    Map<String, dynamic> s;
    try {
      s = await AppSupabase.client.rpc('get_digest_settings', params: {'p_org': orgId}) as Map<String, dynamic>;
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('تعذّر تحميل الإعداد')));
      return;
    }
    if (!context.mounted) return;
    var enabled = s['enabled'] == true;
    var dow = (s['dow'] as num).toInt();
    var hour = (s['hour'] as num).toInt();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('ملخص الأسبوع للأسر', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('إشعار أسبوعي لكل أسرة: ما سمّع ابنها وحضوره ونقاطه، بتوقيت المركز.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('تفعيل الملخص الأسبوعي'), value: enabled, onChanged: (v) => setSheet(() => enabled = v)),
            DropdownButtonFormField<int>(
              initialValue: dow,
              decoration: const InputDecoration(labelText: 'اليوم'),
              items: [for (var i = 0; i < 7; i++) DropdownMenuItem(value: i, child: Text(_days[i]))],
              onChanged: (v) => setSheet(() => dow = v ?? dow),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: hour,
              decoration: const InputDecoration(labelText: 'الساعة'),
              items: [for (var h = 0; h < 24; h++) DropdownMenuItem(value: h, child: Text('${h.toString().padLeft(2, '0')}:00'))],
              onChanged: (v) => setSheet(() => hour = v ?? hour),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
          ]),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await AppSupabase.client.rpc('set_digest_settings', params: {'p_org': orgId, 'p_enabled': enabled, 'p_dow': dow, 'p_hour': hour});
      messenger.showSnackBar(const SnackBar(content: Text('حُفظ إعداد الملخص الأسبوعي')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e is PostgrestException ? e.message : 'تعذّر الحفظ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.mark_email_read_rounded),
      title: const Text('ملخص الأسبوع للأسر'),
      subtitle: const Text('اليوم والساعة وتفعيله'),
      trailing: const Icon(Icons.chevron_left_rounded),
      onTap: () => _open(context),
    );
  }
}
