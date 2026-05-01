// lib/presentation/shell/platform_shell.dart
//
// Responsive shell: mobile = BottomNavigationBar, web/desktop = NavigationRail.
// Renders Staff UI or Admin UI based on profile.role.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../staff/staff_home.dart';
import '../staff/sales_entry_form.dart';
import '../admin/approval_queue.dart';
import '../admin/inventory_management.dart';
import '../admin/admin_report.dart';

class PlatformShell extends ConsumerStatefulWidget {
  const PlatformShell({super.key});

  @override
  ConsumerState<PlatformShell> createState() => _PlatformShellState();
}

class _PlatformShellState extends ConsumerState<PlatformShell> {
  int _selectedIndex = 0;

  // ── Staff destinations ──────────────────────────────
  static const _staffDestinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'New Sale'),
  ];

  // ── Admin destinations ──────────────────────────────
  static const _adminDestinations = [
    NavigationDestination(icon: Icon(Icons.pending_actions_outlined), selectedIcon: Icon(Icons.pending_actions), label: 'Queue'),
    NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Inventory'),
    NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
  ];

  List<Widget> _staffPages(bool isAdmin) => [
        const StaffHome(),
        const SalesEntryForm(),
      ];

  List<Widget> _adminPages() => [
        const ApprovalQueue(),
        const InventoryManagement(),
        const AdminReport(),
      ];

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text('Profile not found')),
          );
        }

        final isAdmin = profile.isAdmin;
        final destinations = isAdmin ? _adminDestinations : _staffDestinations;
        final pages        = isAdmin ? _adminPages() : _staffPages(isAdmin);
        final clampedIndex = _selectedIndex.clamp(0, pages.length - 1);

        final isWide = MediaQuery.sizeOf(context).width >= 720;

        if (isWide) {
          return _WideLayout(
            destinations:  destinations,
            selectedIndex: clampedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            page:          pages[clampedIndex],
            profile:       profile,
          );
        } else {
          return _NarrowLayout(
            destinations:  destinations,
            selectedIndex: clampedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            page:          pages[clampedIndex],
            profile:       profile,
          );
        }
      },
    );
  }
}

// ── Wide Layout (Web / Desktop) ──────────────────────
class _WideLayout extends ConsumerWidget {
  const _WideLayout({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.page,
    required this.profile,
  });

  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget page;
  final dynamic profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          // ── Side Rail ─────────────────────────────
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVar,
              border: Border(right: BorderSide(color: AppTheme.outline)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo / Brand
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.secondary],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.storefront, color: Colors.white, size: 26),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'SalesLedger',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        profile.isAdmin ? 'Admin Panel' : 'Staff Portal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceSub,
                        ),
                      ),
                    ],
                  ),
                ),
                // Nav items
                ...destinations.asMap().entries.map((e) {
                  final i    = e.key;
                  final dest = e.value;
                  final sel  = i == selectedIndex;
                  return _NavRailItem(
                    icon:     sel ? dest.selectedIcon! : dest.icon,
                    label:    dest.label,
                    selected: sel,
                    onTap:    () => onDestinationSelected(i),
                  );
                }),
                const Spacer(),
                // Profile + sign-out
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            profile.fullName.isNotEmpty
                                ? profile.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(
                          profile.fullName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          profile.role.toUpperCase(),
                          style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceSub),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.logout, size: 18),
                          tooltip: 'Sign out',
                          onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Main content ──────────────────────────
          Expanded(child: page),
        ],
      ),
    );
  }
}

class _NavRailItem extends StatelessWidget {
  const _NavRailItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final bool   selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color:        selected ? AppTheme.primary.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: IconTheme(
          data: IconThemeData(
            color: selected ? AppTheme.primary : AppTheme.onSurfaceSub,
            size: 22,
          ),
          child: icon,
        ),
        title: Text(
          label,
          style: TextStyle(
            color:      selected ? AppTheme.primary : AppTheme.onSurfaceSub,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize:   14,
          ),
        ),
        onTap:         onTap,
        shape:         RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense:         true,
      ),
    );
  }
}

// ── Narrow Layout (Mobile) ───────────────────────────
class _NarrowLayout extends ConsumerWidget {
  const _NarrowLayout({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.page,
    required this.profile,
  });

  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget page;
  final dynamic profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SalesLedger'),
        actions: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primary,
            child: Text(
              profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: page,
      bottomNavigationBar: NavigationBar(
        backgroundColor:  AppTheme.surfaceVar,
        selectedIndex:    selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations:     destinations,
        height:           64,
        labelBehavior:    NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
    );
  }
}
