import 'package:flutter/material.dart';

import '../models/tire.dart';
import '../panels/edit_tire_panel.dart';
import '../panels/sell_tire_panel.dart';
import '../panels/tire_detail_panel.dart';
import '../widgets/tire_inventory_card.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, required this.tires});

  final List<Tire> tires;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Tire> _filteredAndSortedTires() {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.tires.where((tire) {
      if (query.isEmpty) {
        return true;
      }
      return tire.code.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      final aRim = _rimValue(a.code);
      final bRim = _rimValue(b.code);
      final byRim = aRim.compareTo(bRim);
      if (byRim != 0) {
        return byRim;
      }
      return a.code.compareTo(b.code);
    });

    return filtered;
  }

  double _rimValue(String code) {
    final match = RegExp(r'R(\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(code);
    if (match == null) {
      return 9999;
    }
    return double.tryParse(match.group(1) ?? '') ?? 9999;
  }

  String _rimLabel(String code) {
    final match = RegExp(r'R(\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(code);
    if (match == null) {
      return 'R?';
    }
    return 'R${match.group(1)}';
  }

  Future<void> _openEditPanel(Tire tire) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EditTirePanel(tire: tire),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados (simulado)')),
      );
    }
  }

  Future<void> _openSellPanel(Tire tire) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SellTirePanel(tire: tire),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta registrada (simulado)')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Seguro que deseas eliminar este artículo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (!mounted) {
      return;
    }

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artículo eliminado (simulado)')),
      );
    }
  }

  void _openDetail(Tire tire) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TireDetailPanel(
        tire: tire,
        onEdit: () {
          Navigator.of(context).pop();
          _openEditPanel(tire);
        },
        onDelete: () {
          Navigator.of(context).pop();
          _confirmDelete();
        },
        onSell: () {
          Navigator.of(context).pop();
          _openSellPanel(tire);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tires = _filteredAndSortedTires();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Buscar por código',
              hintText: 'Ej: 185, 33x12.5R18',
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
        const SizedBox(height: 8),
        Expanded(
          child: tires.isEmpty
              ? const Center(child: Text('Sin resultados para la búsqueda.'))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 20),
                  itemCount: tires.length,
                  itemBuilder: (context, index) {
                    final tire = tires[index];
                    final rimLabel = _rimLabel(tire.code);
                    final showHeader =
                        index == 0 || _rimLabel(tires[index - 1].code) != rimLabel;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                            child: Text(
                              rimLabel,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        TireInventoryCard(
                          tire: tire,
                          onTap: () => _openDetail(tire),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
