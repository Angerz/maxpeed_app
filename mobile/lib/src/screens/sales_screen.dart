import 'package:flutter/material.dart';

import '../models/sale_models.dart';
import '../panels/sale_detail_panel.dart';
import '../services/catalog_api_service.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _apiService = CatalogApiService();
  final _scrollController = ScrollController();

  final List<SaleListItem> _sales = [];
  bool _loadingInitial = true;
  bool _loadingMore = false;
  String? _error;
  String? _nextUrl;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loadingInitial = true;
      _error = null;
    });
    try {
      final page = await _apiService.fetchSales();
      if (!mounted) {
        return;
      }
      setState(() {
        _sales
          ..clear()
          ..addAll(page.results);
        _nextUrl = page.next;
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
          _loadingInitial = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _nextUrl == null) {
      return;
    }
    setState(() {
      _loadingMore = true;
    });
    try {
      final page = await _apiService.fetchSales(url: _nextUrl);
      if (!mounted) {
        return;
      }
      setState(() {
        _sales.addAll(page.results);
        _nextUrl = page.next;
      });
    } catch (_) {
      // silencioso; se puede reintentar al hacer scroll.
    } finally {
      if (mounted) {
        setState(() {
          _loadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final threshold = _scrollController.position.maxScrollExtent - 180;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

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

  void _openDetail(SaleListItem sale) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SaleDetailPanel(
        saleId: sale.id,
        apiService: _apiService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadInitial,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_sales.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadInitial,
        child: ListView(
          children: const [
            SizedBox(height: 140),
            Center(child: Text('No hay ventas registradas.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 18),
        itemCount: _sales.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _sales.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final sale = _sales[index];
          final due = sale.totalDue.isNotEmpty ? sale.totalDue : sale.total;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              onTap: () => _openDetail(sale),
              title: Text(
                'Venta #${sale.id}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(_formatDate(sale.soldAt)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total: $due'),
                  if (sale.tradeinCreditTotal.isNotEmpty)
                    Text('Trade-in: ${sale.tradeinCreditTotal}'),
                  if (sale.itemCount > 0) Text('Items: ${sale.itemCount}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

