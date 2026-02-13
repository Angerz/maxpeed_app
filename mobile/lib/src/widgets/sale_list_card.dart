import 'package:flutter/material.dart';

import '../models/sale_transaction.dart';

class SaleListCard extends StatelessWidget {
  const SaleListCard({
    super.key,
    required this.sale,
    this.onTap,
  });

  final SaleTransaction sale;
  final VoidCallback? onTap;

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
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(
          '${sale.brand} • ${sale.code}',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(_dateLabel(sale.dateTime)),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Cant: ${sale.quantity}'),
            const SizedBox(height: 2),
            Text(
              'Total: ${sale.total.toStringAsFixed(2)}',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
