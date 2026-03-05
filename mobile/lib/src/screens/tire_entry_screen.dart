import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/brand_option.dart';
import '../models/catalog_choice_option.dart';
import '../models/catalog_choices.dart';
import '../services/catalog_api_service.dart';
import '../widgets/brand_autocomplete_field.dart';

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
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _suggestedPriceController = TextEditingController();
  final _modelController = TextEditingController();

  late final CatalogApiService _apiService;

  CatalogChoices? _choices;
  BrandOption? _selectedBrand;
  CatalogChoiceOption? _selectedTireType;
  CatalogChoiceOption? _selectedRimDiameter;
  CatalogChoiceOption? _selectedOrigin;
  CatalogChoiceOption? _selectedPlyRating;
  CatalogChoiceOption? _selectedTreadType;
  CatalogChoiceOption? _selectedLetterColor;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _apiService = CatalogApiService();
    _loadInitialData();
  }

  @override
  void dispose() {
    _brandController.dispose();
    _widthController.dispose();
    _profileController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _suggestedPriceController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final choices = await _apiService.fetchChoices();
      if (!mounted) {
        return;
      }
      setState(() {
        _choices = choices;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = 'No se pudieron cargar las opciones. ${error.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool get _showProfileField {
    final type = _selectedTireType?.value;
    return type == 'RADIAL' || type == 'MILLIMETRIC';
  }

  String? _requiredTextValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'El campo $fieldName es obligatorio';
    }
    return null;
  }

  String? _intValidator(String? value, String fieldName) {
    final requiredError = _requiredTextValidator(value, fieldName);
    if (requiredError != null) {
      return requiredError;
    }

    if (int.tryParse(value!.trim()) == null) {
      return 'Ingresa un número entero válido en $fieldName';
    }

    return null;
  }

  String? _decimalValidator(String? value, String fieldName, {bool required = true}) {
    if (!required && (value == null || value.trim().isEmpty)) {
      return null;
    }

    final requiredError = _requiredTextValidator(value, fieldName);
    if (requiredError != null) {
      return requiredError;
    }

    if (double.tryParse(value!.trim()) == null) {
      return 'Ingresa un número válido en $fieldName';
    }

    return null;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa los campos obligatorios.')),
      );
      return;
    }

    if (_selectedBrand == null ||
        _selectedTireType == null ||
        _selectedRimDiameter == null ||
        _selectedOrigin == null ||
        _selectedPlyRating == null ||
        _selectedTreadType == null ||
        _selectedLetterColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los selectores obligatorios.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _apiService.createStockReceipt(
        tireType: _selectedTireType!.value,
        brandId: _selectedBrand!.id,
        rimDiameter: _selectedRimDiameter!.value,
        origin: _selectedOrigin!.value,
        plyRating: _selectedPlyRating!.value,
        treadType: _selectedTreadType!.value,
        letterColor: _selectedLetterColor!.value,
        width: int.parse(_widthController.text.trim()),
        aspectRatio: _showProfileField
            ? int.parse(_profileController.text.trim())
            : null,
        quantity: int.parse(_quantityController.text.trim()),
        unitPurchasePrice: _priceController.text.trim(),
        recommendedSalePrice: _suggestedPriceController.text.trim().isEmpty
            ? null
            : _suggestedPriceController.text.trim(),
        model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      final receiptId = response['receipt_id'];
      final stockAfter = response['stock_after'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingreso registrado. Recibo #$receiptId | Stock: $stockAfter'),
        ),
      );

      _resetForm();
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error is ApiException
          ? error.message
          : 'No se pudo registrar el ingreso.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _brandController.clear();
    _widthController.clear();
    _profileController.clear();
    _quantityController.clear();
    _priceController.clear();
    _suggestedPriceController.clear();
    _modelController.clear();

    setState(() {
      _selectedBrand = null;
      _selectedTireType = null;
      _selectedRimDiameter = null;
      _selectedOrigin = null;
      _selectedPlyRating = null;
      _selectedTreadType = null;
      _selectedLetterColor = null;
    });
  }

  DropdownButtonFormField<CatalogChoiceOption> _buildChoiceField({
    required String label,
    required String fieldKey,
    required List<CatalogChoiceOption> items,
    required CatalogChoiceOption? value,
    required ValueChanged<CatalogChoiceOption?> onChanged,
  }) {
    return DropdownButtonFormField<CatalogChoiceOption>(
      value: value,
      decoration: InputDecoration(labelText: '$label *'),
      items: items
          .map(
            (option) => DropdownMenuItem<CatalogChoiceOption>(
              value: option,
              child: Text(_apiService.translateLabel(fieldKey, option)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (selected) {
        if (selected == null) {
          return 'Selecciona $label';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _loadError!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadInitialData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final choices = _choices;
    if (choices == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildChoiceField(
              label: 'Tipo de neumático',
              fieldKey: 'tire_type',
              items: choices.tireTypes,
              value: _selectedTireType,
              onChanged: (value) {
                setState(() {
                  _selectedTireType = value;
                  if (!_showProfileField) {
                    _profileController.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            BrandAutocompleteField(
              controller: _brandController,
              initialValue: _selectedBrand,
              searchBrands: _apiService.searchBrands,
              onSelected: (brand) {
                _selectedBrand = brand;
              },
            ),
            const SizedBox(height: 12),
            _buildChoiceField(
              label: 'Aro',
              fieldKey: 'rim_diameter',
              items: choices.rimDiameters,
              value: _selectedRimDiameter,
              onChanged: (value) {
                setState(() {
                  _selectedRimDiameter = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildChoiceField(
              label: 'Origen',
              fieldKey: 'origin',
              items: choices.origins,
              value: _selectedOrigin,
              onChanged: (value) {
                setState(() {
                  _selectedOrigin = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildChoiceField(
              label: 'PR',
              fieldKey: 'ply_rating',
              items: choices.plyRatings,
              value: _selectedPlyRating,
              onChanged: (value) {
                setState(() {
                  _selectedPlyRating = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildChoiceField(
              label: 'Diseño',
              fieldKey: 'tread_type',
              items: choices.treadTypes,
              value: _selectedTreadType,
              onChanged: (value) {
                setState(() {
                  _selectedTreadType = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildChoiceField(
              label: 'Color de letra',
              fieldKey: 'letter_color',
              items: choices.letterColors,
              value: _selectedLetterColor,
              onChanged: (value) {
                setState(() {
                  _selectedLetterColor = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _widthController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Ancho *'),
              validator: (value) => _intValidator(value, 'Ancho'),
            ),
            if (_showProfileField) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _profileController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Perfil *'),
                validator: (value) => _intValidator(value, 'Perfil'),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Cantidad *'),
              validator: (value) => _intValidator(value, 'Cantidad'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Precio de compra *'),
              validator: (value) => _decimalValidator(value, 'Precio de compra'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _suggestedPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Precio sugerido de venta',
                hintText: 'Opcional',
              ),
              validator: (value) =>
                  _decimalValidator(value, 'Precio sugerido de venta', required: false),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _modelController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Modelo',
                hintText: 'Opcional',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSubmitting ? 'Guardando...' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
