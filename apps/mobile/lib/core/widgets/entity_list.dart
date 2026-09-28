import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../tenant/tenant_controller.dart';
import 'app_drawer.dart';
import 'ui.dart';
import 'garden.dart';
import '../theme/app_theme.dart';
import '../../core/i18n/i18n.dart';

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
    this.addLabel,
    this.searchable = false,
  });

  final String title;
  final Future<List<T>> Function(String orgId) loader;
  final EntityTile Function(BuildContext context, T item) tileBuilder;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;
  final String? addPath;
  /// Defaults to the translated 'Add'.
  final String? addLabel;
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
      appBar: AppBar(
        leading: const DrawerLeading(),title: Text(widget.title)),
      drawer: const AppDrawer(),
      floatingActionButton: widget.addPath == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _open(widget.addPath!),
              icon: const Icon(Icons.add_rounded),
              label: Text(widget.addLabel ?? tr(context).ui.add),
            ),
      body: Column(
        children: [
          if (widget.searchable)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: tr(context).ui.search,
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: kHairline)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
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
                        return EmptyState(icon: Icons.search_off_rounded, title: tr(context).ui.noMatch);
                      }
                      final countLine = Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
                        child: Text(fmt(tr(context).garden.itemsN, {'n': tiles.length}), style: const TextStyle(color: kInkMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      );
                      return RefreshIndicator(
                        onRefresh: () async {
                          setState(() => _reload(orgId!));
                          await _future;
                        },
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, widget.addPath == null ? 24 : 96),
                          itemCount: tiles.length + 1,
                          separatorBuilder: (context, index) => SizedBox(height: index == 0 ? 6 : 10),
                          itemBuilder: (context, index) {
                            if (index == 0) return countLine;
                            final t = tiles[index - 1];
                            return GardenCard(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              onTap: t.path == null ? null : () => _open(t.path!),
                              child: Row(children: [
                                if (t.leading != null) ...[t.leading!, const SizedBox(width: 12)],
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kInk)),
                                    if (t.subtitle != null) ...[
                                      const SizedBox(height: 3),
                                      Text(t.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kInkMuted, fontSize: 12.5)),
                                    ],
                                  ]),
                                ),
                                if (t.trailing != null) t.trailing! else if (t.path != null) Icon(forwardChevron(context), color: Colors.grey.shade400),
                              ]),
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
    return IconBubble(icon, color: c, size: 44);
  }
}
