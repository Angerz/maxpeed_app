class SaleTransaction {
  const SaleTransaction({
    required this.id,
    required this.brand,
    required this.logoAsset,
    required this.code,
    required this.dateTime,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
  });

  final String id;
  final String brand;
  final String logoAsset;
  final String code;
  final DateTime dateTime;
  final int quantity;
  final double unitPrice;
  final double discount;

  double get subtotal => quantity * unitPrice;

  double get total => subtotal - discount;
}
