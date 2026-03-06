import 'package:flutter/material.dart';

import '../models/inventory_card_item.dart';
import '../models/inventory_group_response.dart';
import '../panels/inventory_detail_sheet.dart';
import '../services/catalog_api_service.dart';
import '../widgets/tire_inventory_card.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  final _apiService = CatalogApiService();

  bool _includeZeroStock = false;
  bool _isLoading = true;
  String? _error;
  InventoryGroupResponse? _inventory;

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInventory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.fetchInventory(includeZeroStock: _includeZeroStock);
      if (!mounted) {
        return;
      }
      setState(() {
        _inventory = response;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _rimNumber(String rimLabel) {
    final match = RegExp(r'R(\d+)', caseSensitive: false).firstMatch(rimLabel);
    return int.tryParse(match?.group(1) ?? '') ?? 9999;
  }

  List<String> _sortedGroupKeys(Map<String, List<InventoryCardItem>> groups) {
    final keys = groups.keys.toList();
    keys.sort((a, b) {
      final byRim = _rimNumber(a).compareTo(_rimNumber(b));
      if (byRim != 0) {
        return byRim;
      }
      return a.compareTo(b);
    });
    return keys;
  }

  List<InventoryCardItem> _sortedItems(List<InventoryCardItem> items) {
    final sorted = List<InventoryCardItem>.from(items);
    sorted.sort((a, b) => a.code.compareTo(b.code));

    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return sorted;
    }

    return sorted.where((item) => item.code.toLowerCase().contains(query)).toList();
  }

  void _openDetail(InventoryCardItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => InventoryDetailSheet(
        inventoryItemId: item.inventoryItemId,
        apiService: _apiService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No se pudo cargar inventario.\n$_error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _fetchInventory,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final groups = _inventory?.groups ?? const <String, List<InventoryCardItem>>{};
    final keys = _sortedGroupKeys(groups);

    if (keys.isEmpty) {
      return Column(
        children: [
          SwitchListTile(
            title: const Text('Incluir sin stock'),
            value: _includeZeroStock,
            onChanged: (value) {
              setState(() {
                _includeZeroStock = value;
              });
              _fetchInventory();
            },
          ),
          const Expanded(
            child: Center(child: Text('No hay items en inventario.')),
          ),
        ],
      );
    }

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Incluir sin stock'),
          value: _includeZeroStock,
          onChanged: (value) {
            setState(() {
              _includeZeroStock = value;
            });
            _fetchInventory();
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Buscar por código',
              hintText: 'Ej: 265, 33x12.5R18',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 6, bottom: 16),
            children: keys.expand((key) {
              final items = _sortedItems(groups[key] ?? const []);
              if (items.isEmpty) {
                return <Widget>[];
              }

              return <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                  child: Text(
                    key,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                ...items.map(
                  (item) => TireInventoryCard(
                    item: item,
                    onTap: () => _openDetail(item),
                  ),
                ),
              ];
            }).toList(),
          ),
        ),
      ],
    );
  }
}
