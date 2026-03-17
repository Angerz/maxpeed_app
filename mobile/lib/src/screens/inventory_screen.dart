import 'package:flutter/material.dart';

import '../models/inventory_card_item.dart';
import '../models/inventory_group_response.dart';
import '../models/cart_models.dart';
import '../models/rim_grouped_response.dart';
import '../models/rim_inventory_card_item.dart';
import '../panels/add_to_cart_sheet.dart';
import '../panels/inventory_detail_sheet.dart';
import '../panels/rim_detail_sheet.dart';
import '../services/catalog_api_service.dart';
import '../store/cart_store.dart';
import '../widgets/rim_inventory_card.dart';
import '../widgets/tire_inventory_card.dart';

enum InventoryViewMode { tires, rims }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, required this.cartStore});

  final CartStore cartStore;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  final _apiService = CatalogApiService();
  final Map<int, double?> _tireSuggestedPriceCache = <int, double?>{};

  InventoryViewMode _mode = InventoryViewMode.tires;
  bool _includeZeroStock = false;

  bool _isLoadingTires = false;
  bool _isLoadingRims = false;
  String? _tiresError;
  String? _rimsError;
  InventoryGroupResponse? _tiresInventory;
  RimGroupedResponse? _rimsInventory;

  @override
  void initState() {
    super.initState();
    _fetchTires();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTires() async {
    setState(() {
      _isLoadingTires = true;
      _tiresError = null;
    });

    try {
      final response = await _apiService.fetchInventory(
        includeZeroStock: _includeZeroStock,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _tiresInventory = response;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _tiresError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTires = false;
        });
      }
    }
  }

  Future<void> _refreshTires() async {
    try {
      final response = await _apiService.fetchInventory(
        includeZeroStock: _includeZeroStock,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _tiresInventory = response;
        _tiresError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo refrescar inventario de llantas. ${error.toString()}',
          ),
        ),
      );
    }
  }

  Future<void> _fetchRims() async {
    setState(() {
      _isLoadingRims = true;
      _rimsError = null;
    });

    try {
      final response = await _apiService.fetchRimsInventory();
      if (!mounted) {
        return;
      }
      setState(() {
        _rimsInventory = response;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _rimsError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRims = false;
        });
      }
    }
  }

  Future<void> _refreshRims() async {
    try {
      final response = await _apiService.fetchRimsInventory();
      if (!mounted) {
        return;
      }
      setState(() {
        _rimsInventory = response;
        _rimsError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo refrescar inventario de aros. ${error.toString()}',
          ),
        ),
      );
    }
  }

  Future<void> _refreshCurrentMode() {
    return _mode == InventoryViewMode.tires ? _refreshTires() : _refreshRims();
  }

  int _rimNumber(String rimLabel) {
    final match = RegExp(r'R(\d+)', caseSensitive: false).firstMatch(rimLabel);
    return int.tryParse(match?.group(1) ?? '') ?? 9999;
  }

  List<String> _sortGroupKeys(Iterable<String> keys) {
    final sorted = keys.toList();
    sorted.sort((a, b) {
      final byRim = _rimNumber(a).compareTo(_rimNumber(b));
      if (byRim != 0) {
        return byRim;
      }
      return a.compareTo(b);
    });
    return sorted;
  }

  List<InventoryCardItem> _filterAndSortTireItems(
    List<InventoryCardItem> items,
  ) {
    final sorted = List<InventoryCardItem>.from(items)
      ..sort((a, b) => a.code.compareTo(b.code));

    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return sorted;
    }

    return sorted
        .where((item) => item.code.toLowerCase().contains(query))
        .toList();
  }

  List<RimInventoryCardItem> _filterAndSortRimItems(
    List<RimInventoryCardItem> items,
  ) {
    final sorted = List<RimInventoryCardItem>.from(items)
      ..sort((a, b) => a.internalCode.compareTo(b.internalCode));

    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return sorted;
    }

    return sorted
        .where((item) => item.internalCode.toLowerCase().contains(query))
        .toList();
  }

  void _openTireDetail(InventoryCardItem item) {
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

  Future<void> _openRimPreview(RimInventoryCardItem item) async {
    final deactivated = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => RimDetailSheet(item: item, apiService: _apiService),
    );

    if (deactivated == true && mounted) {
      await _fetchRims();
    }
  }

  Future<void> _addTireToCart(InventoryCardItem item) async {
    final cachedSuggested = _tireSuggestedPriceCache[item.inventoryItemId];
    final result = await showModalBottomSheet<AddToCartResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddToCartSheet(
        title: 'Agregar llanta ${item.code}',
        stock: item.stock,
        suggestedPrice: cachedSuggested,
        loadSuggestedPrice: () =>
            _resolveTireSuggestedPrice(item.inventoryItemId),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    widget.cartStore.addProduct(
      inventoryItemId: item.inventoryItemId,
      itemType: CartProductType.tire,
      displayCode: item.code,
      brand: item.brand,
      ownerName: item.owner?.name ?? '-',
      quantity: result.quantity,
      unitPrice: result.unitPrice,
      availableStock: item.stock,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Producto agregado al carrito')),
    );
  }

  Future<void> _addRimToCart(RimInventoryCardItem item) async {
    final result = await showModalBottomSheet<AddToCartResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddToCartSheet(
        title: 'Agregar aro ${item.internalCode}',
        stock: item.stock,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    widget.cartStore.addProduct(
      inventoryItemId: item.inventoryItemId,
      itemType: CartProductType.rim,
      displayCode: item.internalCode,
      brand: item.brand,
      ownerName: item.owner?.name ?? '-',
      quantity: result.quantity,
      unitPrice: result.unitPrice,
      availableStock: item.stock,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Producto agregado al carrito')),
    );
  }

  Future<double?> _resolveTireSuggestedPrice(int inventoryItemId) async {
    if (_tireSuggestedPriceCache.containsKey(inventoryItemId)) {
      return _tireSuggestedPriceCache[inventoryItemId];
    }

    try {
      final detail = await _apiService.fetchInventoryDetail(inventoryItemId);
      final parsed = double.tryParse(detail.suggestedSalePrice.trim());
      _tireSuggestedPriceCache[inventoryItemId] = parsed;
      return parsed;
    } catch (_) {
      _tireSuggestedPriceCache[inventoryItemId] = null;
      return null;
    }
  }

  Widget _buildHeaderControls() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: SegmentedButton<InventoryViewMode>(
            segments: const [
              ButtonSegment(
                value: InventoryViewMode.tires,
                label: Text('Llantas'),
              ),
              ButtonSegment(value: InventoryViewMode.rims, label: Text('Aros')),
            ],
            selected: {_mode},
            onSelectionChanged: (value) {
              final next = value.first;
              if (next == _mode) {
                return;
              }
              setState(() {
                _mode = next;
              });

              if (_mode == InventoryViewMode.rims &&
                  _rimsInventory == null &&
                  !_isLoadingRims) {
                _fetchRims();
              }

              if (_mode == InventoryViewMode.tires &&
                  _tiresInventory == null &&
                  !_isLoadingTires) {
                _fetchTires();
              }
            },
          ),
        ),
        if (_mode == InventoryViewMode.tires)
          SwitchListTile(
            title: const Text('Incluir sin stock'),
            value: _includeZeroStock,
            onChanged: (value) {
              setState(() {
                _includeZeroStock = value;
              });
              _fetchTires();
            },
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _mode == InventoryViewMode.tires
                  ? 'Buscar por código de llanta'
                  : 'Buscar por código interno de aro',
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
      ],
    );
  }

  Widget _buildError(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildTiresList() {
    if (_isLoadingTires) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_tiresError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 360,
            child: _buildError(
              'No se pudo cargar inventario de llantas.\n$_tiresError',
              _fetchTires,
            ),
          ),
        ],
      );
    }

    final groups =
        _tiresInventory?.groups ?? const <String, List<InventoryCardItem>>{};
    final groupKeys = _sortGroupKeys(groups.keys);

    if (groupKeys.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 300,
            child: Center(child: Text('No hay llantas en inventario.')),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 6, bottom: 16),
      children: groupKeys.expand((key) {
        final items = _filterAndSortTireItems(groups[key] ?? const []);
        if (items.isEmpty) {
          return <Widget>[];
        }

        return <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
            child: Text(
              key,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          ...items.map(
            (item) => TireInventoryCard(
              item: item,
              onTap: () => _openTireDetail(item),
              onAdd: () => _addTireToCart(item),
            ),
          ),
        ];
      }).toList(),
    );
  }

  Widget _buildRimsList() {
    if (_isLoadingRims) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_rimsError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 360,
            child: _buildError(
              'No se pudo cargar inventario de aros.\n$_rimsError',
              _fetchRims,
            ),
          ),
        ],
      );
    }

    final groups =
        _rimsInventory?.groups ?? const <String, List<RimInventoryCardItem>>{};
    final groupKeys = _sortGroupKeys(groups.keys);

    if (groupKeys.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 300,
            child: Center(child: Text('No hay aros en inventario.')),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 6, bottom: 16),
      children: groupKeys.expand((key) {
        final items = _filterAndSortRimItems(groups[key] ?? const []);
        if (items.isEmpty) {
          return <Widget>[];
        }

        return <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
            child: Text(
              key,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          ...items.map(
            (item) => RimInventoryCard(
              item: item,
              onTap: () => _openRimPreview(item),
              onAdd: () => _addRimToCart(item),
            ),
          ),
        ];
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeaderControls(),
        const SizedBox(height: 6),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshCurrentMode,
            child: _mode == InventoryViewMode.tires
                ? _buildTiresList()
                : _buildRimsList(),
          ),
        ),
      ],
    );
  }
}
