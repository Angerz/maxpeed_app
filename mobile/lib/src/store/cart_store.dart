import 'package:flutter/foundation.dart';

import '../models/cart_models.dart';

class CartStore extends ChangeNotifier {
  final List<CartLineProduct> _products = [];
  final List<CartLineManual> _manualLines = [];
  final List<TradeInLine> _tradeInLines = [];

  int _nextId = 1;
  double _discountTotal = 0;

  List<CartLineProduct> get products => List.unmodifiable(_products);
  List<CartLineManual> get manualLines => List.unmodifiable(_manualLines);
  List<TradeInLine> get tradeInLines => List.unmodifiable(_tradeInLines);

  int get badgeCount =>
      _products.length + _manualLines.length + _tradeInLines.length;

  double get subtotalProducts =>
      _products.fold(0, (sum, line) => sum + line.lineTotal);

  double get subtotalManual =>
      _manualLines.fold(0, (sum, line) => sum + line.amount);

  double get subtotal => subtotalProducts + subtotalManual;

  double get discountTotal => _discountTotal;

  double get totalVenta {
    final total = subtotal - _discountTotal;
    return total < 0 ? 0 : total;
  }

  double get tradeInCredit =>
      _tradeInLines.fold(0, (sum, line) => sum + line.assessedValue);

  double get totalPagar {
    final total = totalVenta - tradeInCredit;
    return total < 0 ? 0 : total;
  }

  bool get hasSaleLines => _products.isNotEmpty || _manualLines.isNotEmpty;

  void setDiscount(double value) {
    _discountTotal = value < 0 ? 0 : value;
    notifyListeners();
  }

  void addProduct({
    required int inventoryItemId,
    required CartProductType itemType,
    required String displayCode,
    required String brand,
    required String ownerName,
    required int quantity,
    required double unitPrice,
    required int availableStock,
  }) {
    _products.add(
      CartLineProduct(
        id: _nextId++,
        inventoryItemId: inventoryItemId,
        itemType: itemType,
        displayCode: displayCode,
        brand: brand,
        ownerName: ownerName,
        quantity: quantity,
        unitPrice: unitPrice,
        availableStock: availableStock,
      ),
    );
    notifyListeners();
  }

  void updateProductLine({
    required int id,
    required int quantity,
    required double unitPrice,
  }) {
    final index = _products.indexWhere((line) => line.id == id);
    if (index == -1) {
      return;
    }
    _products[index] = _products[index].copyWith(
      quantity: quantity,
      unitPrice: unitPrice,
    );
    notifyListeners();
  }

  void removeProductLine(int id) {
    _products.removeWhere((line) => line.id == id);
    notifyListeners();
  }

  void upsertManualLine({
    int? id,
    required ManualLineType type,
    required String description,
    required double amount,
    String? detailNote,
  }) {
    if (id == null) {
      _manualLines.add(
        CartLineManual(
          id: _nextId++,
          type: type,
          description: description,
          amount: amount,
          detailNote: detailNote,
        ),
      );
    } else {
      final index = _manualLines.indexWhere((line) => line.id == id);
      if (index != -1) {
        _manualLines[index] = _manualLines[index].copyWith(
          type: type,
          description: description,
          amount: amount,
          detailNote: detailNote,
        );
      }
    }
    notifyListeners();
  }

  void removeManualLine(int id) {
    _manualLines.removeWhere((line) => line.id == id);
    notifyListeners();
  }

  void upsertTradeIn({
    int? id,
    required TradeInType type,
    required int quantity,
    required double purchasePrice,
    required String specsSummary,
    String? notes,
    TradeInTireSpec? tireSpec,
    TradeInRimSpec? rimSpec,
    int? conditionPercent,
    bool? needsRepair,
  }) {
    if (id == null) {
      _tradeInLines.add(
        TradeInLine(
          id: _nextId++,
          type: type,
          quantity: quantity,
          purchasePrice: purchasePrice,
          specsSummary: specsSummary,
          notes: notes,
          tireSpec: tireSpec,
          rimSpec: rimSpec,
          conditionPercent: conditionPercent,
          needsRepair: needsRepair,
        ),
      );
    } else {
      final index = _tradeInLines.indexWhere((line) => line.id == id);
      if (index != -1) {
        _tradeInLines[index] = _tradeInLines[index].copyWith(
          type: type,
          quantity: quantity,
          purchasePrice: purchasePrice,
          specsSummary: specsSummary,
          notes: notes,
          tireSpec: tireSpec,
          rimSpec: rimSpec,
          conditionPercent: conditionPercent,
          needsRepair: needsRepair,
        );
      }
    }
    notifyListeners();
  }

  void removeTradeIn(int id) {
    _tradeInLines.removeWhere((line) => line.id == id);
    notifyListeners();
  }

  void clear() {
    _products.clear();
    _manualLines.clear();
    _tradeInLines.clear();
    _discountTotal = 0;
    notifyListeners();
  }
}
