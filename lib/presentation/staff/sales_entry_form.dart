// lib/presentation/staff/sales_entry_form.dart
//
// Two-step dependent dropdown:
//   Step 1 → Pick Category  (loads from Supabase)
//   Step 2 → Pick Sub-option (filtered by category_id)
// Rate auto-fills from product.base_rate; staff can override.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/category.dart';
import '../../data/models/product.dart';
import '../../providers/providers.dart';

class SalesEntryForm extends ConsumerStatefulWidget {
  const SalesEntryForm({super.key});

  @override
  ConsumerState<SalesEntryForm> createState() => _SalesEntryFormState();
}

class _SalesEntryFormState extends ConsumerState<SalesEntryForm>
    with SingleTickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController();
  final _rateCtrl     = TextEditingController();
  final _notesCtrl    = TextEditingController();

  Category? _selectedCategory;
  Product?  _selectedProduct;
  bool      _isSubmitting = false;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _quantityCtrl.dispose();
    _rateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onCategoryChanged(Category? cat) {
    setState(() {
      _selectedCategory = cat;
      _selectedProduct  = null;
      _rateCtrl.clear();
    });
  }

  void _onProductChanged(Product? product) {
    setState(() {
      _selectedProduct = product;
      if (product != null) {
        _rateCtrl.text = product.baseRate.toStringAsFixed(2);
      }
    });
  }

  double get _totalAmount {
    final qty  = double.tryParse(_quantityCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text)     ?? 0;
    return qty * rate;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      _showSnack('Please select a product', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(mySalesProvider.notifier).submit(
            productId: _selectedProduct!.id,
            quantity:  double.parse(_quantityCtrl.text),
            rate:      double.parse(_rateCtrl.text),
            notes:     _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );
      _showSnack('Sale submitted successfully!');
      _resetForm();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedCategory = null;
      _selectedProduct  = null;
    });
    _quantityCtrl.clear();
    _rateCtrl.clear();
    _notesCtrl.clear();
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? AppTheme.error : AppTheme.success,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Sale Entry',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'Fill in the details below',
                  style: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 13),
                ),
                const SizedBox(height: 28),

                // ── STEP 1: Category ─────────────────
                _SectionLabel(step: '01', label: 'Select Category'),
                const SizedBox(height: 10),
                categoriesAsync.when(
                  loading: () => const _DropdownSkeleton(),
                  error:   (e, _) => Text('Error: $e', style: const TextStyle(color: AppTheme.error)),
                  data:    (cats) => _CategoryDropdown(
                    categories:       cats,
                    selectedCategory: _selectedCategory,
                    onChanged:        _onCategoryChanged,
                  ),
                ),

                // ── STEP 2: Sub-option (dependent) ───
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve:    Curves.easeInOut,
                  child: _selectedCategory == null
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _SectionLabel(step: '02', label: 'Select Product / Sub-option'),
                            const SizedBox(height: 10),
                            _ProductDropdown(
                              categoryId:      _selectedCategory!.id,
                              selectedProduct: _selectedProduct,
                              onChanged:       _onProductChanged,
                            ),
                          ],
                        ),
                ),

                // ── Quantity & Rate ───────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve:    Curves.easeInOut,
                  child: _selectedProduct == null
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _SectionLabel(step: '03', label: 'Quantity & Rate'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _NumericField(
                                    controller: _quantityCtrl,
                                    label:      'Quantity',
                                    hint:       '0.00',
                                    suffix:     'units',
                                    onChanged:  (_) => setState(() {}),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Required';
                                      final qty = double.tryParse(v) ?? 0;
                                      if (qty <= 0) return 'Must be > 0';
                                      if (_selectedProduct != null &&
                                          qty > _selectedProduct!.stockQuantity) {
                                        return 'Exceeds stock (${_selectedProduct!.stockQuantity.toStringAsFixed(0)} available)';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _NumericField(
                                    controller: _rateCtrl,
                                    label:      'Rate (₹)',
                                    hint:       '0.00',
                                    suffix:     '/unit',
                                    onChanged:  (_) => setState(() {}),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Required';
                                      if ((double.tryParse(v) ?? 0) < 0) return 'Invalid';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── Live total ───────────────
                            if (_totalAmount > 0)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primary.withOpacity(0.15),
                                      AppTheme.secondary.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Amount',
                                        style: TextStyle(fontWeight: FontWeight.w600)),
                                    Text(
                                      '₹${_totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize:   22,
                                        color:      AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 20),
                            _SectionLabel(step: '04', label: 'Notes (optional)'),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller:  _notesCtrl,
                              maxLines:    3,
                              decoration:  const InputDecoration(
                                hintText: 'e.g. delivery address, customer name…',
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ── Submit button ──────────────
                            SizedBox(
                              width:  double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submit,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 22, height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color:       Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_circle_outline, size: 20),
                                          SizedBox(width: 8),
                                          Text('Submit Sale'),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── STEP label ───────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.step, required this.label});
  final String step, label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color:        AppTheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}

// ── Category Dropdown ────────────────────────────────
class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
  });

  final List<Category> categories;
  final Category?      selectedCategory;
  final ValueChanged<Category?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Category>(
      value:          selectedCategory,
      decoration:     const InputDecoration(
        prefixIcon: Icon(Icons.category_outlined),
        hintText:   'Choose a category…',
      ),
      dropdownColor:  AppTheme.surfaceVar,
      items:          categories.map((cat) => DropdownMenuItem(
            value: cat,
            child: Text(cat.name),
          )).toList(),
      onChanged:      onChanged,
      validator: (v) => v == null ? 'Please select a category' : null,
    );
  }
}

