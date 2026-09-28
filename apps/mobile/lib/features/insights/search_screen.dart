import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import 'insights_repository.dart';
import '../../core/i18n/i18n.dart';

/// One box that finds a student (name or number), a teacher or a circle.
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _repository = InsightsRepository(AppSupabase.client);
  final _controller = TextEditingController();
  Timer? _debounce;
  SearchResults? _results;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _results = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final orgId = context.read<TenantController>().active!.organization.id;
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        final r = await _repository.search(orgId, value.trim());
        if (mounted) setState(() => _results = r);
      } catch (_) {
        if (mounted) setState(() => _error = tr(context).ins.searchFailed);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  Widget _section(String title, List<Widget> tiles) {
    if (tiles.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 14, bottom: 6), child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
      Card(child: Column(children: tiles)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final r = _results;
    final empty = r != null && r.students.isEmpty && r.teachers.isEmpty && r.circles.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          decoration: InputDecoration(hintText: tr(context).ins.searchPh, border: InputBorder.none, filled: false),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) Text(_error!),
        if (empty) Padding(padding: EdgeInsets.only(top: 60), child: Center(child: Text(tr(context).ins.noResults))),
        if (r != null) ...[
          _section(tr(context).ins.students, [
            for (final s in r.students)
              ListTile(
                title: Text('${s['name']}'),
                subtitle: Text('${s['code']} · ${s['circle'] ?? tr(context).ins.noCircle}'),
                onTap: () => context.push('/students/${s['id']}/file'),
              ),
          ]),
          _section(tr(context).ins.staff, [
            for (final t in r.teachers)
              ListTile(title: Text('${t['name']}'), subtitle: Text(t['role'] == 'admin' ? tr(context).ins.admin : tr(context).ins.teacher), onTap: () => context.push('/members/${t['id']}')),
          ]),
          _section(tr(context).ins.circles, [
            for (final c in r.circles) ListTile(title: Text('${c['name']}'), onTap: () => context.push('/circle/${c['id']}')),
          ]),
        ],
      ]),
    );
  }
}
