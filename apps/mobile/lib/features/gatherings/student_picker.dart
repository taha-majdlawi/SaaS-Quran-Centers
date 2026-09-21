import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/supabase/supabase_client.dart';
import '../insights/insights_repository.dart';

/// Search-as-you-type dialog that returns the chosen student's id (or null).
Future<String?> pickStudent(BuildContext context, String orgId, {String initialQuery = ''}) => showDialog<String>(
      context: context,
      builder: (context) => _StudentPicker(orgId: orgId, initialQuery: initialQuery),
    );

class _StudentPicker extends StatefulWidget {
  const _StudentPicker({required this.orgId, required this.initialQuery});
  final String orgId;
  final String initialQuery;

  @override
  State<_StudentPicker> createState() => _StudentPickerState();
}

class _StudentPickerState extends State<_StudentPicker> {
  final _repository = InsightsRepository(AppSupabase.client);
  late final _controller = TextEditingController(text: widget.initialQuery);
  Timer? _debounce;
  List<Map<String, dynamic>> _students = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.trim().length >= 2) _search(widget.initialQuery);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _students = const []);
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await _repository.search(widget.orgId, q.trim());
      if (mounted) setState(() => _students = r.students);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('اختر الطالب'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'اسم الطالب أو رقمه', prefixIcon: Icon(Icons.search_rounded)),
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () => _search(v));
            },
          ),
          if (_loading) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
          Flexible(
            child: ListView(shrinkWrap: true, children: [
              for (final s in _students)
                ListTile(
                  dense: true,
                  title: Text('${s['name']}'),
                  subtitle: Text('${s['code']} · ${s['circle'] ?? 'بدون حلقة'}'),
                  onTap: () => Navigator.pop(context, s['id'] as String),
                ),
            ]),
          ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء'))],
    );
  }
}
