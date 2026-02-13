class Tire {
  const Tire({
    required this.id,
    required this.brand,
    required this.logoAsset,
    required this.code,
    required this.stock,
    required this.description,
    required this.price,
  });

  final String id;
  final String brand;
  final String logoAsset;
  final String code;
  final int stock;
  final String description;
  final double price;
  double get suggestedSalePrice => price * 1.25;

  Tire copyWith({
    String? id,
    String? brand,
    String? logoAsset,
    String? code,
    int? stock,
    String? description,
    double? price,
  }) {
    return Tire(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      logoAsset: logoAsset ?? this.logoAsset,
      code: code ?? this.code,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      price: price ?? this.price,
    );
  }
}
