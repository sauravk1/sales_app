// lib/data/services/supabase_service.dart
//
// Single service class for all Supabase CRUD operations.
// Injected via Riverpod (see providers/).

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/profile.dart';
import '../models/sale.dart';
import '../models/revenue_summary.dart';
import '../../core/constants/supabase_constants.dart';

class SupabaseService {
  SupabaseService(this._client);

  final SupabaseClient _client;

  // ── Convenience getters ─────────────────────────────
  SupabaseQueryBuilder get _profiles   => _client.from(SupabaseConstants.profilesTable);
  SupabaseQueryBuilder get _categories => _client.from(SupabaseConstants.categoriesTable);
  SupabaseQueryBuilder get _products   => _client.from(SupabaseConstants.productsTable);
  SupabaseQueryBuilder get _sales      => _client.from(SupabaseConstants.salesTable);

  String? get currentUserId => _client.auth.currentUser?.id;

  // ════════════════════════════════════════════════════
  // AUTH
  // ════════════════════════════════════════════════════

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    return _client.auth.signUp(
      email:    email,
      password: password,
      data:     {'full_name': fullName, 'role': role},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email:    email,
      password: password,
    );
  }

  Future<void> signOut() async => _client.auth.signOut();

  // ════════════════════════════════════════════════════
  // PROFILES
  // ════════════════════════════════════════════════════

  Future<Profile?> fetchCurrentProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    final data = await _profiles.select().eq('id', uid).single();
    return Profile.fromJson(data);
  }

  Future<List<Profile>> fetchAllStaff() async {
    final data = await _profiles
        .select()
        .eq('role', 'staff')
        .order('full_name');
    return (data as List).map((j) => Profile.fromJson(j)).toList();
  }

  // ════════════════════════════════════════════════════
  // CATEGORIES
  // ════════════════════════════════════════════════════

  Future<List<Category>> fetchCategories() async {
    final data = await _categories.select().order('name');
    return (data as List).map((j) => Category.fromJson(j)).toList();
  }

  Future<Category> addCategory(String name) async {
    final data = await _categories
        .insert({'name': name})
        .select()
        .single();
    return Category.fromJson(data);
  }

  Future<void> deleteCategory(int id) async {
    await _categories.delete().eq('id', id);
  }

  // ════════════════════════════════════════════════════
  // PRODUCTS
  // ════════════════════════════════════════════════════

  /// Fetch all products for a given [categoryId].
  Future<List<Product>> fetchProductsByCategory(int categoryId) async {
    final data = await _products
        .select()
        .eq('category_id', categoryId)
        .order('sub_option_name');
    return (data as List).map((j) => Product.fromJson(j)).toList();
  }

  Future<List<Product>> fetchAllProducts() async {
    final data = await _products.select().order('sub_option_name');
    return (data as List).map((j) => Product.fromJson(j)).toList();
  }

  Future<Product> addProduct({
    required int    categoryId,
    required String subOptionName,
    required double baseRate,
  }) async {
    final data = await _products
        .insert({
          'category_id':     categoryId,
          'sub_option_name': subOptionName,
          'base_rate':       baseRate,
        })
        .select()
        .single();
    return Product.fromJson(data);
  }

  Future<Product> updateProduct({
    required int    id,
    String?         subOptionName,
    double?         baseRate,
  }) async {
    final updates = <String, dynamic>{};
    if (subOptionName != null) updates['sub_option_name'] = subOptionName;
    if (baseRate      != null) updates['base_rate']       = baseRate;
    final data = await _products
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return Product.fromJson(data);
  }

  Future<void> deleteProduct(int id) async {
    await _products.delete().eq('id', id);
  }

  // ════════════════════════════════════════════════════
  // SALES
  // ════════════════════════════════════════════════════

  static const _salesJoin = '''
    *,
    products (
      sub_option_name,
      base_rate,
      categories ( name )
    ),
    profiles ( full_name )
  ''';

  /// Staff: fetch their own sales, paginated.
  Future<List<Sale>> fetchMySales({int limit = 20, int offset = 0}) async {
    final uid = currentUserId;
    if (uid == null) return [];
    final data = await _sales
        .select(_salesJoin)
        .eq('staff_id', uid)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (data as List).map((j) => Sale.fromJson(j)).toList();
  }

  /// Admin: fetch all sales, filtered by [status] if provided.
  Future<List<Sale>> fetchAllSales({
    String?  status,
    int      limit  = 50,
    int      offset = 0,
  }) async {
    var query = _sales.select(_salesJoin);
    if (status != null) query = query.eq('status', status);
    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (data as List).map((j) => Sale.fromJson(j)).toList();
  }

  /// Admin: fetch pending sales for approval queue.
  Future<List<Sale>> fetchPendingSales() async =>
      fetchAllSales(status: 'pending', limit: 100);

  /// Staff: submit a new sale.
  Future<Sale> submitSale({
    required int    productId,
    required double quantity,
    required double rate,
    String?         notes,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final data = await _sales
        .insert({
          'product_id': productId,
          'quantity':   quantity,
          'rate':       rate,
          'staff_id':   uid,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        })
        .select(_salesJoin)
        .single();
    return Sale.fromJson(data);
  }

  /// Admin: approve or reject a sale.
  Future<void> updateSaleStatus(String saleId, String status) async {
    assert(status == 'approved' || status == 'rejected');
    await _sales.update({'status': status}).eq('id', saleId);
  }

  // ════════════════════════════════════════════════════
  // REALTIME
  // ════════════════════════════════════════════════════

  /// Returns a broadcast stream of sales changes.
  /// Admin dashboard subscribes to this for live updates.
  RealtimeChannel subscribeSalesChanges({
    required void Function(Map<String, dynamic> payload) onInsert,
    required void Function(Map<String, dynamic> payload) onUpdate,
  }) {
    final channel = _client
        .channel('public:sales')
        .onPostgresChanges(
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  'sales',
          callback: (payload) => onInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event:  PostgresChangeEvent.update,
          schema: 'public',
          table:  'sales',
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
    return channel;
  }

  /// Staff: subscribe to status changes on THEIR own sales.
  RealtimeChannel subscribeMySalesChanges({
    required String staffId,
    required void Function(Map<String, dynamic> payload) onUpdate,
  }) {
    return _client
        .channel('public:sales:staff:$staffId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.update,
          schema: 'public',
          table:  'sales',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'staff_id',
            value:  staffId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  /// Subscribe to product changes (stock updates, edits).
  RealtimeChannel subscribeProductChanges({
    required void Function(Map<String, dynamic> payload) onChange,
  }) {
    return _client
        .channel('public:products')
        .onPostgresChanges(
          event:  PostgresChangeEvent.update,
          schema: 'public',
          table:  'products',
          callback: (payload) => onChange(payload.newRecord),
        )
        .subscribe();
  }

  Future<void> unsubscribeChannel(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }


  // ════════════════════════════════════════════════════
  // ANALYTICS / RPC
  // ════════════════════════════════════════════════════

  /// Calls the `get_revenue_summary` Postgres function.
  Future<RevenueSummary> fetchRevenueSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await _client.rpc(
      SupabaseConstants.rpcRevenueSummary,
      params: {
        'p_start_date': startDate.toIso8601String().substring(0, 10),
        'p_end_date':   endDate.toIso8601String().substring(0, 10),
      },
    );

    // rpc returns a List when RETURNS TABLE; take first row
    final row = (result as List).isNotEmpty
        ? result.first as Map<String, dynamic>
        : <String, dynamic>{};
    return RevenueSummary.fromJson(row);
  }

  // ════════════════════════════════════════════════════
  // STOCK
  // ════════════════════════════════════════════════════

  /// Admin: add stock to a product via the `add_stock` RPC.
  /// Returns the new stock quantity.
  Future<double> addStock({
    required int    productId,
    required double quantity,
  }) async {
    final result = await _client.rpc(
      'add_stock',
      params: {
        'p_product_id': productId,
        'p_quantity':   quantity,
      },
    );
    return (result as num).toDouble();
  }
}
