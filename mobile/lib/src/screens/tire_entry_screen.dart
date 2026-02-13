import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/tire_type.dart';

class TireEntryScreen extends StatefulWidget {
  const TireEntryScreen({super.key});

  @override
  State<TireEntryScreen> createState() => _TireEntryScreenState();
}

class _TireEntryScreenState extends State<TireEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _widthController = TextEditingController();
  final _profileController = TextEditingController();
  final _rimController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  TireType? _selectedType;

  @override
  void dispose() {
    _brandController.dispose();
    _widthController.dispose();
    _profileController.dispose();
    _rimController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'El campo $fieldName es obligatorio';
    }
    return null;
  }

  String? _numericValidator(String? value, String fieldName) {
    final requiredError = _requiredValidator(value, fieldName);
    if (requiredError != null) {
      return requiredError;
    }

    if (num.tryParse(value!.trim()) == null) {
      return 'Ingresa un valor numérico válido en $fieldName';
    }

    return null;
  }

  bool get _showProfileField => _selectedType?.requiresProfile ?? false;

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa los campos obligatorios.')),
      );
      return;
    }

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el tipo de neumático.')),
      );
      return;
    }

    final width = _widthController.text.trim();
    final profile = _profileController.text.trim();
    final rim = _rimController.text.trim();
    final qty = _quantityController.text.trim();
    final price = _priceController.text.trim();

    final code = _showProfileField ? '${width}/${profile}R$rim' : '${width}R$rim';

    final summary = 'Guardado (simulado): ${_brandController.text.trim()} $code | '
        'Cantidad: $qty | Precio: $price';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(summary)));

    _formKey.currentState?.reset();
    _brandController.clear();
    _widthController.clear();
    _profileController.clear();
    _rimController.clear();
    _quantityController.clear();
    _priceController.clear();
    _descriptionController.clear();

    setState(() {
      _selectedType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<TireType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo de neumático *',
              ),
              items: TireType.values
                  .map(
                    (type) => DropdownMenuItem<TireType>(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (type) {
                setState(() {
                  _selectedType = type;
                  if (!(_selectedType?.requiresProfile ?? false)) {
                    _profileController.clear();
                  }
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Selecciona un tipo de neumático';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brandController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Marca *',
                hintText: 'Ej: Goodyear',
              ),
              validator: (value) => _requiredValidator(value, 'Marca'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _widthController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Ancho *'),
              validator: (value) => _numericValidator(value, 'Ancho'),
            ),
            if (_showProfileField) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _profileController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Perfil *'),
                validator: (value) => _numericValidator(value, 'Perfil'),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _rimController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Aro *'),
              validator: (value) => _numericValidator(value, 'Aro'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Cantidad *'),
              validator: (value) => _numericValidator(value, 'Cantidad'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Precio *'),
              validator: (value) => _numericValidator(value, 'Precio'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              textInputAction: TextInputAction.done,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ej: 8PR, MT, TAILANDESA',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
