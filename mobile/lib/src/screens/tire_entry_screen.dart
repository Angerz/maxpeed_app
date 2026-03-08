import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/brand_option.dart';
import '../models/catalog_choice_option.dart';
import '../models/catalog_choices.dart';
import '../models/owner.dart';
import '../models/rim_receipt_request.dart';
import '../services/catalog_api_service.dart';
import '../services/rim_photo_storage.dart';
import '../widgets/brand_autocomplete_field.dart';

enum EntryMode { tire, rim }

class TireEntryScreen extends StatefulWidget {
  const TireEntryScreen({super.key});

  @override
  State<TireEntryScreen> createState() => _TireEntryScreenState();
}

class _TireEntryScreenState extends State<TireEntryScreen> {
  late final CatalogApiService _apiService;
  CatalogChoices? _choices;
  bool _isLoading = true;
  String? _loadError;
  EntryMode _mode = EntryMode.tire;

  @override
  void initState() {
    super.initState();
    _apiService = CatalogApiService();
    _loadInitialData();
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
              Text(_loadError!, textAlign: TextAlign.center),
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: SegmentedButton<EntryMode>(
            segments: const [
              ButtonSegment(value: EntryMode.tire, label: Text('LLANTA')),
              ButtonSegment(value: EntryMode.rim, label: Text('ARO')),
            ],
            selected: {_mode},
            onSelectionChanged: (next) {
              setState(() {
                _mode = next.first;
              });
            },
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _mode == EntryMode.tire ? 0 : 1,
            children: [
              _TireEntryForm(choices: choices, apiService: _apiService),
              _RimEntryForm(choices: choices, apiService: _apiService),
            ],
          ),
        ),
      ],
    );
  }
}

class _TireEntryForm extends StatefulWidget {
  const _TireEntryForm({required this.choices, required this.apiService});

  final CatalogChoices choices;
  final CatalogApiService apiService;

  @override
  State<_TireEntryForm> createState() => _TireEntryFormState();
}

