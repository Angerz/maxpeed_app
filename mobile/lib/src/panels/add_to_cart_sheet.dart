import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddToCartResult {
  const AddToCartResult({
    required this.quantity,
    required this.unitPrice,
  });

  final int quantity;
  final double unitPrice;
}

class AddToCartSheet extends StatefulWidget {
  const AddToCartSheet({
    super.key,
    required this.title,
    required this.stock,
    this.suggestedPrice,
  });

  final String title;
  final int stock;
  final double? suggestedPrice;

  @override
  State<AddToCartSheet> createState() => _AddToCartSheetState();
}

class _AddToCartSheetState extends State<AddToCartSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    _priceController = TextEditingController(
      text: widget.suggestedPrice != null ? widget.suggestedPrice!.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  int get _quantity => int.tryParse(_quantityController.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final overStock = _quantity > widget.stock;

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
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Stock actual: ${widget.stock}'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Cantidad *'),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa una cantidad > 0';
                  }
                  return null;
                },
              ),
              if (overStock)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Advertencia: la cantidad supera el stock disponible.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: InputDecoration(
                  labelText: 'Precio unitario *',
                  hintText: widget.suggestedPrice != null
                      ? 'Precio sugerido: ${widget.suggestedPrice!.toStringAsFixed(2)}'
                      : 'Ingresa precio',
                ),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa un precio > 0';
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
                  final result = AddToCartResult(
                    quantity: int.parse(_quantityController.text.trim()),
                    unitPrice: double.parse(_priceController.text.trim()),
                  );
                  Navigator.of(context).pop(result);
                },
                child: const Text('Agregar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

