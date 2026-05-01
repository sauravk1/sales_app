// lib/providers/sales_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/sale.dart';
import '../data/models/revenue_summary.dart';
import 'auth_provider.dart';

// ─────────────────────────────────────────────────────
// STAFF: My Sales
// ─────────────────────────────────────────────────────

class MySalesNotifier extends AsyncNotifier<List<Sale>> {
  RealtimeChannel? _channel;

  @override
  Future<List<Sale>> build() async {
    final service  = ref.watch(supabaseServiceProvider);
    final sales    = await service.fetchMySales();
    final staffId  = service.currentUserId;

    if (staffId != null) {
      // Subscribe to any status changes on this staff's sales
      _channel = service.subscribeMySalesChanges(
        staffId: staffId,
        onUpdate: (payload) {
          final id     = payload['id'] as String?;
          final status = payload['status'] as String?;
          if (id == null || status == null) return;

          final current = state.value ?? [];
          final idx = current.indexWhere((s) => s.id == id);
          if (idx != -1) {
            // Refresh the whole list to get updated joined data
            ref.read(supabaseServiceProvider).fetchMySales().then((fresh) {
              state = AsyncData(fresh);
            });
          }
        },
      );

      ref.onDispose(() {
        if (_channel != null) {
          ref.read(supabaseServiceProvider).unsubscribeChannel(_channel!);
        }
      });
    }

    return sales;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(supabaseServiceProvider).fetchMySales());
  }

  Future<void> submit({
    required int    productId,
    required double quantity,
    required double rate,
    String?         notes,
  }) async {
    final sale = await ref.read(supabaseServiceProvider).submitSale(
          productId: productId,
          quantity:  quantity,
          rate:      rate,
          notes:     notes,
        );
    state = AsyncData([sale, ...state.value ?? []]);
  }
}

final mySalesProvider =
    AsyncNotifierProvider<MySalesNotifier, List<Sale>>(MySalesNotifier.new);


// ─────────────────────────────────────────────────────
// ADMIN: Pending Sales (with Realtime)
// ─────────────────────────────────────────────────────

class PendingSalesNotifier extends AsyncNotifier<List<Sale>> {
  RealtimeChannel? _channel;

  @override
  Future<List<Sale>> build() async {
    final sales = await ref.watch(supabaseServiceProvider).fetchPendingSales();
    _subscribeRealtime();
    ref.onDispose(() {
      if (_channel != null) {
        ref.read(supabaseServiceProvider).unsubscribeChannel(_channel!);
      }
    });
    return sales;
  }

  void _subscribeRealtime() {
    _channel = ref.read(supabaseServiceProvider).subscribeSalesChanges(
      onInsert: (payload) {
        // New sale submitted — add to pending list if status == pending
        if (payload['status'] == 'pending') {
          final sale = Sale.fromJson(payload);
          state = AsyncData([sale, ...state.value ?? []]);
        }
      },
      onUpdate: (payload) {
        // Status changed — remove from pending if no longer pending
        final id     = payload['id'] as String;
        final status = payload['status'] as String;
        if (status != 'pending') {
          state = AsyncData(
            (state.value ?? []).where((s) => s.id != id).toList(),
          );
        }
      },
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(supabaseServiceProvider).fetchPendingSales());
  }

  Future<void> approve(String saleId) async {
    await ref.read(supabaseServiceProvider).updateSaleStatus(saleId, 'approved');
    state = AsyncData(
      (state.value ?? []).where((s) => s.id != saleId).toList(),
    );
  }

  Future<void> reject(String saleId) async {
    await ref.read(supabaseServiceProvider).updateSaleStatus(saleId, 'rejected');
    state = AsyncData(
      (state.value ?? []).where((s) => s.id != saleId).toList(),
    );
  }
}

final pendingSalesProvider =
    AsyncNotifierProvider<PendingSalesNotifier, List<Sale>>(PendingSalesNotifier.new);

// ─────────────────────────────────────────────────────
// ADMIN: All Sales
// ─────────────────────────────────────────────────────
final allSalesProvider = FutureProvider<List<Sale>>((ref) async {
  return ref.watch(supabaseServiceProvider).fetchAllSales();
});

// ─────────────────────────────────────────────────────
// ADMIN: Revenue Summary (date range)
// ─────────────────────────────────────────────────────

class DateRangeState {
  final DateTime start;
  final DateTime end;
  const DateRangeState({required this.start, required this.end});
}

final dateRangeProvider = StateProvider<DateRangeState>((ref) {
  final now = DateTime.now();
  return DateRangeState(
    start: DateTime(now.year, now.month, 1),
    end:   now,
  );
});

final revenueSummaryProvider = FutureProvider<RevenueSummary>((ref) async {
  final range = ref.watch(dateRangeProvider);
  return ref.watch(supabaseServiceProvider).fetchRevenueSummary(
        startDate: range.start,
        endDate:   range.end,
      );
});
