// lib/presentation/admin/inventory_management.dart
//
// Admin view: tree-like Category → Products hierarchy.
// Supports adding / editing / deleting categories and products inline.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/category.dart';
import '../../data/models/product.dart';
import '../../providers/providers.dart';

class InventoryManagement extends ConsumerWidget {
  const InventoryManagement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inventory',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'Manage categories & products',
                        style: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _AddCategoryButton(
                  onAdd: (name) => ref.read(categoryNotifierProvider.notifier).add(name),
                ),
              ],
            ),
          ),

          // ── Category list ────────────────────────────────
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => Center(
                child: Text('Error: $e', style: const TextStyle(color: AppTheme.error)),
              ),
              data: (categories) => categories.isEmpty
                  ? _EmptyState(
                      icon:    Icons.category_outlined,
                      message: 'No categories yet',
                      sub:     'Tap "Add Category" to get started',
                    )
                  : ListView.builder(
                      padding:     const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount:   categories.length,
                      itemBuilder: (_, i) => _CategoryTile(category: categories[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category tile (expandable) ───────────────────────
class _CategoryTile extends ConsumerStatefulWidget {
  const _CategoryTile({required this.category});
  final Category category;

  @override
  ConsumerState<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends ConsumerState<_CategoryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsByCategoryProvider(widget.category.id));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          // ── Category header ──────────────────────────
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.category, color: Colors.white, size: 20),
            ),
            title: Text(
              widget.category.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: productsAsync.maybeWhen(
              data: (p) => Text(
                '${p.length} product${p.length != 1 ? 's' : ''}',
                style: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 12),
              ),
              orElse: () => null,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add product button
                IconButton(
                  icon:    const Icon(Icons.add_circle_outline, color: AppTheme.secondary),
                  tooltip: 'Add product',
                  onPressed: () => _showAddProductDialog(context),
                ),
                // Delete category
                IconButton(
                  icon:    const Icon(Icons.delete_outline, color: AppTheme.error),
                  tooltip: 'Delete category',
                  onPressed: () => _confirmDeleteCategory(context),
                ),
                // Expand / collapse
                AnimatedRotation(
                  turns:    _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    icon:      const Icon(Icons.expand_more),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                ),
              ],
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),

          // ── Products (expanded) ──────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve:    Curves.easeInOut,
            child: _expanded
                ? productsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child:   Text('Error: $e', style: const TextStyle(color: AppTheme.error)),
                    ),
                    data: (products) => products.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              'No products — tap + to add one',
                              style: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 13),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Column(
                              children: products
                                  .map((p) => _ProductRow(product: p))
                                  .toList(),
                            ),
                          ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AddProductDialog(categoryId: widget.category.id),
    );
  }

  Future<void> _confirmDeleteCategory(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Delete Category?'),
        content: Text('Delete "${widget.category.name}" and all its products?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:     const Text('Cancel'),
          ),
          ElevatedButton(
            style:     ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child:     const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(categoryNotifierProvider.notifier).delete(widget.category.id);
    }
  }
}

// ── Product row ──────────────────────────────────────
class _ProductRow extends ConsumerWidget {
  const _ProductRow({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.subdirectory_arrow_right, size: 16, color: AppTheme.onSurfaceSub),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.subOptionName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      product.isOutOfStock ? Icons.warning_rounded : (product.isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined),
                      size:  12,
                      color: product.isOutOfStock ? AppTheme.error : (product.isLowStock ? Colors.orange : AppTheme.onSurfaceSub),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Stock: ${product.stockQuantity.toStringAsFixed(0)} units',
                      style: TextStyle(
                        fontSize: 11,
                        color: product.isOutOfStock ? AppTheme.error : (product.isLowStock ? Colors.orange : AppTheme.onSurfaceSub),
                        fontWeight: product.isLowStock ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:        AppTheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border:       Border.all(color: AppTheme.secondary.withOpacity(0.3)),
            ),
            child: Text(
              '₹${product.baseRate.toStringAsFixed(2)}',
              style: const TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 2),
          // Add stock
          IconButton(
            icon:    const Icon(Icons.add_box_outlined, size: 18, color: AppTheme.secondary),
            tooltip: 'Add Stock',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _AddStockDialog(product: product),
            ),
          ),
          IconButton(
            icon:    const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
            tooltip: 'Edit',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _EditProductDialog(product: product),
            ),
          ),
          IconButton(
            icon:    const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
            tooltip: 'Delete',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title:   const Text('Delete Product?'),
                  content: Text('Delete "${product.subOptionName}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style:     ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                      onPressed: () => Navigator.pop(context, true),
                      child:     const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(productNotifierProvider.notifier).delete(product.id);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── Add Category button + dialog ─────────────────────
class _AddCategoryButton extends StatelessWidget {
  const _AddCategoryButton({required this.onAdd});
  final Future<void> Function(String name) onAdd;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon:  const Icon(Icons.add, size: 18),
      label: const Text('Add Category'),
      onPressed: () => showDialog(
        context: context,
        builder: (_) => _AddCategoryDialog(onAdd: onAdd),
      ),
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog({required this.onAdd});
  final Future<void> Function(String) onAdd;

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _ctrl    = TextEditingController();
  bool  _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:   const Text('New Category'),
      content: TextField(
        controller:   _ctrl,
        autofocus:    true,
        decoration:   InputDecoration(
          labelText: 'Category name',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child:     const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : () async {
            final name = _ctrl.text.trim();
            if (name.isEmpty) {
              setState(() => _error = 'Name is required');
              return;
            }
            setState(() => _loading = true);
            try {
              await widget.onAdd(name);
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              setState(() { _loading = false; _error = e.toString(); });
            }
          },
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Add'),
        ),
      ],
    );
  }
}

