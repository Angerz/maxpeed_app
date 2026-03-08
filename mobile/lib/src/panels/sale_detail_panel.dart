import 'package:flutter/material.dart';

import '../models/sale_models.dart';
import '../services/catalog_api_service.dart';

class SaleDetailPanel extends StatefulWidget {
  const SaleDetailPanel({
    super.key,
    required this.saleId,
    required this.apiService,
  });

  final int saleId;
  final CatalogApiService apiService;

  @override
  State<SaleDetailPanel> createState() => _SaleDetailPanelState();
}

class _SaleDetailPanelState extends State<SaleDetailPanel> {
  bool _loading = true;
  String? _error;
  SaleDetail? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _asMoney(String value) => value.isEmpty ? '-' : value;

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw.isEmpty ? '-' : raw;
    }
    final local = parsed.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await widget.apiService.fetchSaleDetail(widget.saleId);
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
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
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final detail = _detail;
    if (detail == null) {
      return const SafeArea(child: SizedBox.shrink());
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Venta #${detail.id}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Fecha: ${_formatDate(detail.soldAt)}'),
                    if (detail.notes.isNotEmpty) Text('Notas: ${detail.notes}'),
                    const Divider(height: 24),
                    Text('Subtotal: ${_asMoney(detail.subtotal)}'),
                    Text('Descuento: ${_asMoney(detail.discountTotal)}'),
                    Text(
                      'Crédito trade-in: ${_asMoney(detail.tradeinCreditTotal)}',
                    ),
                    Text('Total: ${_asMoney(detail.total)}'),
                    Text(
                      'Total a pagar: ${_asMoney(detail.totalDue)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Divider(height: 24),
                    Text(
                      'Líneas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index.isOdd) {
                      return const SizedBox(height: 8);
                    }
                    final line = detail.lines[index ~/ 2];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.description.isEmpty
                                        ? '-'
                                        : line.description,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${line.lineType} | Cant: ${line.quantity}',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (line.unitPrice.isNotEmpty)
                                  Text('P/U: ${line.unitPrice}'),
                                if (line.assessedValue.isNotEmpty)
                                  Text('Tasado: ${line.assessedValue}'),
                                Text(
                                  line.lineTotal.isEmpty ? '-' : line.lineTotal,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: detail.lines.isEmpty
                      ? 0
                      : (detail.lines.length * 2) - 1,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}
