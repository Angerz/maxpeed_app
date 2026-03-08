import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/cart_models.dart';

class TradeInFormResult {
  const TradeInFormResult({
    required this.type,
    required this.assessedValue,
    required this.notes,
    this.conditionPercent,
    this.needsRepair,
  });

  final TradeInType type;
  final double assessedValue;
  final String? notes;
  final int? conditionPercent;
  final bool? needsRepair;
}

class AddTradeInSheet extends StatefulWidget {
  const AddTradeInSheet({super.key, this.initialLine});

  final TradeInLine? initialLine;

  @override
  State<AddTradeInSheet> createState() => _AddTradeInSheetState();
}

class _AddTradeInSheetState extends State<AddTradeInSheet> {
  final _formKey = GlobalKey<FormState>();
  late TradeInType _type;
  int _conditionPercent = 70;
  bool _needsRepair = false;
  late final TextEditingController _assessedValueController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _type = widget.initialLine?.type ?? TradeInType.tire;
    _conditionPercent = widget.initialLine?.conditionPercent ?? 70;
    _needsRepair = widget.initialLine?.needsRepair ?? false;
    _assessedValueController = TextEditingController(
      text: widget.initialLine != null
          ? widget.initialLine!.assessedValue.toStringAsFixed(2)
          : '',
    );
    _notesController = TextEditingController(
      text: widget.initialLine?.notes ?? '',
    );
  }

  @override
  void dispose() {
    _assessedValueController.dispose();
    _notesController.dispose();
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.initialLine == null
                      ? 'Agregar Trade-in (parte de pago)'
                      : 'Editar Trade-in',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SegmentedButton<TradeInType>(
                  segments: const [
                    ButtonSegment(
                      value: TradeInType.tire,
                      label: Text('Llanta'),
                    ),
                    ButtonSegment(value: TradeInType.rim, label: Text('Aro')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _type = selection.first;
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (_type == TradeInType.tire) ...[
                  Text(
                    'Estado: $_conditionPercent%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    min: 10,
                    max: 100,
                    divisions: 9,
                    value: _conditionPercent.toDouble(),
                    label: '$_conditionPercent%',
                    onChanged: (value) {
                      final snapped = ((value / 10).round() * 10).clamp(
                        10,
                        100,
                      );
                      setState(() {
                        _conditionPercent = snapped;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                if (_type == TradeInType.rim) ...[
                  CheckboxListTile(
                    value: _needsRepair,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Requiere reparación'),
                    onChanged: (value) {
                      setState(() {
                        _needsRepair = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                TextFormField(
                  controller: _assessedValueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Valor tasado *',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse((value ?? '').trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Ingresa valor tasado > 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    hintText: 'Opcional',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    Navigator.of(context).pop(
                      TradeInFormResult(
                        type: _type,
                        assessedValue: double.parse(
                          _assessedValueController.text.trim(),
                        ),
                        notes: _notesController.text.trim().isEmpty
                            ? null
                            : _notesController.text.trim(),
                        conditionPercent: _type == TradeInType.tire
                            ? _conditionPercent
                            : null,
                        needsRepair: _type == TradeInType.rim
                            ? _needsRepair
                            : null,
                      ),
                    );
                  },
                  child: Text(
                    widget.initialLine == null
                        ? 'Agregar Trade-in'
                        : 'Guardar cambios',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
