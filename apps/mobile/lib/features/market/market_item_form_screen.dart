import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import '../engagement/engagement_models.dart';
import '../engagement/engagement_repository.dart';

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
      setState(() => _error = 'الاسم والسعر مطلوبان');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.saveItem(
        _orgId,
        id: widget.itemId,
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        imageUrl: _image.text.trim().isEmpty ? null : _image.text.trim(),
        price: price,
        stock: int.tryParse(_stock.text.trim()),
        isActive: _active,
      );
      if (mounted) context.pop();
    } on PostgrestException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العنصر'),
        content: const Text('الطلبات السابقة تحتفظ باسمه وسعره. متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
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
        title: Text(widget.itemId == null ? 'عنصر جديد' : 'تعديل عنصر'),
        actions: [if (widget.itemId != null) IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete)],
      ),
      body: AsyncBody<MarketOverview>(
        future: _future,
        builder: (context, o) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) MessageBanner(message: _error!),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'الاسم')),
            const SizedBox(height: 12),
            TextField(controller: _description, maxLines: 2, decoration: const InputDecoration(labelText: 'الوصف')),
            const SizedBox(height: 12),
            TextField(controller: _image, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'رابط الصورة (اختياري)')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'السعر (${o.symbol})'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المخزون (فارغ = بلا حد)'))),
            ]),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('فعّال (يظهر للطلاب)'), value: _active, onChanged: (v) => setState(() => _active = v)),
            const SizedBox(height: 12),
            LoadingButton(label: 'حفظ', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
