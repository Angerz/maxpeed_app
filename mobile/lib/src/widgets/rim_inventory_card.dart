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

  String get _logoAsset {
    final normalized = item.brand.toLowerCase().replaceAll(' ', '_');
    return 'assets/brands/$normalized.png';
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
              Positioned.fill(
                child: Opacity(
                  opacity: 0.22,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: 0.85,
                      child: item.image != null && item.image!.hasUrl
                          ? Image.network(
                              item.image!.url,
                              fit: BoxFit.contain,
                              alignment: Alignment.centerRight,
                              errorBuilder: (context, error, stackTrace) =>
                                  _BrandPlaceholder(brand: item.brand),
                            )
                          : Image.asset(
                              _logoAsset,
                              fit: BoxFit.contain,
                              alignment: Alignment.centerRight,
                              errorBuilder: (context, error, stackTrace) =>
                                  _BrandPlaceholder(brand: item.brand),
                            ),
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
