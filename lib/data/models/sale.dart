// lib/data/models/sale.dart
import 'package:intl/intl.dart';

class Sale {
  final String id;
  final int productId;
  final double quantity;
  final double rate;
  final double totalAmount;
  final String staffId;
  final String status;
  final DateTime saleDate;
  final String? notes;
  final DateTime createdAt;

  // Joined fields (optional, populated via Supabase select with joins)
  final String? productName;
  final String? categoryName;
  final String? staffName;

  const Sale({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.rate,
    required this.totalAmount,
    required this.staffId,
    required this.status,
    required this.saleDate,
    required this.createdAt,
    this.notes,
    this.productName,
    this.categoryName,
    this.staffName,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    final product = json['products'] as Map<String, dynamic>?;
    final category = product != null
        ? (product['categories'] as Map<String, dynamic>?)
        : null;
    final profile = json['profiles'] as Map<String, dynamic>?;

    return Sale(
      id:           json['id'] as String,
      productId:    json['product_id'] as int,
      quantity:     (json['quantity'] as num).toDouble(),
      rate:         (json['rate'] as num).toDouble(),
      totalAmount:  (json['total_amount'] as num).toDouble(),
      staffId:      json['staff_id'] as String,
      status:       json['status'] as String,
      saleDate:     DateTime.parse(json['sale_date'] as String),
      createdAt:    DateTime.parse(json['created_at'] as String),
      notes:        json['notes'] as String?,
      productName:  product?['sub_option_name'] as String?,
      categoryName: category?['name'] as String?,
      staffName:    profile?['full_name'] as String?,
    );
  }

  String get formattedDate =>
      DateFormat('dd MMM yyyy').format(saleDate);

  String get formattedAmount =>
      '₹${NumberFormat('#,##,##0.00').format(totalAmount)}';
}
