import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/tire.dart';

class SellTirePanel extends StatefulWidget {
  const SellTirePanel({super.key, required this.tire});

  final Tire tire;

  @override
  State<SellTirePanel> createState() => _SellTirePanelState();
}

class _SellTirePanelState extends State<SellTirePanel> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  late final TextEditingController _unitPriceController;
  final _discountController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _unitPriceController = TextEditingController(
      text: widget.tire.suggestedSalePrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  String? _validateQuantity(String? value) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null) {
      return 'Ingresa una cantidad válida';
    }
    if (parsed <= 0) {
      return 'La cantidad debe ser > 0';
    }
    return null;
  }

  String? _validateUnitPrice(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null) {
      return 'Ingresa un precio válido';
    }
    if (parsed <= 0) {
      return 'El precio unitario debe ser > 0';
    }
    return null;
  }

  String? _validateDiscount(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null) {
      return 'Ingresa un descuento válido';
    }
    if (parsed < 0) {
      return 'El descuento debe ser >= 0';
    }
    return null;
  }

  void _confirm() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Vender ${widget.tire.code}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Sugerido: ${widget.tire.suggestedSalePrice.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Cantidad a vender *'),
                validator: _validateQuantity,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: const InputDecoration(labelText: 'Precio unitario *'),
                validator: _validateUnitPrice,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: const InputDecoration(labelText: 'Descuento *'),
                validator: _validateDiscount,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _confirm,
                child: const Text('Confirmar venta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
