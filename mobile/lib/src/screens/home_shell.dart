import 'package:flutter/material.dart';

import '../screens/cart_screen.dart';
import '../store/cart_store.dart';
import 'inventory_screen.dart';
import 'sales_screen.dart';
import 'tire_entry_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

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
    final pages = [
      InventoryScreen(cartStore: _cartStore),
      const TireEntryScreen(),
      const SalesScreen(),
    ];

    final titles = ['Inventario', 'Ingreso de mercadería', 'Ventas'];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_currentIndex])),
      body: IndexedStack(index: _currentIndex, children: pages),
      floatingActionButton: AnimatedBuilder(
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
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onError,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.playlist_add_outlined),
            selectedIcon: Icon(Icons.playlist_add_check_circle),
            label: 'Ingresar',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Ventas',
          ),
        ],
      ),
    );
  }
}