// ── Add Product dialog ────────────────────────────────
class _AddProductDialog extends ConsumerStatefulWidget {
  const _AddProductDialog({required this.categoryId});
  final int categoryId;

  @override
  ConsumerState<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<_AddProductDialog> {
  final _nameCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:   const Text('Add Product'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller:  _nameCtrl,
            autofocus:   true,
            decoration:  const InputDecoration(labelText: 'Sub-option name (e.g. ACC)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller:  _rateCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
            decoration:  const InputDecoration(labelText: 'Base rate (₹)', prefixText: '₹ '),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : () async {
            final name = _nameCtrl.text.trim();
            final rate = double.tryParse(_rateCtrl.text);
            if (name.isEmpty || rate == null || rate < 0) {
              setState(() => _error = 'Please enter valid name and rate');
              return;
            }
            setState(() { _loading = true; _error = null; });
            try {
              await ref.read(productNotifierProvider.notifier).add(
                    categoryId:    widget.categoryId,
                    subOptionName: name,
                    baseRate:      rate,
                  );
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              setState(() { _loading = false; _error = e.toString(); });
            }
          },
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Add'),
        ),
      ],
    );
  }
}

// ── Edit Product dialog ───────────────────────────────
class _EditProductDialog extends ConsumerStatefulWidget {
  const _EditProductDialog({required this.product});
  final Product product;

  @override
  ConsumerState<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends ConsumerState<_EditProductDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _rateCtrl;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.subOptionName);
    _rateCtrl = TextEditingController(text: widget.product.baseRate.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:   const Text('Edit Product'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller:  _nameCtrl,
            autofocus:   true,
            decoration:  const InputDecoration(labelText: 'Sub-option name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller:  _rateCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
            decoration:  const InputDecoration(labelText: 'Base rate (₹)', prefixText: '₹ '),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : () async {
            final name = _nameCtrl.text.trim();
            final rate = double.tryParse(_rateCtrl.text);
            if (name.isEmpty || rate == null || rate < 0) {
              setState(() => _error = 'Please enter valid name and rate');
              return;
            }
            setState(() { _loading = true; _error = null; });
            try {
              await ref.read(productNotifierProvider.notifier).updateProduct(
                    id:            widget.product.id,
                    subOptionName: name,
                    baseRate:      rate,
                  );
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              setState(() { _loading = false; _error = e.toString(); });
            }
          },
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ── Add Stock dialog ─────────────────────────────────
class _AddStockDialog extends ConsumerStatefulWidget {
  const _AddStockDialog({required this.product});
  final Product product;

  @override
  ConsumerState<_AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends ConsumerState<_AddStockDialog> {
  final _qtyCtrl = TextEditingController();
  bool    _loading = false;
  String? _error;
  double? _newStock;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Stock — ${widget.product.subOptionName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current stock: ${widget.product.stockQuantity.toStringAsFixed(0)} units',
            style: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller:   _qtyCtrl,
            autofocus:    true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:   InputDecoration(
              labelText: 'Quantity to add',
              suffixText: 'units',
              errorText:  _error,
            ),
          ),
          if (_newStock != null) ...[                    
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        AppTheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.secondary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'New stock: ${_newStock!.toStringAsFixed(0)} units',
                    style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ElevatedButton(
          onPressed: _loading ? null : () async {
            final qty = double.tryParse(_qtyCtrl.text);
            if (qty == null || qty <= 0) {
              setState(() => _error = 'Enter a valid quantity');
              return;
            }
            setState(() { _loading = true; _error = null; });
            try {
              final newStock = await ref
                  .read(supabaseServiceProvider)
                  .addStock(productId: widget.product.id, quantity: qty);
              // Refresh the product list
              ref.invalidate(productsByCategoryProvider(widget.product.categoryId));
              ref.invalidate(productNotifierProvider);
              setState(() { _loading = false; _newStock = newStock; });
              _qtyCtrl.clear();
            } catch (e) {
              setState(() { _loading = false; _error = e.toString(); });
            }
          },
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Add Stock'),
        ),
      ],
    );
  }
}

// ── Shared empty state ────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message, required this.sub});
  final IconData icon;
  final String   message, sub;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.onSurfaceSub),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.onSurfaceSub)),
          const SizedBox(height: 8),
          Text(sub, style: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 13)),
        ],
      ),
    );
  }
}
