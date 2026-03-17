import 'package:flutter/material.dart';

import '../models/inventory_detail.dart';
import '../models/rim_inventory_card_item.dart';
import '../services/catalog_api_service.dart';

class RimDetailSheet extends StatefulWidget {
  const RimDetailSheet({
    super.key,
    required this.item,
    required this.apiService,
    required this.canDeactivateRims,
  });

  final RimInventoryCardItem item;
  final CatalogApiService apiService;
  final bool canDeactivateRims;

  @override
  State<RimDetailSheet> createState() => _RimDetailSheetState();
}

class _RimDetailSheetState extends State<RimDetailSheet> {
  late Future<InventoryDetail> _future;
  bool _isDeactivating = false;
  String? _error;

  bool get _canDeactivate =>
      widget.canDeactivateRims &&
      widget.item.owner?.name.trim().toUpperCase() == 'ALDO';

  @override
  void initState() {
    super.initState();
    _future = widget.apiService.fetchInventoryDetail(
      widget.item.inventoryItemId,
    );
  }

  Future<void> _deactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text(
          '¿Desactivar este aro? Ya no se mostrará en inventario.',
        ),
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aro desactivado')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isDeactivating = false;
        });
      }
    }
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) {
      return '-';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    final local = parsed.toLocal();
    final yy = local.year.toString().padLeft(4, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$yy-$mm-$dd $hh:$min';
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }

  String _fallback(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  String _detailImageUrl(InventoryDetail detail) {
    final full = detail.image?.url.trim() ?? '';
    if (full.isNotEmpty) {
      return full;
    }

    final thumbFromDetail = detail.imageThumb?.url.trim() ?? '';
    if (thumbFromDetail.isNotEmpty) {
      return thumbFromDetail;
    }

    final thumbFromCard = widget.item.imageThumb?.url.trim() ?? '';
    if (thumbFromCard.isNotEmpty) {
      return thumbFromCard;
    }

    return widget.item.image?.url.trim() ?? '';
  }

  Widget _buildImagePreview(String imageUrl) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.album_outlined, size: 80),
            )
          : const Icon(Icons.album_outlined, size: 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: FutureBuilder<InventoryDetail>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 280,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 320,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No se pudo cargar el detalle del aro.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _future = widget.apiService.fetchInventoryDetail(
                            widget.item.inventoryItemId,
                          );
                        });
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            final detail = snapshot.data;
            if (detail == null) {
              return const SizedBox(
                height: 220,
                child: Center(child: Text('Sin detalle.')),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImagePreview(_detailImageUrl(detail)),
                  const SizedBox(height: 14),
                  Text(
                    _fallback(detail.code, widget.item.internalCode),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _row(
                    'Código',
                    _fallback(detail.code, widget.item.internalCode),
                  ),
                  _row('Tipo', detail.tireType),
                  _row('Marca', _fallback(detail.brand, widget.item.brand)),
                  _row('Stock', '${detail.stock}'),
                  _row(
                    'Dueño',
                    detail.owner?.name ?? widget.item.owner?.name ?? '-',
                  ),
                  _row(
                    'Detalles',
                    _fallback(detail.details, widget.item.details),
                  ),
                  _row('Precio compra', detail.purchasePrice),
                  _row('Precio sugerido', detail.suggestedSalePrice),
                  _row('Último restock', _formatDate(detail.lastRestockAt)),
                  _row('Creado', _formatDate(detail.createdAt)),
                  _row('Actualizado', _formatDate(detail.updatedAt)),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
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
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.errorContainer,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onErrorContainer,
                      ),
                      label: Text(
                        _isDeactivating ? 'Desactivando...' : 'Desactivar',
                      ),
                    ),
                  TextButton(
                    onPressed: _isDeactivating
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
