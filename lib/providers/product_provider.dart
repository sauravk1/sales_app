// lib/providers/product_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/product.dart';
import 'auth_provider.dart';

/// Family provider — fetches products for a given categoryId.
final productsByCategoryProvider =
    FutureProvider.family<List<Product>, int>((ref, categoryId) async {
  return ref.watch(supabaseServiceProvider).fetchProductsByCategory(categoryId);
});

/// All products (for admin inventory view).
final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(supabaseServiceProvider).fetchAllProducts();
});

// ─────────────────────────────────────────────────────
// ProductNotifier: Admin CRUD + Realtime stock updates
// ─────────────────────────────────────────────────────
class ProductNotifier extends AsyncNotifier<List<Product>> {
  RealtimeChannel? _channel;

  @override
  Future<List<Product>> build() async {
    final products = await ref.watch(supabaseServiceProvider).fetchAllProducts();

    // Subscribe to product updates (e.g. stock changes from trigger)
    _channel = ref.read(supabaseServiceProvider).subscribeProductChanges(
      onChange: (payload) {
        final updatedId    = payload['id'] as int?;
        final updatedStock = (payload['stock_quantity'] as num?)?.toDouble();
        if (updatedId == null) return;

        // Update matching product in state
        final current = state.value ?? [];
        final idx = current.indexWhere((p) => p.id == updatedId);
        if (idx != -1) {
          final updated = current[idx].copyWith(stockQuantity: updatedStock);
          final newList = [...current];
          newList[idx]  = updated;
          state = AsyncData(newList);
        }

        // Also invalidate the per-category family provider
        ref.invalidate(productsByCategoryProvider);
      },
    );

    ref.onDispose(() {
      if (_channel != null) {
        ref.read(supabaseServiceProvider).unsubscribeChannel(_channel!);
      }
    });

    return products;
  }

  Future<void> add({
    required int    categoryId,
    required String subOptionName,
    required double baseRate,
  }) async {
    final p = await ref.read(supabaseServiceProvider).addProduct(
          categoryId:    categoryId,
          subOptionName: subOptionName,
          baseRate:      baseRate,
        );
    state = AsyncData([...state.value ?? [], p]);
    ref.invalidate(productsByCategoryProvider);
  }

  Future<void> updateProduct({
    required int    id,
    String?         subOptionName,
    double?         baseRate,
  }) async {
    final updated = await ref.read(supabaseServiceProvider).updateProduct(
          id:            id,
          subOptionName: subOptionName,
          baseRate:      baseRate,
        );
    state = AsyncData(
      (state.value ?? []).map((p) => p.id == id ? updated : p).toList(),
    );
    ref.invalidate(productsByCategoryProvider);
  }

  Future<void> delete(int id) async {
    await ref.read(supabaseServiceProvider).deleteProduct(id);
    state = AsyncData(
      (state.value ?? []).where((p) => p.id != id).toList(),
    );
    ref.invalidate(productsByCategoryProvider);
  }
}

final productNotifierProvider =
    AsyncNotifierProvider<ProductNotifier, List<Product>>(ProductNotifier.new);
