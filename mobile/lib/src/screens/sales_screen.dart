import 'package:flutter/material.dart';

import '../models/sale_transaction.dart';
import '../panels/sale_detail_panel.dart';
import '../widgets/sale_list_card.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key, required this.sales});

  final List<SaleTransaction> sales;

  void _openDetail(BuildContext context, SaleTransaction sale) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SaleDetailPanel(sale: sale),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return const Center(child: Text('No hay ventas mock disponibles.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 18),
      itemCount: sales.length,
      itemBuilder: (context, index) {
        final sale = sales[index];
        return SaleListCard(
          sale: sale,
          onTap: () => _openDetail(context, sale),
        );
      },
    );
  }
}