// ── Product Dropdown (dependent on categoryId) ────────
class _ProductDropdown extends ConsumerWidget {
  const _ProductDropdown({
    required this.categoryId,
    required this.selectedProduct,
    required this.onChanged,
  });

  final int      categoryId;
  final Product? selectedProduct;
  final ValueChanged<Product?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsByCategoryProvider(categoryId));

    return productsAsync.when(
      loading: () => const _DropdownSkeleton(),
      error:   (e, _) => Text('Error: $e', style: const TextStyle(color: AppTheme.error)),
      data: (products) {
        if (products.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        AppTheme.surfaceVar,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: AppTheme.outline),
            ),
            child: Text(
              'No products found for this category',
              style: TextStyle(color: AppTheme.onSurfaceSub),
            ),
          );
        }
        final validProduct = products.contains(selectedProduct) ? selectedProduct : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<Product>(
              value:         validProduct,
              decoration:    const InputDecoration(
                prefixIcon: Icon(Icons.inventory_2_outlined),
                hintText:   'Choose a sub-option…',
              ),
              dropdownColor: AppTheme.surfaceVar,
              items: products.map((p) {
                final stockLabel = p.isOutOfStock
                    ? '  [OUT OF STOCK]'
                    : '  (Stock: ${p.stockQuantity.toStringAsFixed(0)})';
                return DropdownMenuItem<Product>(
                  value:   p.isOutOfStock ? null : p,
                  enabled: !p.isOutOfStock,
                  child:   Text(
                    '${p.subOptionName}  •  ₹${p.baseRate.toStringAsFixed(0)}$stockLabel',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.isOutOfStock ? AppTheme.onSurfaceSub : null,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              validator: (v) => v == null ? 'Please select a product' : null,
            ),
            if (validProduct != null && validProduct.isLowStock) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Low stock: ${validProduct.stockQuantity.toStringAsFixed(0)} units remaining',
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        );
      },

    );
  }
}

// ── Numeric text field ────────────────────────────────
class _NumericField extends StatelessWidget {
  const _NumericField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.suffix,
    required this.onChanged,
    required this.validator,
  });

  final TextEditingController  controller;
  final String                 label, hint, suffix;
  final ValueChanged<String>   onChanged;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:  controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
      ],
      decoration: InputDecoration(
        labelText:   label,
        hintText:    hint,
        suffixText:  suffix,
        suffixStyle: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 12),
      ),
      onChanged:   onChanged,
      validator:   validator,
    );
  }
}

// ── Loading skeleton for dropdowns ───────────────────
class _DropdownSkeleton extends StatelessWidget {
  const _DropdownSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color:        AppTheme.surfaceVar,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppTheme.outline),
      ),
      alignment: Alignment.centerLeft,
      padding:   const EdgeInsets.symmetric(horizontal: 16),
      child: const SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
