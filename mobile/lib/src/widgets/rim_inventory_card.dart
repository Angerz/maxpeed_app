import 'package:flutter/material.dart';

import '../models/rim_inventory_card_item.dart';

class RimInventoryCard extends StatelessWidget {
  const RimInventoryCard({
    super.key,
    required this.item,
    this.onTap,
    this.onAdd,
  });

  final RimInventoryCardItem item;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  String get _thumbUrl {
    final thumb = item.imageThumb?.url.trim() ?? '';
    if (thumb.isNotEmpty) {
      return thumb;
    }
    return item.image?.url.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              if (item.conditionLabel != null && item.conditionLabel!.isNotEmpty)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _ConditionBadge(label: item.conditionLabel!),
                ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.22,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: 0.85,
                      child: _thumbUrl.isNotEmpty
                          ? Image.network(
                              _thumbUrl,
                              fit: BoxFit.contain,
                              alignment: Alignment.centerRight,
                              cacheWidth: 600,
                              errorBuilder: (context, error, stackTrace) =>
                                  _BrandPlaceholder(brand: item.brand),
                            )
                          : _BrandPlaceholder(brand: item.brand),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.internalCode,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.brand,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.stock}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(item.details, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      item.owner?.name ?? '-',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (onAdd != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add_shopping_cart_outlined),
                          label: const Text('Agregar'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConditionBadge extends StatelessWidget {
  const _ConditionBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB74D),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFF3E2723),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _BrandPlaceholder extends StatelessWidget {
  const _BrandPlaceholder({required this.brand});

  final String brand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.album_outlined,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            brand,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
