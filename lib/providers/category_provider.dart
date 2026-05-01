// lib/providers/category_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category.dart';
import 'auth_provider.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(supabaseServiceProvider).fetchCategories();
});

// Notifier for admin CRUD on categories
class CategoryNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() =>
      ref.watch(supabaseServiceProvider).fetchCategories();

  Future<void> add(String name) async {
    final service = ref.read(supabaseServiceProvider);
    final cat = await service.addCategory(name);
    state = AsyncData([...state.value ?? [], cat]
      ..sort((a, b) => a.name.compareTo(b.name)));
  }

  Future<void> delete(int id) async {
    await ref.read(supabaseServiceProvider).deleteCategory(id);
    state = AsyncData(
      (state.value ?? []).where((c) => c.id != id).toList(),
    );
  }
}

final categoryNotifierProvider =
    AsyncNotifierProvider<CategoryNotifier, List<Category>>(CategoryNotifier.new);
