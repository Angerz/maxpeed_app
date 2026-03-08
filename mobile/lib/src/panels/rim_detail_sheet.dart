import 'package:flutter/material.dart';

import '../models/rim_inventory_card_item.dart';
import '../services/catalog_api_service.dart';

class RimDetailSheet extends StatefulWidget {
  const RimDetailSheet({
    super.key,
    required this.item,
    required this.apiService,
  });

  final RimInventoryCardItem item;
  final CatalogApiService apiService;

  @override
  State<RimDetailSheet> createState() => _RimDetailSheetState();
}

class _RimDetailSheetState extends State<RimDetailSheet> {
  bool _isDeactivating = false;
  String? _error;

  bool get _canDeactivate => widget.item.owner?.name.trim().toUpperCase() == 'ALDO';

  Future<void> _deactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Desactivar este aro? Ya no se mostrará en inventario.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeactivating = true;
      _error = null;
    });

    try {
      await widget.apiService.deactivateRim(
        widget.item.inventoryItemId,
        reason: 'Retiro ALDO',
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aro desactivado')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.statusCode == 403
                ? 'No autorizado'
                : error.message
          : 'No se pudo desactivar el aro';
      setState(() {
        _error = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isDeactivating = false;
        });
      }
    }
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRow('Código interno', widget.item.internalCode),
              _buildRow('Marca', widget.item.brand),
              _buildRow('Stock', '${widget.item.stock}'),
              _buildRow('Detalles', widget.item.details),
              _buildRow('Dueño', widget.item.owner?.name ?? '-'),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              if (_canDeactivate)
                ElevatedButton.icon(
                  onPressed: _isDeactivating ? null : _deactivate,
                  icon: _isDeactivating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.block),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.errorContainer,
                    foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  label: Text(_isDeactivating ? 'Desactivando...' : 'Desactivar'),
                ),
              TextButton(
                onPressed: _isDeactivating ? null : () => Navigator.of(context).pop(false),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
