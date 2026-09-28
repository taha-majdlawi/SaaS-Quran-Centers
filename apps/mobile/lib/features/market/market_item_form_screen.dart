import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import '../engagement/engagement_models.dart';
import '../engagement/engagement_repository.dart';
import '../../core/i18n/i18n.dart';

/// Admin: create / edit one market item (priced in the center's currency).
class MarketItemFormScreen extends StatefulWidget {
  const MarketItemFormScreen({super.key, this.itemId});

  final String? itemId;

  @override
  State<MarketItemFormScreen> createState() => _MarketItemFormScreenState();
}

class _MarketItemFormScreenState extends State<MarketItemFormScreen> {
  final _repository = EngagementRepository(AppSupabase.client);
  late final Future<MarketOverview> _future = _load();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _image = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  bool _active = true;
  bool _saving = false;
  Uint8List? _picked; // chosen from the device, uploaded on save
  String _pickedExt = 'jpg';
  String? _error;

  String get _orgId => context.read<TenantController>().active!.organization.id;

  Future<MarketOverview> _load() async {
    final o = await _repository.marketOverview(_orgId);
    final item = o.items.where((i) => i.id == widget.itemId).firstOrNull;
    if (item != null) {
      _name.text = item.name;
      _description.text = item.description ?? '';
      _image.text = item.imageUrl ?? '';
      _price.text = '${item.price}';
      _stock.text = item.stock?.toString() ?? '';
      _active = item.isActive;
    }
    return o;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _image.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = num.tryParse(_price.text.trim());
    if (_name.text.trim().isEmpty || price == null) {
      setState(() => _error = tr(context).mkt.nameRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // a picture chosen from the device wins over a pasted link
      final uploaded = _picked == null ? null : await _repository.uploadMarketImage(_orgId, _picked!, _pickedExt);
      await _repository.saveItem(
        _orgId,
        id: widget.itemId,
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        imageUrl: uploaded ?? (_image.text.trim().isEmpty ? null : _image.text.trim()),
        price: price,
        stock: int.tryParse(_stock.text.trim()),
        isActive: _active,
      );
      if (mounted) context.pop();
    } on PostgrestException catch (e) {
      setState(() => _error = e.message);
    } on StorageException catch (e) {
      setState(() => _error = e.message.contains('row-level security') ? tr(context).mkt.noUpload : tr(context).mkt.uploadFailed);
    } catch (e) {
      setState(() => _error = friendlyError(e, tr(context).set.saveFailed));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: Icon(Icons.photo_library_rounded), title: Text(tr(context).set.fromGallery), onTap: () => Navigator.pop(context, ImageSource.gallery)),
          ListTile(leading: Icon(Icons.photo_camera_rounded), title: Text(tr(context).set.takePhoto), onTap: () => Navigator.pop(context, ImageSource.camera)),
        ]),
      ),
    );
    if (source == null) return;
    final file = await ImagePicker().pickImage(source: source, maxWidth: 1200, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 3 * 1024 * 1024) {
      setState(() => _error = tr(context).mkt.tooBig3);
      return;
    }
    setState(() {
      _error = null;
      _picked = bytes;
      _pickedExt = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    });
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).mkt.deleteItem),
        content: Text(tr(context).mkt.deleteItemBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context).common.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(tr(context).common.delete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repository.deleteItem(_orgId, widget.itemId!);
      if (mounted) context.pop();
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemId == null ? tr(context).mkt.newItem : tr(context).mkt.editItem),
        actions: [if (widget.itemId != null) IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete)],
      ),
      body: AsyncBody<MarketOverview>(
        future: _future,
        builder: (context, o) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) MessageBanner(message: _error!),
            TextField(controller: _name, decoration: InputDecoration(labelText: tr(context).mkt.name)),
            const SizedBox(height: 12),
            TextField(controller: _description, maxLines: 2, decoration: InputDecoration(labelText: tr(context).mkt.description)),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: _picked != null
                      ? Image.memory(_picked!, fit: BoxFit.cover)
                      : (_image.text.trim().isNotEmpty
                          ? Image.network(_image.text.trim(), fit: BoxFit.cover, errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image_rounded)))
                          : Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image_outlined, size: 32, color: Colors.grey)))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(spacing: 8, runSpacing: 4, children: [
                  OutlinedButton.icon(onPressed: _saving ? null : _pickImage, icon: Icon(Icons.upload_rounded, size: 18), label: Text(tr(context).mkt.uploadDevice)),
                  if (_picked != null || _image.text.trim().isNotEmpty)
                    TextButton(
                      onPressed: _saving ? null : () => setState(() {
                        _picked = null;
                        _image.clear();
                      }),
                      child: Text(tr(context).mkt.removeImage, style: TextStyle(color: Colors.red)),
                    ),
                ]),
              ),
            ]),
            const SizedBox(height: 8),
            TextField(controller: _image, textDirection: TextDirection.ltr, onChanged: (_) => setState(() => _picked = null), decoration: InputDecoration(labelText: tr(context).mkt.imageLink)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _price, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: fmt(tr(context).mkt.priceIn, {'symbol': o.symbol})))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _stock, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr(context).mkt.stock))),
            ]),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(tr(context).mkt.active), value: _active, onChanged: (v) => setState(() => _active = v)),
            const SizedBox(height: 12),
            LoadingButton(label: tr(context).common.save, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
