// lib/core/constants/supabase_constants.dart

/// Replace these with your actual Supabase project credentials.
/// Found in: Supabase Dashboard → Settings → API
class SupabaseConstants {
  SupabaseConstants._();

  static const String supabaseUrl = 'https://iuokrlbrrbnjbhgqqlud.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1b2tybGJycmJuamJoZ3FxbHVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2MDUyMDUsImV4cCI6MjA5MzE4MTIwNX0.JToRpDKbZcHms7UojwxY4R-0U0ZJHagAWZrFtTRaYfU';

  // Table names
  static const String profilesTable   = 'profiles';
  static const String categoriesTable = 'categories';
  static const String productsTable   = 'products';
  static const String salesTable      = 'sales';

  // RPC function names
  static const String rpcRevenueSummary    = 'get_revenue_summary';
  static const String rpcPendingSalesCount = 'get_pending_sales_count';
}
