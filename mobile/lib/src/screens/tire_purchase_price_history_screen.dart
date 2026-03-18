import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/purchase_price_history.dart';
import '../services/catalog_api_service.dart';

class TirePurchasePriceHistoryScreen extends StatefulWidget {
  const TirePurchasePriceHistoryScreen({
    super.key,
    required this.inventoryItemId,
    required this.apiService,
  });

  final int inventoryItemId;
  final CatalogApiService apiService;

  @override
  State<TirePurchasePriceHistoryScreen> createState() =>
      _TirePurchasePriceHistoryScreenState();
}

class _TirePurchasePriceHistoryScreenState
    extends State<TirePurchasePriceHistoryScreen> {
  late Future<PurchasePriceHistoryResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiService.fetchPurchasePriceHistory(
      widget.inventoryItemId,
    );
  }

  String _money(double value) => 'S/ ${value.toStringAsFixed(2)}';

  String _formatDate(DateTime? date, String raw) {
    if (date == null) {
      final parsed = DateTime.tryParse(raw)?.toLocal();
      if (parsed == null) {
        return raw.isEmpty ? '-' : raw;
      }
      date = parsed;
    }
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  Widget _buildEmpty() {
    return const Center(child: Text('No hay historial de precios disponible'));
  }

  Widget _buildError(Object? error) {
    final message = error is ApiException && error.statusCode == 403
        ? 'No autorizado'
        : 'No se pudo cargar historial de precios.\n$error';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                setState(() {
                  _future = widget.apiService.fetchPurchasePriceHistory(
                    widget.inventoryItemId,
                  );
                });
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(PurchasePriceHistoryResponse data) {
    if (data.points.isEmpty) {
      return _buildEmpty();
    }

    final spots = <FlSpot>[];
    double minY = data.points.first.amount;
    double maxY = data.points.first.amount;
    for (var i = 0; i < data.points.length; i++) {
      final amount = data.points[i].amount;
      spots.add(FlSpot(i.toDouble(), amount));
      if (amount < minY) {
        minY = amount;
      }
      if (amount > maxY) {
        maxY = amount;
      }
    }
    final yPadding = (maxY - minY).abs() < 1 ? 1.0 : (maxY - minY) * 0.2;
    final bottomTitles = data.points;

    return LineChart(
      LineChartData(
        minY: minY - yPadding,
        maxY: maxY + yPadding,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 10,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index < 0 || index >= data.points.length) {
                  return null;
                }
                final point = data.points[index];
                final date = _formatDate(point.date, point.rawDate);
                return LineTooltipItem(
                  '$date\n${_money(point.amount)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
            barWidth: 3,
          ),
        ],
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 54,
              getTitlesWidget: (value, meta) {
                return Text(
                  'S/${value.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= bottomTitles.length) {
                  return const SizedBox.shrink();
                }
                final point = bottomTitles[index];
                return SideTitleWidget(
                  meta: meta,
                  angle: -0.45,
                  child: Text(
                    _formatDate(point.date, point.rawDate),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats(PurchasePriceStats stats) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mínimo: ${_money(stats.min)}', style: textTheme.bodyLarge),
        const SizedBox(height: 2),
        Text('Máximo: ${_money(stats.max)}', style: textTheme.bodyLarge),
        const SizedBox(height: 2),
        Text('Promedio: ${_money(stats.avg)}', style: textTheme.bodyLarge),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de precios')),
      body: SafeArea(
        child: FutureBuilder<PurchasePriceHistoryResponse>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _buildError(snapshot.error);
            }
            final data = snapshot.data;
            if (data == null) {
              return _buildEmpty();
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.code} · ${data.brand}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Actual: ${_money(data.currentPurchasePrice)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (data.stats != null) ...[
                    const SizedBox(height: 10),
                    _buildStats(data.stats!),
                  ],
                  const SizedBox(height: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: _buildChart(data),
                    ),
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
