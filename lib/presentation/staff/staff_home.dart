// lib/presentation/staff/staff_home.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/sale.dart';
import '../../providers/providers.dart';

class StaffHome extends ConsumerWidget {
  const StaffHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(mySalesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Sales',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                  ),
                  Text(
                    'Your recent transactions',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceSub,
                        ),
                  ),
                  const SizedBox(height: 20),
                  // ── Summary row ──────────────────────
                  salesAsync.maybeWhen(
                    data: (sales) => _SummaryRow(sales: sales),
                    orElse:       () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Sales list ───────────────────────────────
          salesAsync.when(
            loading: () => SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, __) => const _ShimmerCard(),
                childCount: 5,
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                    const SizedBox(height: 12),
                    Text('Failed to load sales', style: TextStyle(color: AppTheme.onSurfaceSub)),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => ref.read(mySalesProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (sales) => sales.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 64, color: AppTheme.onSurfaceSub),
                          const SizedBox(height: 16),
                          Text(
                            'No sales yet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.onSurfaceSub,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap "New Sale" to submit your first entry',
                            style: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _SaleCard(sale: sales[i]),
                        childCount: sales.length,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Stats ────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.sales});
  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    final pending  = sales.where((s) => s.status == 'pending').length;
    final approved = sales.where((s) => s.status == 'approved').length;

    return Row(
      children: [
        Expanded(child: _StatChip(label: 'Total Sales', value: sales.length.toString(), color: AppTheme.primary)),
        const SizedBox(width: 10),
        Expanded(child: _StatChip(label: 'Pending',     value: pending.toString(),       color: AppTheme.warning)),
        const SizedBox(width: 10),
        Expanded(child: _StatChip(label: 'Approved',    value: approved.toString(),      color: AppTheme.success)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color});
  final String label, value;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color:      color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Sale Card ────────────────────────────────────────
class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.sale});
  final Sale sale;

  @override
  Widget build(BuildContext context) {

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Category icon pill
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color:        AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${sale.categoryName ?? ''} — ${sale.productName ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${sale.quantity} units × ₹${sale.rate}',
                    style: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sale.formattedDate,
                    style: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  sale.formattedAmount,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 6),
                _StatusBadge(status: sale.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Shimmer placeholder ──────────────────────────────
class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Shimmer.fromColors(
        baseColor:      AppTheme.surfaceVar,
        highlightColor: AppTheme.outline,
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color:        AppTheme.surfaceVar,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
