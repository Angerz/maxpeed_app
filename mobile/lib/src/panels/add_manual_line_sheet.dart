import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/cart_models.dart';

class ManualLineFormResult {
  const ManualLineFormResult({
    required this.description,
    required this.amount,
  });

  final String description;
  final double amount;
}

class AddManualLineSheet extends StatefulWidget {
  const AddManualLineSheet({
    super.key,
    this.initialLine,
  });

  final CartLineManual? initialLine;

  @override
  State<AddManualLineSheet> createState() => _AddManualLineSheetState();
}

class _AddManualLineSheetState extends State<AddManualLineSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.initialLine?.description ?? '');
    _amountController = TextEditingController(
      text: widget.initialLine != null ? widget.initialLine!.amount.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
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
              Text(
                widget.initialLine == null ? 'Agregar línea' : 'Editar línea',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción *'),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'La descripción es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: const InputDecoration(labelText: 'Monto *'),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa monto > 0';
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
                    ManualLineFormResult(
                      description: _descriptionController.text.trim(),
                      amount: double.parse(_amountController.text.trim()),
                    ),
                  );
                },
                child: Text(widget.initialLine == null ? 'Agregar' : 'Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
