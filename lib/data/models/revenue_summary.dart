// lib/data/models/revenue_summary.dart

class CategoryRevenue {
  final String category;
  final double amount;
  const CategoryRevenue({required this.category, required this.amount});
}

class RevenueSummary {
  final double totalRevenue;
  final int totalSales;
  final double avgSaleValue;
  final List<CategoryRevenue> byCategory;

  const RevenueSummary({
    required this.totalRevenue,
    required this.totalSales,
    required this.avgSaleValue,
    required this.byCategory,
  });

  factory RevenueSummary.fromJson(Map<String, dynamic> json) {
    final byCatRaw = json['by_category'] as Map<String, dynamic>? ?? {};
    final byCategory = byCatRaw.entries
        .map((e) => CategoryRevenue(
              category: e.key,
              amount:   (e.value as num).toDouble(),
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return RevenueSummary(
      totalRevenue:  (json['total_revenue'] as num?)?.toDouble() ?? 0,
      totalSales:    (json['total_sales']   as int?)            ?? 0,
      avgSaleValue:  (json['avg_sale_value'] as num?)?.toDouble() ?? 0,
      byCategory:    byCategory,
    );
  }

  static RevenueSummary empty() => const RevenueSummary(
        totalRevenue:  0,
        totalSales:    0,
        avgSaleValue:  0,
        byCategory:    [],
      );
}