class _TireEntryFormState extends State<_TireEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _widthController = TextEditingController();
  final _profileController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _suggestedPriceController = TextEditingController();
  final _modelController = TextEditingController();

  BrandOption? _selectedBrand;
  Owner? _selectedOwner;
  CatalogChoiceOption? _selectedTireType;
  CatalogChoiceOption? _selectedRimDiameter;
  CatalogChoiceOption? _selectedOrigin;
  CatalogChoiceOption? _selectedPlyRating;
  CatalogChoiceOption? _selectedTreadType;
  CatalogChoiceOption? _selectedLetterColor;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedOwner = widget.choices.owners.isNotEmpty
        ? widget.choices.owners.first
        : null;
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

  String? _decimalValidator(
    String? value,
    String fieldName, {
    bool required = true,
  }) {
    if (!required && (value == null || value.trim().isEmpty)) {
      return null;
    }

    final requiredError = _requiredTextValidator(value, fieldName);
    if (requiredError != null) {
      return requiredError;
    }

    final parsed = double.tryParse(value!.trim());
    if (parsed == null || parsed <= 0) {
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
        _selectedOwner == null ||
        _selectedTireType == null ||
        _selectedRimDiameter == null ||
        _selectedOrigin == null ||
        _selectedPlyRating == null ||
        _selectedTreadType == null ||
        _selectedLetterColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los selectores obligatorios.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await widget.apiService.postStockReceipt(
        tireType: _selectedTireType!.value,
        brandId: _selectedBrand!.id,
        ownerId: _selectedOwner!.id,
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
        unitPurchasePrice: double.parse(
          _priceController.text.trim(),
        ).toStringAsFixed(2),
        recommendedSalePrice: _suggestedPriceController.text.trim().isEmpty
            ? null
            : double.parse(
                _suggestedPriceController.text.trim(),
              ).toStringAsFixed(2),
        model: _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      final receiptId = response['receipt_id'];
      final stockAfter = response['stock_after'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ingreso de llanta registrado. Recibo #$receiptId | Stock: $stockAfter',
          ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
      _selectedOwner = widget.choices.owners.isNotEmpty
          ? widget.choices.owners.first
          : null;
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
              child: Text(widget.apiService.translateLabel(fieldKey, option)),
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
    final choices = widget.choices;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Owner>(
              value: _selectedOwner,
              decoration: const InputDecoration(labelText: 'Dueño *'),
              items: choices.owners
                  .map(
                    (owner) => DropdownMenuItem<Owner>(
                      value: owner,
                      child: Text(owner.name),
                    ),
                  )
                  .toList(),
              onChanged: (owner) => setState(() => _selectedOwner = owner),
              validator: (value) => value == null ? 'Selecciona Dueño' : null,
            ),
            const SizedBox(height: 12),
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
            _buildChoiceField(
              label: 'Aro',
              fieldKey: 'rim_diameter',
              items: choices.rimDiameters,
              value: _selectedRimDiameter,
              onChanged: (value) =>
                  setState(() => _selectedRimDiameter = value),
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
            BrandAutocompleteField(
              controller: _brandController,
              initialValue: _selectedBrand,
              searchBrands: widget.apiService.searchBrands,
              onSelected: (brand) {
                _selectedBrand = brand;
              },
            ),
            const SizedBox(height: 12),
            _buildChoiceField(
              label: 'Origen',
              fieldKey: 'origin',
              items: choices.origins,
              value: _selectedOrigin,
              onChanged: (value) => setState(() => _selectedOrigin = value),
            ),
            const SizedBox(height: 12),
            _buildChoiceField(
              label: 'PR',
              fieldKey: 'ply_rating',
              items: choices.plyRatings,
              value: _selectedPlyRating,
              onChanged: (value) => setState(() => _selectedPlyRating = value),
            ),
            const SizedBox(height: 12),
            _buildChoiceField(
              label: 'Diseño',
              fieldKey: 'tread_type',
              items: choices.treadTypes,
              value: _selectedTreadType,
              onChanged: (value) => setState(() => _selectedTreadType = value),
            ),
            const SizedBox(height: 12),
            _buildChoiceField(
              label: 'Color de letra',
              fieldKey: 'letter_color',
              items: choices.letterColors,
              value: _selectedLetterColor,
              onChanged: (value) =>
                  setState(() => _selectedLetterColor = value),
            ),
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Precio de compra *',
              ),
              validator: (value) =>
                  _decimalValidator(value, 'Precio de compra'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _suggestedPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Precio sugerido de venta',
                hintText: 'Opcional',
              ),
              validator: (value) => _decimalValidator(
                value,
                'Precio sugerido de venta',
                required: false,
              ),
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
              label: Text(_isSubmitting ? 'Guardando...' : 'Guardar LLANTA'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RimEntryForm extends StatefulWidget {
  const _RimEntryForm({required this.choices, required this.apiService});

  final CatalogChoices choices;
  final CatalogApiService apiService;

  @override
  State<_RimEntryForm> createState() => _RimEntryFormState();
}

class _RimEntryFormState extends State<_RimEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  final _photoStorage = createRimPhotoStorage();
  final _internalCodeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _suggestedPriceController = TextEditingController();
  final _notesController = TextEditingController();

  List<BrandOption> _rimBrands = const [];
  Owner? _selectedOwner;
  BrandOption? _selectedBrand;
  CatalogChoiceOption? _selectedDiameter;
  CatalogChoiceOption? _selectedHoles;
  CatalogChoiceOption? _selectedWidth;
  CatalogChoiceOption? _selectedMaterial;

  bool _isSet = false;
  bool _isLoadingBrands = true;
  String? _brandsError;
  bool _isSubmitting = false;
  XFile? _selectedPhoto;
  Uint8List? _selectedPhotoBytes;

  @override
  void initState() {
    super.initState();
    _selectedOwner = widget.choices.owners.isNotEmpty
        ? widget.choices.owners.first
        : null;
    _loadRimBrands();
  }

  @override
  void dispose() {
    _internalCodeController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _suggestedPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadRimBrands() async {
    setState(() {
      _isLoadingBrands = true;
      _brandsError = null;
    });

    try {
      final brands = await widget.apiService.fetchRimBrands();
      if (!mounted) {
        return;
      }
      setState(() {
        _rimBrands = brands;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _brandsError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBrands = false;
        });
      }
    }
  }

  String? _requiredTextValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'El campo $fieldName es obligatorio';
    }
    return null;
  }

  String? _positiveIntValidator(
    String? value,
    String fieldName, {
    bool required = true,
  }) {
    if (!required && (value == null || value.trim().isEmpty)) {
      return null;
    }
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null || parsed <= 0) {
      return 'Ingresa $fieldName > 0';
    }
    return null;
  }

  String? _positiveDecimalValidator(
    String? value,
    String fieldName, {
    bool required = true,
  }) {
    if (!required && (value == null || value.trim().isEmpty)) {
      return null;
    }
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed <= 0) {
      return 'Ingresa $fieldName > 0';
    }
    return null;
  }

  String _toPrice(String raw) => double.parse(raw.trim()).toStringAsFixed(2);

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa los campos obligatorios.')),
      );
      return;
    }

    if (_selectedOwner == null ||
        _selectedBrand == null ||
        _selectedDiameter == null ||
        _selectedHoles == null ||
        _selectedWidth == null ||
        _selectedMaterial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los selectores obligatorios.'),
        ),
      );
      return;
    }

    final quantity = _isSet ? 1 : int.parse(_quantityController.text.trim());

    setState(() {
      _isSubmitting = true;
    });

    final internalCode = _internalCodeController.text.trim();
    try {
      final request = RimReceiptRequest(
        ownerId: _selectedOwner!.id,
        brandId: _selectedBrand!.id,
        internalCode: internalCode,
        rimDiameter: _selectedDiameter!.value,
        holes: int.parse(_selectedHoles!.value),
        widthIn: int.parse(_selectedWidth!.value),
        material: _selectedMaterial!.value,
        isSet: _isSet,
        quantity: quantity,
        unitPurchasePrice: _toPrice(_priceController.text),
        suggestedSalePrice: _suggestedPriceController.text.trim().isEmpty
            ? null
            : _toPrice(_suggestedPriceController.text),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await widget.apiService.postRimReceipt(request);
      if (_selectedPhotoBytes != null &&
          _photoStorage.supportsPersistentStorage) {
        await _photoStorage.savePhotoBytes(
          internalCode: internalCode,
          bytes: _selectedPhotoBytes!,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingreso de aro registrado.')),
      );
      _resetForm();
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'No se pudo registrar el ingreso de aro.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
    _internalCodeController.clear();
    _quantityController.clear();
    _priceController.clear();
    _suggestedPriceController.clear();
    _notesController.clear();
    setState(() {
      _selectedOwner = widget.choices.owners.isNotEmpty
          ? widget.choices.owners.first
          : null;
      _selectedBrand = null;
      _selectedDiameter = null;
      _selectedHoles = null;
      _selectedWidth = null;
      _selectedMaterial = null;
      _isSet = false;
      _selectedPhoto = null;
      _selectedPhotoBytes = null;
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final code = _internalCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero ingresa el código del aro')),
      );
      return;
    }

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked == null) {
        return;
      }
      final bytes = await picked.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedPhoto = picked;
        _selectedPhotoBytes = bytes;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo seleccionar la foto')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBrands) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_brandsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No se pudieron cargar marcas de aros.\n$_brandsError',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadRimBrands,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Owner>(
              value: _selectedOwner,
              decoration: const InputDecoration(labelText: 'Dueño *'),
              items: widget.choices.owners
                  .map(
                    (owner) => DropdownMenuItem<Owner>(
                      value: owner,
                      child: Text(owner.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedOwner = value),
              validator: (value) => value == null ? 'Selecciona Dueño' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BrandOption>(
              value: _selectedBrand,
              decoration: const InputDecoration(labelText: 'Marca *'),
              items: _rimBrands
                  .map(
                    (brand) => DropdownMenuItem<BrandOption>(
                      value: brand,
                      child: Text(brand.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedBrand = value),
              validator: (value) => value == null ? 'Selecciona Marca' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _internalCodeController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Código interno *'),
              validator: (value) =>
                  _requiredTextValidator(value, 'Código interno'),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Foto (opcional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (!_photoStorage.supportsPersistentStorage)
                      const Text(
                        'Guardado local disponible solo en dispositivo móvil.',
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                !_photoStorage.supportsPersistentStorage ||
                                    _isSubmitting
                                ? null
                                : () => _pickPhoto(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Tomar foto'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                !_photoStorage.supportsPersistentStorage ||
                                    _isSubmitting
                                ? null
                                : () => _pickPhoto(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Elegir de galería'),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedPhotoBytes != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedPhotoBytes!,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedPhoto?.name ?? 'Foto seleccionada',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    setState(() {
                                      _selectedPhoto = null;
                                      _selectedPhotoBytes = null;
                                    });
                                  },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Quitar'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CatalogChoiceOption>(
              value: _selectedDiameter,
              decoration: const InputDecoration(labelText: 'Diámetro *'),
              items: widget.choices.rimDiameters
                  .map(
                    (option) => DropdownMenuItem<CatalogChoiceOption>(
                      value: option,
                      child: Text(option.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedDiameter = value),
              validator: (value) =>
                  value == null ? 'Selecciona Diámetro' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CatalogChoiceOption>(
              value: _selectedHoles,
              decoration: const InputDecoration(
                labelText: 'Número de huecos *',
              ),
              items: widget.choices.rimHoles
                  .map(
                    (option) => DropdownMenuItem<CatalogChoiceOption>(
                      value: option,
                      child: Text(option.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedHoles = value),
              validator: (value) =>
                  value == null ? 'Selecciona Número de huecos' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CatalogChoiceOption>(
              value: _selectedWidth,
              decoration: const InputDecoration(labelText: 'Ancho *'),
              items: widget.choices.rimWidthsIn
                  .map(
                    (option) => DropdownMenuItem<CatalogChoiceOption>(
                      value: option,
                      child: Text(option.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedWidth = value),
              validator: (value) => value == null ? 'Selecciona Ancho' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CatalogChoiceOption>(
              value: _selectedMaterial,
              decoration: const InputDecoration(labelText: 'Material *'),
              items: widget.choices.rimMaterials
                  .map(
                    (option) => DropdownMenuItem<CatalogChoiceOption>(
                      value: option,
                      child: Text(
                        widget.apiService.translateLabel(
                          'rim_material',
                          option,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedMaterial = value),
              validator: (value) =>
                  value == null ? 'Selecciona Material' : null,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _isSet,
              onChanged: (value) {
                setState(() {
                  _isSet = value ?? false;
                  if (_isSet) {
                    _quantityController.text = '1';
                  } else {
                    _quantityController.clear();
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
              title: const Text('Juego completo'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _quantityController,
              enabled: !_isSet,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: _isSet
                    ? 'Cantidad (fijada en 1 por juego)'
                    : 'Cantidad *',
              ),
              validator: (value) => _isSet
                  ? null
                  : _positiveIntValidator(value, 'Cantidad', required: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Precio compra unitario *',
              ),
              validator: (value) =>
                  _positiveDecimalValidator(value, 'Precio compra unitario'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _suggestedPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Precio sugerido',
                hintText: 'Opcional (vacío = null)',
              ),
              validator: (value) => _positiveDecimalValidator(
                value,
                'Precio sugerido',
                required: false,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Notas',
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
              label: Text(_isSubmitting ? 'Guardando...' : 'Guardar ARO'),
            ),
          ],
        ),
      ),
    );
  }
}
