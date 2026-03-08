import 'package:flutter/material.dart';

import '../models/cart_models.dart';
import '../models/sale_models.dart';
import '../panels/add_manual_line_sheet.dart';
import '../panels/add_service_line_sheet.dart';
import '../panels/add_tradein_sheet.dart';
import '../panels/edit_line_sheet.dart';
import '../services/catalog_api_service.dart';
import '../store/cart_store.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, required this.cartStore});

  final CartStore cartStore;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _discountController = TextEditingController();
  final _saleNotesController = TextEditingController();
  final _apiService = CatalogApiService();

  bool _isSubmittingSale = false;

  @override
  void initState() {
    super.initState();
    _discountController.text = widget.cartStore.discountTotal.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _discountController.dispose();
    _saleNotesController.dispose();
    super.dispose();
  }

  String _money(double value) => value.toStringAsFixed(2);
  String _price(double value) => value.toStringAsFixed(2);

  SaleCreateRequest _buildSaleRequest() {
    final lines = <SaleLineRequest>[];

    for (final product in widget.cartStore.products) {
      lines.add(
        SaleLineRequest(
          lineType: product.itemType == CartProductType.tire ? 'INVENTORY_TIRE' : 'INVENTORY_RIM',
          inventoryItemId: product.inventoryItemId,
          quantity: product.quantity,
          unitPrice: _price(product.unitPrice),
          discount: '0.00',
        ),
      );
    }

    for (final manual in widget.cartStore.manualLines) {
      if (manual.type == ManualLineType.service) {
        final description = manual.detailNote == null || manual.detailNote!.trim().isEmpty
            ? manual.description
            : '${manual.description} - Nota: ${manual.detailNote!.trim()}';
        lines.add(
          SaleLineRequest(
            lineType: 'SERVICE',
            description: description,
            quantity: 1,
            unitPrice: _price(manual.amount),
          ),
        );
      } else {
        lines.add(
          SaleLineRequest(
            lineType: 'ACCESSORY',
            description: manual.description,
            quantity: 1,
            unitPrice: _price(manual.amount),
          ),
        );
      }
    }

    for (final tradeIn in widget.cartStore.tradeInLines) {
      lines.add(
        SaleLineRequest(
          lineType: tradeIn.type == TradeInType.tire ? 'TRADEIN_TIRE' : 'TRADEIN_RIM',
          description: tradeIn.summary +
              ((tradeIn.notes == null || tradeIn.notes!.trim().isEmpty)
                  ? ''
                  : ' - ${tradeIn.notes!.trim()}'),
          quantity: 1,
          assessedValue: _price(tradeIn.assessedValue),
          tireConditionPercent: tradeIn.type == TradeInType.tire ? tradeIn.conditionPercent : null,
          rimRequiresRepair: tradeIn.type == TradeInType.rim ? tradeIn.needsRepair : null,
        ),
      );
    }

    return SaleCreateRequest(
      discountTotal: _price(widget.cartStore.discountTotal),
      notes: _saleNotesController.text.trim().isEmpty ? null : _saleNotesController.text.trim(),
      lines: lines,
    );
  }

  Future<void> _showAddOptions() async {
    final option = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.miscellaneous_services_outlined),
              title: const Text('Servicio'),
              onTap: () => Navigator.of(context).pop('service'),
            ),
            ListTile(
              leading: const Icon(Icons.extension_outlined),
              title: const Text('Accesorio'),
              onTap: () => Navigator.of(context).pop('accessory'),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_outlined),
              title: const Text('Trade-in (parte de pago)'),
              onTap: () => Navigator.of(context).pop('tradein'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || option == null) {
      return;
    }

    if (option == 'service') {
      final result = await showModalBottomSheet<ServiceLineFormResult>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => AddServiceLineSheet(apiService: _apiService),
      );
      if (result == null) {
        return;
      }
      widget.cartStore.upsertManualLine(
        type: ManualLineType.service,
        description: result.serviceName,
        amount: result.amount,
        detailNote: result.detailNote,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Servicio agregado al carrito')),
        );
      }
      return;
    }

    if (option == 'accessory') {
      final result = await showModalBottomSheet<ManualLineFormResult>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const AddManualLineSheet(),
      );
      if (result == null) {
        return;
      }
      widget.cartStore.upsertManualLine(
        type: ManualLineType.accessory,
        description: result.description,
        amount: result.amount,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Accesorio agregado al carrito')),
        );
      }
      return;
    }

    final result = await showModalBottomSheet<TradeInFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const AddTradeInSheet(),
    );
    if (result == null) {
      return;
    }
    widget.cartStore.upsertTradeIn(
      type: result.type,
      assessedValue: result.assessedValue,
      notes: result.notes,
      conditionPercent: result.conditionPercent,
      needsRepair: result.needsRepair,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trade-in agregado')),
      );
    }
  }

  Future<void> _editProductLine(CartLineProduct line) async {
    final result = await showModalBottomSheet<EditProductLineResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => EditProductLineSheet(line: line),
    );
    if (result == null) {
      return;
    }
    widget.cartStore.updateProductLine(
      id: line.id,
      quantity: result.quantity,
      unitPrice: result.unitPrice,
    );
  }

  Future<void> _editManualLine(CartLineManual line) async {
    if (line.type == ManualLineType.service) {
      final result = await showModalBottomSheet<ServiceLineFormResult>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => AddServiceLineSheet(
          apiService: _apiService,
          initialLine: line,
        ),
      );
      if (result == null) {
        return;
      }
      widget.cartStore.upsertManualLine(
        id: line.id,
        type: ManualLineType.service,
        description: result.serviceName,
        amount: result.amount,
        detailNote: result.detailNote,
      );
      return;
    }

    final result = await showModalBottomSheet<ManualLineFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddManualLineSheet(
        initialLine: line,
      ),
    );
    if (result == null) {
      return;
    }
    widget.cartStore.upsertManualLine(
      id: line.id,
      type: ManualLineType.accessory,
      description: result.description,
      amount: result.amount,
      detailNote: null,
    );
  }

  Future<void> _editTradeInLine(TradeInLine line) async {
    final result = await showModalBottomSheet<TradeInFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddTradeInSheet(initialLine: line),
    );
    if (result == null) {
      return;
    }
    widget.cartStore.upsertTradeIn(
      id: line.id,
      type: result.type,
      assessedValue: result.assessedValue,
      notes: result.notes,
      conditionPercent: result.conditionPercent,
      needsRepair: result.needsRepair,
    );
  }

  Future<void> _finalizarVenta() async {
    if (!widget.cartStore.hasSaleLines) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto, servicio o accesorio.')),
      );
      return;
    }

    setState(() {
      _isSubmittingSale = true;
    });

    try {
      final response = await _apiService.createSale(_buildSaleRequest());
      if (!mounted) {
        return;
      }
      widget.cartStore.clear();
      _discountController.text = '0.00';
      _saleNotesController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Venta registrada: #${response.saleId}')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      String message = 'No se pudo registrar la venta.';
      if (error is ApiException) {
        if (error.statusCode == 409) {
          message = 'Stock insuficiente. ${error.message}';
        } else if (error.statusCode == 403) {
          message = 'No está permitido vender aros de ALDO';
        } else if (error.statusCode == 400) {
          message = error.message;
        } else {
          message = error.message;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingSale = false;
        });
      }
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.cartStore;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        actions: [
          IconButton(
            onPressed: _showAddOptions,
            icon: const Icon(Icons.add),
            tooltip: 'Agregar línea',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 130),
            children: [
              _sectionTitle('Productos'),
              if (store.products.isEmpty)
                const ListTile(title: Text('Sin productos en el carrito')),
              ...store.products.map(
                (line) => ListTile(
                  title: Text('${line.displayCode} | ${line.brand}'),
                  subtitle: Text(
                    'Owner: ${line.ownerName} | ${line.quantity} x ${_money(line.unitPrice)}',
                  ),
                  trailing: Text(_money(line.lineTotal)),
                  onTap: () => _editProductLine(line),
                  leading: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => store.removeProductLine(line.id),
                  ),
                ),
              ),
              _sectionTitle('Servicios y accesorios'),
              if (store.manualLines.isEmpty)
                const ListTile(title: Text('Sin servicios o accesorios')),
              ...store.manualLines.map(
                (line) => ListTile(
                  title: Text(line.description),
                  subtitle: Text(
                    line.type == ManualLineType.service
                        ? (line.detailNote == null || line.detailNote!.trim().isEmpty
                            ? 'Servicio'
                            : 'Servicio | ${line.detailNote}')
                        : 'Accesorio',
                  ),
                  trailing: Text(_money(line.amount)),
                  onTap: () => _editManualLine(line),
                  leading: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => store.removeManualLine(line.id),
                  ),
                ),
              ),
              _sectionTitle('Trade-in (parte de pago)'),
              if (store.tradeInLines.isEmpty)
                const ListTile(title: Text('Sin trade-in agregado')),
              ...store.tradeInLines.map(
                (line) => ListTile(
                  title: Text(line.summary),
                  subtitle: line.notes == null ? null : Text(line.notes!),
                  trailing: Text('-${_money(line.assessedValue)}'),
                  onTap: () => _editTradeInLine(line),
                  leading: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => store.removeTradeIn(line.id),
                  ),
                ),
              ),
              const Divider(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Descuento total'),
                  onChanged: (value) {
                    final parsed = double.tryParse(value.trim()) ?? 0;
                    store.setDiscount(parsed);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _saleNotesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas de venta',
                    hintText: 'Opcional',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Subtotal'),
                trailing: Text(_money(store.subtotal)),
              ),
              ListTile(
                title: const Text('Descuento total'),
                trailing: Text(_money(store.discountTotal)),
              ),
              ListTile(
                title: const Text('Total venta'),
                trailing: Text(_money(store.totalVenta)),
              ),
              ListTile(
                title: const Text('Crédito trade-in'),
                trailing: Text(_money(store.tradeInCredit)),
              ),
              ListTile(
                title: const Text('Total a pagar'),
                trailing: Text(
                  _money(store.totalPagar),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          onPressed: _isSubmittingSale ? null : _finalizarVenta,
          child: Text(_isSubmittingSale ? 'Registrando venta...' : 'Finalizar venta'),
        ),
      ),
    );
  }
}
