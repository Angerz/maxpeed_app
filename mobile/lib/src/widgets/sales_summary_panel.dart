import 'package:flutter/material.dart';

import '../models/sale_models.dart';

class SalesSummaryPanel extends StatefulWidget {
  const SalesSummaryPanel({
    super.key,
    required this.summary,
    this.onChangeDates,
  });

  final SalesSummary? summary;
  final VoidCallback? onChangeDates;

  @override
  State<SalesSummaryPanel> createState() => _SalesSummaryPanelState();
}

class _SalesSummaryPanelState extends State<SalesSummaryPanel> {
  bool _expanded = false;

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw.isEmpty ? '-' : raw;
    }
    final local = parsed.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }

  String _money(String raw) {
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      return 'S/ ${raw.isEmpty ? '0.00' : raw}';
    }
    return 'S/ ${parsed.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = widget.summary;
    final start = summary == null ? '-' : _formatDate(summary.startDate);
    final end = summary == null ? '-' : _formatDate(summary.endDate);
    final total = summary == null ? 'S/ 0.00' : _money(summary.totalRevenue);

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen del periodo',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$total · $start - $end',
                            style: theme.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _SummaryDashboard(
                  summary: summary,
                  onChangeDates: widget.onChangeDates,
                  formatDate: _formatDate,
                  money: _money,
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryDashboard extends StatelessWidget {
  const _SummaryDashboard({
    required this.summary,
    required this.onChangeDates,
    required this.formatDate,
    required this.money,
  });

  final SalesSummary? summary;
  final VoidCallback? onChangeDates;
  final String Function(String) formatDate;
  final String Function(String) money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAnySales =
        summary != null && ((double.tryParse(summary!.totalRevenue) ?? 0) > 0);

    return Column(
      children: [
        if (!hasAnySales) ...[
          Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No hay ventas en este periodo',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajusta el rango de fechas para ver movimiento.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: onChangeDates,
                      child: const Text('Cambiar fechas'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        TotalRevenueCard(
          amount: summary == null ? 'S/ 0.00' : money(summary!.totalRevenue),
          periodLabel: summary == null
              ? '- - -'
              : '${formatDate(summary!.startDate)} - ${formatDate(summary!.endDate)}',
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final useRow = constraints.maxWidth >= 620;
            final bestDayCard = SummaryMetricCard(
              title: 'Mejor día',
              icon: Icons.trending_up,
              accent: theme.colorScheme.primary,
              date: summary?.bestDay == null
                  ? 'Sin ventas en el periodo'
                  : formatDate(summary!.bestDay!.date),
              amount: summary?.bestDay == null
                  ? '-'
                  : money(summary!.bestDay!.total),
              countLabel: summary?.bestDay == null
                  ? null
                  : '${summary!.bestDay!.salesCount} ventas',
            );

            final worstDayCard = SummaryMetricCard(
              title: 'Día más flojo',
              icon: Icons.trending_down,
              accent: theme.colorScheme.secondary,
              date: summary?.worstDay == null
                  ? 'Sin ventas en el periodo'
                  : formatDate(summary!.worstDay!.date),
              amount: summary?.worstDay == null
                  ? '-'
                  : money(summary!.worstDay!.total),
              countLabel: summary?.worstDay == null
                  ? null
                  : '${summary!.worstDay!.salesCount} ventas',
            );

            if (useRow) {
              return Row(
                children: [
                  Expanded(child: bestDayCard),
                  const SizedBox(width: 10),
                  Expanded(child: worstDayCard),
                ],
              );
            }
            return Column(
              children: [bestDayCard, const SizedBox(height: 10), worstDayCard],
            );
          },
        ),
      ],
    );
  }
}

class TotalRevenueCard extends StatelessWidget {
  const TotalRevenueCard({
    super.key,
    required this.amount,
    required this.periodLabel,
  });

  final String amount;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.attach_money, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ingresos totales', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    amount,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Periodo: $periodLabel',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryMetricCard extends StatelessWidget {
  const SummaryMetricCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.date,
    required this.amount,
    this.countLabel,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final String date;
  final String amount;
  final String? countLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(date, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              amount,
              textAlign: TextAlign.right,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (countLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                countLabel!,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
