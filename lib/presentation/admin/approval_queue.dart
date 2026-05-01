// lib/presentation/admin/approval_queue.dart
//
// PaginatedDataTable showing all PENDING sales.
// One-click Approve / Reject with Realtime live updates.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/sale.dart';
import '../../providers/providers.dart';

class ApprovalQueue extends ConsumerWidget {
  const ApprovalQueue({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(pendingSalesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Approval Queue',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'Live updates via Supabase Realtime',
                        style: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Live indicator dot
                Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(
                    color:  AppTheme.success,
                    shape:  BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text('Live', style: TextStyle(color: AppTheme.success, fontSize: 12)),
                const SizedBox(width: 12),
                IconButton(
                  icon:     const Icon(Icons.refresh),
                  onPressed: () => ref.read(pendingSalesProvider.notifier).refresh(),
                  tooltip:  'Refresh',
                ),
              ],
            ),
          ),
          Expanded(
            child: salesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                    const SizedBox(height: 12),
                    Text('$e', style: TextStyle(color: AppTheme.onSurfaceSub)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(pendingSalesProvider.notifier).refresh(),
                      child:     const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (sales) {
                if (sales.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 72, color: AppTheme.success),
                        const SizedBox(height: 16),
                        Text(
                          'All caught up!',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text('No pending sales to approve', style: TextStyle(color: AppTheme.onSurfaceSub)),
                      ],
                    ),
                  );
                }

                return _SalesPaginatedTable(sales: sales);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesPaginatedTable extends ConsumerStatefulWidget {
  const _SalesPaginatedTable({required this.sales});
  final List<Sale> sales;

  @override
  ConsumerState<_SalesPaginatedTable> createState() => _SalesPaginatedTableState();
}

class _SalesPaginatedTableState extends ConsumerState<_SalesPaginatedTable> {
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  int _sortColumnIndex = 0;
  bool _ascending = false;

  late List<Sale> _sorted;

  @override
  void initState() {
    super.initState();
    _sorted = List.from(widget.sales);
  }

  @override
  void didUpdateWidget(_SalesPaginatedTable old) {
    super.didUpdateWidget(old);
    _sorted = List.from(widget.sales);
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _ascending       = ascending;
      _sorted.sort((a, b) {
        final cmp = switch (columnIndex) {
          0 => a.createdAt.compareTo(b.createdAt),
          1 => (a.staffName ?? '').compareTo(b.staffName ?? ''),
          2 => (a.categoryName ?? '').compareTo(b.categoryName ?? ''),
          3 => (a.productName  ?? '').compareTo(b.productName  ?? ''),
          4 => a.quantity.compareTo(b.quantity),
          5 => a.totalAmount.compareTo(b.totalAmount),
          _ => 0,
        };
        return ascending ? cmp : -cmp;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PaginatedDataTable(
        header: Text(
          '${widget.sales.length} Pending Sales',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        rowsPerPage:       _rowsPerPage,
        availableRowsPerPage: const [10, 25, 50],
        onRowsPerPageChanged: (v) => setState(() => _rowsPerPage = v ?? 10),
        sortColumnIndex:   _sortColumnIndex,
        sortAscending:     _ascending,
        columnSpacing:     24,
        horizontalMargin:  16,
        columns: [
          DataColumn(label: const Text('Date'),     onSort: _sort),
          DataColumn(label: const Text('Staff'),    onSort: _sort),
          DataColumn(label: const Text('Category'), onSort: _sort),
          DataColumn(label: const Text('Product'),  onSort: _sort),
          DataColumn(label: const Text('Qty'),      onSort: _sort, numeric: true),
          DataColumn(label: const Text('Amount'),   onSort: _sort, numeric: true),
          const DataColumn(label: Text('Actions')),
        ],
        source: _SalesDataSource(sales: _sorted, ref: ref, context: context),
      ),
    );
  }
}

class _SalesDataSource extends DataTableSource {
  _SalesDataSource({
    required this.sales,
    required this.ref,
    required this.context,
  });

  final List<Sale>  sales;
  final WidgetRef   ref;
  final BuildContext context;

  @override
  DataRow? getRow(int index) {
    if (index >= sales.length) return null;
    final sale = sales[index];

    return DataRow(
      key: ValueKey(sale.id),
      cells: [
        DataCell(Text(sale.formattedDate, style: const TextStyle(fontSize: 13))),
        DataCell(Text(sale.staffName    ?? '—', style: const TextStyle(fontSize: 13))),
        DataCell(Text(sale.categoryName ?? '—', style: const TextStyle(fontSize: 13))),
        DataCell(Text(sale.productName  ?? '—', style: const TextStyle(fontSize: 13))),
        DataCell(Text(sale.quantity.toStringAsFixed(2), style: const TextStyle(fontSize: 13))),
        DataCell(Text(sale.formattedAmount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                label:   'Approve',
                color:   AppTheme.success,
                icon:    Icons.check_circle_outline,
                onTap: () async {
                  try {
                    await ref.read(pendingSalesProvider.notifier).approve(sale.id);
                    // Invalidate product cache so inventory shows updated stock
                    ref.invalidate(productNotifierProvider);
                    ref.invalidate(productsByCategoryProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sale approved ✓ — stock updated'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(width: 8),
              _ActionButton(
                label:   'Reject',
                color:   AppTheme.error,
                icon:    Icons.cancel_outlined,
                onTap: () async {
                  final confirm = await _confirmDialog(context);
                  if (confirm == true) {
                    await ref.read(pendingSalesProvider.notifier).reject(sale.id);
                    // Invalidate product cache — stock restored by DB trigger
                    ref.invalidate(productNotifierProvider);
                    ref.invalidate(productsByCategoryProvider);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => sales.length;

  @override
  int get selectedRowCount => 0;

  Future<bool?> _confirmDialog(BuildContext ctx) => showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
          title: const Text('Reject Sale?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:     const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child:     const Text('Reject'),
            ),
          ],
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String     label;
  final Color      color;
  final IconData   icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
