import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../tenant/tenant_controller.dart';
import 'app_drawer.dart';
import 'ui.dart';

/// What one row of an [EntityListScreen] looks like.
class EntityTile {
  const EntityTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.path,
    this.searchText,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// Route opened on tap (the list reloads when it comes back).
  final String? path;

  /// Extra text matched by the search box (title is always matched).
  final String? searchText;
}

/// One list layout for every "table of records" screen: loading / error with
/// retry / empty state, pull-to-refresh, optional search, cards, and an add
/// button - so every module looks and behaves the same.
class EntityListScreen<T> extends StatefulWidget {
  const EntityListScreen({
    super.key,
    required this.title,
    required this.loader,
    required this.tileBuilder,
    required this.emptyIcon,
    required this.emptyTitle,
    this.emptySubtitle,
    this.addPath,
    this.addLabel = 'إضافة',
    this.searchable = false,
  });

  final String title;
  final Future<List<T>> Function(String orgId) loader;
  final EntityTile Function(BuildContext context, T item) tileBuilder;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;
  final String? addPath;
  final String addLabel;
  final bool searchable;

  @override
  State<EntityListScreen<T>> createState() => _EntityListScreenState<T>();
}

class _EntityListScreenState<T> extends State<EntityListScreen<T>> {
  Future<List<T>>? _future;
  String? _loadedForOrgId;
  String _query = '';

  void _reload(String orgId) {
    _loadedForOrgId = orgId;
    _future = widget.loader(orgId);
  }

  Future<void> _open(String path) async {
    await context.push(path);
    if (_loadedForOrgId != null && mounted) setState(() => _reload(_loadedForOrgId!));
  }

  @override
  Widget build(BuildContext context) {
    final orgId = context.watch<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _reload(orgId);
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      drawer: const AppDrawer(),
      floatingActionButton: widget.addPath == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _open(widget.addPath!),
              icon: const Icon(Icons.add_rounded),
              label: Text(widget.addLabel),
            ),
      body: Column(
        children: [
          if (widget.searchable)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: const InputDecoration(hintText: 'بحث', prefixIcon: Icon(Icons.search_rounded)),
              ),
            ),
          Expanded(
            child: _future == null
                ? const Center(child: CircularProgressIndicator())
                : AsyncBody<List<T>>(
                    future: _future!,
                    onRetry: () => setState(() => _reload(orgId!)),
                    builder: (context, all) {
                      if (all.isEmpty) {
                        return EmptyState(icon: widget.emptyIcon, title: widget.emptyTitle, subtitle: widget.emptySubtitle);
                      }
                      final tiles = all.map((item) => widget.tileBuilder(context, item)).where((t) {
                        if (_query.isEmpty) return true;
                        return t.title.contains(_query) || (t.searchText?.contains(_query) ?? false);
                      }).toList();
                      if (tiles.isEmpty) {
                        return const EmptyState(icon: Icons.search_off_rounded, title: 'لا نتائج مطابقة');
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          setState(() => _reload(orgId!));
                          await _future;
                        },
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, widget.addPath == null ? 24 : 96),
                          itemCount: tiles.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final t = tiles[index];
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: t.leading,
                                title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: t.subtitle == null
                                    ? null
                                    : Padding(padding: const EdgeInsets.only(top: 4), child: Text(t.subtitle!)),
                                trailing: t.trailing ?? (t.path != null ? const Icon(Icons.chevron_left_rounded) : null),
                                onTap: t.path == null ? null : () => _open(t.path!),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Round icon badge used as a tile's leading widget.
class TileIcon extends StatelessWidget {
  const TileIcon(this.icon, {super.key, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: c, size: 22),
    );
  }
}
