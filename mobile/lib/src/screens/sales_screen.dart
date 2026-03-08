import 'package:flutter/material.dart';

import '../models/sale_models.dart';
import '../panels/sale_detail_panel.dart';
import '../services/catalog_api_service.dart';
import '../widgets/sales_summary_panel.dart';

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
  SalesSummary? _summary;
  late DateTime _selectedStartDate;
  late DateTime _selectedEndDate;
  late DateTime _activeStartDate;
  late DateTime _activeEndDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _selectedEndDate = today;
    _selectedStartDate = today.subtract(const Duration(days: 29));
    _activeStartDate = _selectedStartDate;
    _activeEndDate = _selectedEndDate;
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
      final page = await _apiService.fetchSales(
        start: _activeStartDate,
        end: _activeEndDate,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _sales
          ..clear()
          ..addAll(page.results);
        _nextUrl = page.next;
        _summary = page.summary;
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

  String _formatDateOnly(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedStartDate = DateTime(picked.year, picked.month, picked.day);
      if (_selectedStartDate.isAfter(_selectedEndDate)) {
        _selectedEndDate = _selectedStartDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedEndDate = DateTime(picked.year, picked.month, picked.day);
      if (_selectedEndDate.isBefore(_selectedStartDate)) {
        _selectedStartDate = _selectedEndDate;
      }
    });
  }

  Future<void> _applyDateFilter() async {
    if (_selectedStartDate.isAfter(_selectedEndDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha "Desde" no puede ser mayor que "Hasta".'),
        ),
      );
      return;
    }
    setState(() {
      _activeStartDate = _selectedStartDate;
      _activeEndDate = _selectedEndDate;
    });
    await _loadInitial();
  }

  void _openDetail(SaleListItem sale) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SaleDetailPanel(saleId: sale.id, apiService: _apiService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickStartDate,
                              icon: const Icon(Icons.calendar_month_outlined),
                              label: Text(
                                'Desde: ${_formatDateOnly(_selectedStartDate)}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickEndDate,
                              icon: const Icon(Icons.event_outlined),
                              label: Text(
                                'Hasta: ${_formatDateOnly(_selectedEndDate)}',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: _loadingInitial ? null : _applyDateFilter,
                        child: const Text('Aplicar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SalesSummaryPanel(
                summary: _summary,
                onChangeDates: _pickStartDate,
              ),
            ),
          ),
          if (_loadingInitial)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
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
              ),
            )
          else if (_sales.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Text('No hay ventas registradas en el periodo.'),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: _sales.length,
              itemBuilder: (context, index) {
                final sale = _sales[index];
                final due = sale.totalDue.isNotEmpty ? sale.totalDue : sale.total;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    onTap: () => _openDetail(sale),
                    title: Text(
                      'Venta #${sale.id}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
          if (_loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}
