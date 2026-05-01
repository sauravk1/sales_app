// lib/data/models/product.dart

class Product {
  final int    id;
  final int    categoryId;
  final String subOptionName;
  final double baseRate;
  final double stockQuantity;

  const Product({
    required this.id,
    required this.categoryId,
    required this.subOptionName,
    required this.baseRate,
    this.stockQuantity = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id:            json['id'] as int,
        categoryId:    json['category_id'] as int,
        subOptionName: json['sub_option_name'] as String,
        baseRate:      (json['base_rate'] as num).toDouble(),
        stockQuantity: (json['stock_quantity'] as num?)?.toDouble() ?? 0,
      );

  Product copyWith({double? stockQuantity, double? baseRate, String? subOptionName}) => Product(
        id:            id,
        categoryId:    categoryId,
        subOptionName: subOptionName ?? this.subOptionName,
        baseRate:      baseRate      ?? this.baseRate,
        stockQuantity: stockQuantity ?? this.stockQuantity,
      );

  Map<String, dynamic> toJson() => {
        'id':              id,
        'category_id':     categoryId,
        'sub_option_name': subOptionName,
        'base_rate':       baseRate,
        'stock_quantity':  stockQuantity,
      };

  bool get isLowStock => stockQuantity < 10;
  bool get isOutOfStock => stockQuantity <= 0;

  @override
  bool operator ==(Object other) => other is Product && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => subOptionName;
}
