import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/cart_models.dart';

class EditProductLineResult {
  const EditProductLineResult({
    required this.quantity,
    required this.unitPrice,
  });

  final int quantity;
  final double unitPrice;
}

class EditProductLineSheet extends StatefulWidget {
  const EditProductLineSheet({super.key, required this.line});

  final CartLineProduct line;

  @override
  State<EditProductLineSheet> createState() => _EditProductLineSheetState();
}

class _EditProductLineSheetState extends State<EditProductLineSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '${widget.line.quantity}');
    _priceController = TextEditingController(text: widget.line.unitPrice.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Editar línea', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('${widget.line.displayCode} | ${widget.line.brand}'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Cantidad *'),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa cantidad > 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: const InputDecoration(labelText: 'Precio unitario *'),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa precio > 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  Navigator.of(context).pop(
                    EditProductLineResult(
                      quantity: int.parse(_quantityController.text.trim()),
                      unitPrice: double.parse(_priceController.text.trim()),
                    ),
                  );
                },
                child: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

