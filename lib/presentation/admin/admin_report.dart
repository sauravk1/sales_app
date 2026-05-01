// lib/presentation/admin/admin_report.dart
//
// Revenue Analytics screen for Admin:
//  - DateRangePicker to select period
//  - Calls get_revenue_summary RPC via Riverpod provider
//  - Summary KPI cards + fl_chart bar chart by category

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/revenue_summary.dart';
import '../../providers/providers.dart';

class AdminReport extends ConsumerStatefulWidget {
  const AdminReport({super.key});

  @override
  ConsumerState<AdminReport> createState() => _AdminReportState();
}

class _AdminReportState extends ConsumerState<AdminReport> {
  final _fmt = DateFormat('dd MMM yyyy');

  Future<void> _pickDateRange() async {
    final range = ref.read(dateRangeProvider);
    final picked = await showDateRangePicker(
      context:           context,
      initialDateRange:  DateTimeRange(start: range.start, end: range.end),
      firstDate:         DateTime(2020),
      lastDate:          DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary:    AppTheme.primary,
                onPrimary:  Colors.white,
                surface:    AppTheme.surfaceVar,
                onSurface:  AppTheme.onSurface,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(dateRangeProvider.notifier).state = DateRangeState(
        start: picked.start,
        end:   picked.end,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final range      = ref.watch(dateRangeProvider);
    final summaryAsy = ref.watch(revenueSummaryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // ── Page header ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Reports',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'Approved sales analytics',
                    style: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // ── Date range picker ─────────────────
                  InkWell(
                    onTap:        _pickDateRange,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color:        AppTheme.surfaceVar,
                        borderRadius: BorderRadius.circular(14),
                        border:       Border.all(color: AppTheme.primary.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range, color: AppTheme.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected Period',
                                  style: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_fmt.format(range.start)}  →  ${_fmt.format(range.end)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.edit_calendar_outlined, color: AppTheme.primary, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Summary content ────────────────────────
          summaryAsy.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                    const SizedBox(height: 12),
                    Text('$e', style: TextStyle(color: AppTheme.onSurfaceSub)),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(revenueSummaryProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (summary) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── KPI cards ─────────────────────────
                  _KpiRow(summary: summary),
                  const SizedBox(height: 24),

                  // ── Bar chart ─────────────────────────
                  if (summary.byCategory.isNotEmpty) ...[
                    _SectionTitle('Revenue by Category'),
                    const SizedBox(height: 12),
                    _CategoryBarChart(summary: summary),
                    const SizedBox(height: 24),

                    // ── Category breakdown table ────────
                    _SectionTitle('Category Breakdown'),
                    const SizedBox(height: 12),
                    _CategoryTable(summary: summary),
                  ] else
                    _EmptyReport(),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── KPI row ──────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.summary});
  final RevenueSummary summary;

  @override
  Widget build(BuildContext context) {
    final fmtCur = NumberFormat('#,##,##0.00');
    final fmtInt = NumberFormat('#,##,##0');
    return Column(
      children: [
        // Total revenue — full width
        _KpiCard(
          label:    'Total Revenue',
          value:    '₹${fmtCur.format(summary.totalRevenue)}',
          icon:     Icons.currency_rupee,
          gradient: [AppTheme.primary, AppTheme.secondary],
          large:    true,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Total Sales',
                value: fmtInt.format(summary.totalSales),
                icon:  Icons.receipt_long_outlined,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                label: 'Avg Sale Value',
                value: '₹${fmtCur.format(summary.avgSaleValue)}',
                icon:  Icons.trending_up,
                color: AppTheme.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.gradient,
    this.large = false,
  });

  final String     label, value;
  final IconData   icon;
  final Color?     color;
  final List<Color>? gradient;
  final bool       large;

  @override
  Widget build(BuildContext context) {
    final bg = gradient != null
        ? BoxDecoration(
            gradient:     LinearGradient(colors: gradient!),
            borderRadius: BorderRadius.circular(16),
          )
        : BoxDecoration(
            color:        color?.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: (color ?? AppTheme.primary).withOpacity(0.3)),
          );

    final textColor = gradient != null ? Colors.white : (color ?? AppTheme.primary);

    return Container(
      padding: EdgeInsets.all(large ? 20 : 16),
      decoration: bg,
      child: Row(
        children: [
          Container(
            width: large ? 52 : 40,
            height: large ? 52 : 40,
            decoration: BoxDecoration(
              color:        Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: gradient != null ? Colors.white : textColor, size: large ? 28 : 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color:    gradient != null ? Colors.white70 : AppTheme.onSurfaceSub,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color:      gradient != null ? Colors.white : textColor,
                    fontSize:   large ? 26 : 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bar chart ────────────────────────────────────────
class _CategoryBarChart extends StatelessWidget {
  const _CategoryBarChart({required this.summary});
  final RevenueSummary summary;

  @override
  Widget build(BuildContext context) {
    // Take top 7 categories for readability
    final top = summary.byCategory.take(7).toList();
    final max = top.isEmpty ? 1.0 : top.first.amount;

    final bars = top.asMap().entries.map((e) {
      final i   = e.key;
      final cat = e.value;
      final colors = [
        AppTheme.primary,
        AppTheme.secondary,
        const Color(0xFFFF6B6B),
        const Color(0xFFFFD93D),
        const Color(0xFF6BCB77),
        const Color(0xFF4D96FF),
        const Color(0xFFFF922B),
      ];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY:   cat.amount,
            color: colors[i % colors.length],
            width: 28,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ],
      );
    }).toList();

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color:        AppTheme.surfaceVar,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppTheme.outline),
      ),
      child: BarChart(
        BarChartData(
          maxY:          max * 1.2,
          barGroups:     bars,
          gridData:      FlGridData(
            show:              true,
            drawVerticalLine:  false,
            getDrawingHorizontalLine: (_) => FlLine(
              color:     AppTheme.outline,
              strokeWidth: 1,
            ),
          ),
          borderData:    FlBorderData(show: false),
          titlesData:    FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i >= top.length) return const SizedBox.shrink();
                  final name = top[i].category;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      name.length > 8 ? '${name.substring(0, 7)}…' : name,
                      style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceSub),
                    ),
                  );
                },
                reservedSize: 32,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:   true,
                reservedSize: 60,
                getTitlesWidget: (v, _) => Text(
                  '₹${_shortNum(v)}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceSub),
                ),
              ),
            ),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppTheme.surfaceVar,
              getTooltipItem: (group, _, rod, __) {
                final cat = top[group.x];
                return BarTooltipItem(
                  '${cat.category}\n',
                  const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600, fontSize: 12),
                  children: [
                    TextSpan(
                      text:  '₹${NumberFormat('#,##,##0').format(rod.toY)}',
                      style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w700),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _shortNum(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ── Category breakdown table ─────────────────────────
class _CategoryTable extends StatelessWidget {
  const _CategoryTable({required this.summary});
  final RevenueSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.totalRevenue;
    final fmt   = NumberFormat('#,##,##0.00');

    return Container(
      decoration: BoxDecoration(
        color:        AppTheme.surfaceVar,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(child: Text('Category', style: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 12, fontWeight: FontWeight.w600))),
                SizedBox(width: 100, child: Text('Revenue', textAlign: TextAlign.right, style: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 12, fontWeight: FontWeight.w600))),
                SizedBox(width: 60,  child: Text('Share',   textAlign: TextAlign.right, style: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const Divider(height: 1),
          ...summary.byCategory.asMap().entries.map((e) {
            final pct  = total > 0 ? (e.value.amount / total * 100) : 0.0;
            final colors = [
              AppTheme.primary, AppTheme.secondary,
              const Color(0xFFFF6B6B), const Color(0xFFFFD93D),
              const Color(0xFF6BCB77), const Color(0xFF4D96FF),
            ];
            final color = colors[e.key % colors.length];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(e.value.category, style: const TextStyle(fontSize: 13))),
                      SizedBox(
                        width: 100,
                        child: Text(
                          '₹${fmt.format(e.value.amount)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '${pct.toStringAsFixed(1)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(36, 0, 16, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:            pct / 100,
                      backgroundColor:  AppTheme.outline,
                      color:            color,
                      minHeight:        4,
                    ),
                  ),
                ),
                if (e.key < summary.byCategory.length - 1) const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    );
  }
}

// ── Empty state ───────────────────────────────────────
class _EmptyReport extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color:        AppTheme.surfaceVar,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart_outlined, size: 64, color: AppTheme.onSurfaceSub),
          const SizedBox(height: 16),
          Text(
            'No approved sales in this period',
            style: TextStyle(color: AppTheme.onSurfaceSub, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a wider date range or approve some sales first.',
            style: TextStyle(color: AppTheme.onSurfaceSub, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
