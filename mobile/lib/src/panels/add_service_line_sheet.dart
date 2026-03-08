import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/cart_models.dart';
import '../models/service_option.dart';
import '../services/catalog_api_service.dart';

class ServiceLineFormResult {
  const ServiceLineFormResult({
    required this.serviceName,
    required this.amount,
    this.detailNote,
  });

  final String serviceName;
  final double amount;
  final String? detailNote;
}

class AddServiceLineSheet extends StatefulWidget {
  const AddServiceLineSheet({
    super.key,
    required this.apiService,
    this.initialLine,
  });

  final CatalogApiService apiService;
  final CartLineManual? initialLine;

  @override
  State<AddServiceLineSheet> createState() => _AddServiceLineSheetState();
}

class _AddServiceLineSheetState extends State<AddServiceLineSheet> {
  final _formKey = GlobalKey<FormState>();
  final _fallbackNameController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();

  bool _loading = true;
  String? _loadError;
  List<ServiceOption> _services = const [];
  ServiceOption? _selected;

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.initialLine?.detailNote ?? '';
    _amountController.text =
        widget.initialLine != null ? widget.initialLine!.amount.toStringAsFixed(2) : '';
    _fallbackNameController.text = widget.initialLine?.description ?? '';
    _loadServices();
  }

  @override
  void dispose() {
    _fallbackNameController.dispose();
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final options = await widget.apiService.fetchServices();
      if (!mounted) {
        return;
      }
      ServiceOption? selected;
      if (widget.initialLine != null) {
        final match = options.where((option) => option.name == widget.initialLine!.description);
        selected = match.isNotEmpty ? match.first : null;
      }
      setState(() {
        _services = options;
        _selected = selected ?? (options.isNotEmpty ? options.first : null);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallbackMode = _loadError != null || _services.isEmpty;

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
                  widget.initialLine == null ? 'Agregar servicio' : 'Editar servicio',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  if (fallbackMode)
                    Text(
                      _loadError == null
                          ? 'No se encontraron servicios. Usa servicio personalizado.'
                          : 'No se pudo cargar catálogo de servicios. Usa servicio personalizado.',
                    ),
                  if (_loadError != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _loadServices,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ),
                  if (!fallbackMode)
                    DropdownButtonFormField<ServiceOption>(
                      value: _selected,
                      decoration: const InputDecoration(labelText: 'Servicio *'),
                      items: _services
                          .map(
                            (service) => DropdownMenuItem<ServiceOption>(
                              value: service,
                              child: Text(service.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _selected = value),
                      validator: (value) => value == null ? 'Selecciona un servicio' : null,
                    )
                  else
                    TextFormField(
                      controller: _fallbackNameController,
                      decoration: const InputDecoration(labelText: 'Servicio *'),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Ingresa un servicio';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notas/Detalle',
                      hintText: 'Opcional',
                    ),
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
                      final serviceName = fallbackMode
                          ? _fallbackNameController.text.trim()
                          : _selected?.name ?? '';
                      Navigator.of(context).pop(
                        ServiceLineFormResult(
                          serviceName: serviceName,
                          amount: double.parse(_amountController.text.trim()),
                          detailNote: _noteController.text.trim().isEmpty
                              ? null
                              : _noteController.text.trim(),
                        ),
                      );
                    },
                    child: Text(widget.initialLine == null ? 'Agregar servicio' : 'Guardar cambios'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

