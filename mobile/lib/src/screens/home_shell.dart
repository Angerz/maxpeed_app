import 'package:flutter/material.dart';

import '../screens/cart_screen.dart';
import '../store/cart_store.dart';
import '../store/session_store.dart';
import 'inventory_screen.dart';
import 'sales_screen.dart';
import 'tire_entry_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  late final CartStore _cartStore;

  @override
  void initState() {
    super.initState();
    _cartStore = CartStore();
  }

  @override
  void dispose() {
    _cartStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canViewInventory = widget.sessionStore.can('can_view_inventory');
    final canCreateStockReceipt = widget.sessionStore.can(
      'can_create_stock_receipt',
    );
    final canCreateSale = widget.sessionStore.can('can_create_sale');
    final canViewSales = widget.sessionStore.can('can_view_sales');

    final tabs = <_ShellTab>[
      if (canViewInventory)
        _ShellTab(
          title: 'Inventario',
          destination: const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          page: InventoryScreen(
            cartStore: _cartStore,
            canCreateSale: canCreateSale,
            canViewZeroStock: widget.sessionStore.can('can_view_zero_stock'),
            canRestock: widget.sessionStore.can('can_restock'),
            canDeactivateRims: widget.sessionStore.can('can_deactivate_rims'),
          ),
        ),
      if (canCreateStockReceipt)
        _ShellTab(
          title: 'Ingreso de mercadería',
          destination: const NavigationDestination(
            icon: Icon(Icons.playlist_add_outlined),
            selectedIcon: Icon(Icons.playlist_add_check_circle),
            label: 'Ingresar',
          ),
          page: const TireEntryScreen(),
        ),
      if (canViewSales)
        _ShellTab(
          title: 'Ventas',
          destination: const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Ventas',
          ),
          page: SalesScreen(
            canViewSaleDetail: widget.sessionStore.can('can_view_sale_detail'),
          ),
        ),
    ];

    if (_currentIndex >= tabs.length) {
      _currentIndex = tabs.isEmpty ? 0 : tabs.length - 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tabs.isEmpty ? 'Maxpeed' : tabs[_currentIndex].title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await widget.sessionStore.logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'logout',
                child: Text('Cerrar sesión'),
              ),
            ],
          ),
        ],
      ),
      body: tabs.isEmpty
          ? const Center(
              child: Text('No tienes permisos para ver módulos disponibles.'),
            )
          : IndexedStack(
              index: _currentIndex,
              children: tabs.map((tab) => tab.page).toList(),
            ),
      floatingActionButton: canCreateSale && tabs.isNotEmpty
          ? AnimatedBuilder(
              animation: _cartStore,
              builder: (context, _) {
                final badgeCount = _cartStore.badgeCount;
                return FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CartScreen(cartStore: _cartStore),
                      ),
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_cart_checkout),
                      if (badgeCount > 0)
                        Positioned(
                          right: -8,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$badgeCount',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onError,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            )
          : null,
      bottomNavigationBar: tabs.length < 2
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: tabs.map((tab) => tab.destination).toList(),
            ),
    );
  }
}

class _ShellTab {
  const _ShellTab({
    required this.title,
    required this.destination,
    required this.page,
  });

  final String title;
  final NavigationDestination destination;
  final Widget page;
}
