import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  void _refresh(WidgetRef ref) => ref.invalidate(myProductsProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myProductsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'My Products',
          subtitle: 'Everything in your shop',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _edit(context, ref, null),
              icon: const Icon(Icons.add),
              label: const Text('Add product'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _refresh(ref),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        Expanded(
          child: AsyncListView<Product>(
            value: async,
            onRetry: () => _refresh(ref),
            emptyText: 'No products yet. Add your first one.',
            builder: (rows) => SingleChildScrollView(
              child: TableCard(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Stock')),
                  DataColumn(label: Text('Rating')),
                  DataColumn(label: Text('Active')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: rows.map((p) => _row(context, ref, p)).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _row(BuildContext context, WidgetRef ref, Product p) {
    return DataRow(cells: [
      DataCell(Text('${p.id}')),
      DataCell(SizedBox(width: 200, child: Text(p.name, overflow: TextOverflow.ellipsis))),
      DataCell(Text(p.categoryName)),
      DataCell(Text('Rs ${p.price.toStringAsFixed(0)}')),
      DataCell(Text('${p.stock}',
          style: TextStyle(color: p.stock == 0 ? AppColors.danger : AppColors.text))),
      DataCell(Text(p.reviewCount == 0 ? '—' : '${p.averageRating.toStringAsFixed(1)} (${p.reviewCount})')),
      DataCell(StatusBadge(p.isActive ? 'Active' : 'Inactive')),
      DataCell(Row(children: [
        IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _edit(context, ref, p)),
        IconButton(
            icon: const Icon(Icons.delete, size: 18, color: AppColors.danger),
            onPressed: () => _delete(context, ref, p)),
      ])),
    ]);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Product? existing) async {
    final categories = await ref.read(categoriesProvider.future);
    if (!context.mounted) return;
    if (categories.isEmpty) {
      toast(context, 'No categories exist yet. Ask an admin to create one.', error: true);
      return;
    }

    final name = TextEditingController(text: existing?.name ?? '');
    final desc = TextEditingController(text: existing?.description ?? '');
    final price = TextEditingController(text: existing?.price.toStringAsFixed(0) ?? '');
    final stock = TextEditingController(text: existing?.stock.toString() ?? '');
    final image = TextEditingController(text: existing?.imagePath ?? '');
    final unit = TextEditingController(text: existing?.unit ?? '');
    int categoryId = existing?.categoryId ?? categories.first.id;
    bool active = existing?.isActive ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Add product' : 'Edit product'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: desc,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: TextField(
                          controller: price,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Price (Rs)')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                          controller: stock,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Stock')),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: categoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setLocal(() => categoryId = v ?? categoryId),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                      controller: unit,
                      decoration:
                          const InputDecoration(labelText: 'Unit (optional, e.g. Kg)')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                            controller: image,
                            decoration:
                                const InputDecoration(labelText: 'Image path/URL (optional)')),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.upload, size: 18),
                        label: const Text('Upload'),
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            withData: true,
                          );
                          if (result == null || result.files.isEmpty) return;
                          final f = result.files.first;
                          if (f.bytes == null) return;
                          final up = await ref
                              .read(vendorServiceProvider)
                              .uploadProductImage(f.bytes!, f.name);
                          if (up.ok && up.path != null) {
                            setLocal(() => image.text = up.path!);
                          } else if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(up.message)),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  if (existing != null) ...[
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      value: active,
                      onChanged: (v) => setLocal(() => active = v),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final priceVal = double.tryParse(price.text.trim()) ?? 0;
    final stockVal = int.tryParse(stock.text.trim()) ?? 0;
    if (name.text.trim().isEmpty || desc.text.trim().isEmpty || priceVal <= 0) {
      if (context.mounted) toast(context, 'Name, description and a price > 0 are required.', error: true);
      return;
    }

    final body = <String, dynamic>{
      'name': name.text.trim(),
      'description': desc.text.trim(),
      'price': priceVal,
      'stock': stockVal,
      'categoryId': categoryId,
      'imagePath': image.text.trim().isEmpty ? null : image.text.trim(),
      'unit': unit.text.trim().isEmpty ? null : unit.text.trim(),
    };
    if (existing != null) body['isActive'] = active;

    final svc = ref.read(vendorServiceProvider);
    final res = existing == null
        ? await svc.createProduct(body)
        : await svc.updateProduct(existing.id, body);
    if (!context.mounted) return;
    toast(context, res.ok ? 'Saved' : (res.message ?? 'Failed'), error: !res.ok);
    if (res.ok) _refresh(ref);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Product p) async {
    final ok = await confirm(context, 'Delete product?', '"${p.name}" will be removed.');
    if (!ok) return;
    final res = await ref.read(vendorServiceProvider).deleteProduct(p.id);
    if (!context.mounted) return;
    toast(context, res.ok ? 'Deleted' : (res.message ?? 'Failed'), error: !res.ok);
    if (res.ok) _refresh(ref);
  }
}
