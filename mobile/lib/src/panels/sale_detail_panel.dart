import 'package:flutter/material.dart';

import '../models/sale_transaction.dart';

class SaleDetailPanel extends StatelessWidget {
  const SaleDetailPanel({super.key, required this.sale});

  final SaleTransaction sale;

  String _dateLabel(DateTime dateTime) {
    final dd = dateTime.day.toString().padLeft(2, '0');
    final mm = dateTime.month.toString().padLeft(2, '0');
    final yyyy = dateTime.year.toString();
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final min = dateTime.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalle de venta',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            _Row(label: 'ID', value: sale.id),
            _Row(label: 'Marca', value: sale.brand),
            _Row(label: 'Código', value: sale.code),
            _Row(label: 'Fecha', value: _dateLabel(sale.dateTime)),
            _Row(label: 'Cantidad', value: '${sale.quantity}'),
            _Row(label: 'Precio unitario', value: sale.unitPrice.toStringAsFixed(2)),
            _Row(label: 'Subtotal', value: sale.subtotal.toStringAsFixed(2)),
            _Row(label: 'Descuento', value: sale.discount.toStringAsFixed(2)),
            _Row(label: 'Total', value: sale.total.toStringAsFixed(2)),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
