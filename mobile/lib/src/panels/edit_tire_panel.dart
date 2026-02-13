import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/tire.dart';

class EditTirePanel extends StatefulWidget {
  const EditTirePanel({super.key, required this.tire});

  final Tire tire;

  @override
  State<EditTirePanel> createState() => _EditTirePanelState();
}

class _EditTirePanelState extends State<EditTirePanel> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _purchasePriceController;

  @override
  void initState() {
    super.initState();
    _brandController = TextEditingController(text: widget.tire.brand);
    _descriptionController = TextEditingController(text: widget.tire.description);
    _purchasePriceController = TextEditingController(text: widget.tire.price.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _brandController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    super.dispose();
  }

  String? _validateBrand(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Marca obligatoria';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Precio de compra obligatorio';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Ingresa un número válido';
    }
    if (parsed < 0) {
      return 'El precio debe ser >= 0';
    }
    return null;
  }

  void _save() {
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
              const Text(
                'Editar neumático',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Marca *'),
                validator: _validateBrand,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _purchasePriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: const InputDecoration(labelText: 'Precio de compra *'),
                validator: _validatePrice,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _save,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
