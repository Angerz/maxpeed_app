import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/inventory_detail.dart';
import '../models/restock_request.dart';
import '../services/catalog_api_service.dart';

class InventoryDetailSheet extends StatefulWidget {
  const InventoryDetailSheet({
    super.key,
    required this.inventoryItemId,
    required this.apiService,
    required this.canRestock,
  });

  final int inventoryItemId;
  final CatalogApiService apiService;
  final bool canRestock;

  @override
  State<InventoryDetailSheet> createState() => _InventoryDetailSheetState();
}

class _InventoryDetailSheetState extends State<InventoryDetailSheet> {
  late Future<InventoryDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiService.fetchInventoryDetail(widget.inventoryItemId);
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

  Future<void> _openRestock(InventoryDetail detail) async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _RestockSheet(detail: detail, apiService: widget.apiService),
      ),
    );

    if (!mounted) {
      return;
    }

    if (success == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Restock registrado')));
      setState(() {
        _future = widget.apiService.fetchInventoryDetail(
          widget.inventoryItemId,
        );
      });
    }
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
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 300,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No se pudo cargar el detalle.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _future = widget.apiService.fetchInventoryDetail(
                            widget.inventoryItemId,
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
                height: 200,
                child: Center(child: Text('Sin detalle.')),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.code,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _row('Código', detail.code),
                  _row('Tipo', detail.tireType),
                  _row('Marca', detail.brand),
                  _row('Stock', '${detail.stock}'),
                  _row('Dueño', detail.owner?.name ?? '-'),
                  _row('Detalles', detail.details),
                  _row('Precio compra', detail.purchasePrice),
                  _row('Precio sugerido', detail.suggestedSalePrice),
                  _row('Último restock', _formatDate(detail.lastRestockAt)),
                  _row('Creado', _formatDate(detail.createdAt)),
                  _row('Actualizado', _formatDate(detail.updatedAt)),
                  if (widget.canRestock) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _openRestock(detail),
                        child: const Text('Restock'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RestockSheet extends StatefulWidget {
  const _RestockSheet({required this.detail, required this.apiService});

  final InventoryDetail detail;
  final CatalogApiService apiService;

  @override
  State<_RestockSheet> createState() => _RestockSheetState();
}

class _RestockSheetState extends State<_RestockSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _purchaseController = TextEditingController();
  final _suggestedController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _quantityController.dispose();
    _purchaseController.dispose();
    _suggestedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateQuantity(String? value) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null || parsed <= 0) {
      return 'Ingresa cantidad mayor a 0';
    }
    return null;
  }

  String? _validateDecimalRequired(String? value, String label) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed <= 0) {
      return 'Ingresa $label mayor a 0';
    }
    return null;
  }

  String? _validateDecimalOptional(String? value, String label) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      return 'Ingresa $label mayor a 0';
    }
    return null;
  }

  String _formatToTwoDecimals(String value) {
    final parsed = double.parse(value.trim());
    return parsed.toStringAsFixed(2);
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final request = RestockRequest(
        quantity: int.parse(_quantityController.text.trim()),
        unitPurchasePrice: _formatToTwoDecimals(_purchaseController.text),
        suggestedSalePrice: _suggestedController.text.trim().isEmpty
            ? null
            : _formatToTwoDecimals(_suggestedController.text),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await widget.apiService.restockInventoryItem(
        widget.detail.inventoryItemId,
        request,
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Restock',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text('Código: ${widget.detail.code}'),
                Text('Marca: ${widget.detail.brand}'),
                Text('Dueño: ${widget.detail.owner?.name ?? '-'}'),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Cantidad *'),
                  validator: _validateQuantity,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _purchaseController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Precio compra unitario *',
                  ),
                  validator: (value) =>
                      _validateDecimalRequired(value, 'precio compra'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _suggestedController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Precio sugerido',
                    hintText: 'Opcional (vacío = null)',
                  ),
                  validator: (value) =>
                      _validateDecimalOptional(value, 'precio sugerido'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    hintText: 'Opcional',
                  ),
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _submitError!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar restock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
