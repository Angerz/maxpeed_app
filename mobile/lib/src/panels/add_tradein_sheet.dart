import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/brand_option.dart';
import '../models/catalog_choice_option.dart';
import '../models/catalog_choices.dart';
import '../models/cart_models.dart';
import '../models/owner.dart';
import '../services/catalog_api_service.dart';
import '../widgets/brand_autocomplete_field.dart';

class TradeInFormResult {
  const TradeInFormResult({
    required this.type,
    required this.quantity,
    required this.purchasePrice,
    required this.specsSummary,
    required this.notes,
    this.tireSpec,
    this.rimSpec,
    this.conditionPercent,
    this.needsRepair,
    this.rimPhoto,
  });

  final TradeInType type;
  final int quantity;
  final double purchasePrice;
  final String specsSummary;
  final String? notes;
  final TradeInTireSpec? tireSpec;
  final TradeInRimSpec? rimSpec;
  final int? conditionPercent;
  final bool? needsRepair;
  final XFile? rimPhoto;
}

class AddTradeInSheet extends StatefulWidget {
  const AddTradeInSheet({super.key, this.initialLine});

  final TradeInLine? initialLine;

  @override
  State<AddTradeInSheet> createState() => _AddTradeInSheetState();
}

class _AddTradeInSheetState extends State<AddTradeInSheet> {
  final _apiService = CatalogApiService();
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  final _tireBrandController = TextEditingController();
  final _rimInternalCodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _widthController = TextEditingController();
  final _aspectController = TextEditingController();
  final _modelController = TextEditingController();
  final _suggestedSaleController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  CatalogChoices? _choices;
  List<BrandOption> _rimBrands = const [];
  bool _loading = true;
  String? _loadError;

  late TradeInType _type;
  int _conditionPercent = 70;
  bool _needsRepair = false;
  bool _isSet = false;
  XFile? _selectedRimPhoto;
  Uint8List? _selectedRimPhotoBytes;

  Owner? _selectedOwner;
  BrandOption? _selectedTireBrand;
  BrandOption? _selectedRimBrand;
  CatalogChoiceOption? _selectedTireType;
  CatalogChoiceOption? _selectedTireRim;
  CatalogChoiceOption? _selectedOrigin;
  CatalogChoiceOption? _selectedPly;
  CatalogChoiceOption? _selectedTread;
  CatalogChoiceOption? _selectedLetterColor;
  CatalogChoiceOption? _selectedRimDiameter;
  CatalogChoiceOption? _selectedRimHoles;
  CatalogChoiceOption? _selectedRimWidth;
  CatalogChoiceOption? _selectedRimMaterial;

  @override
  void initState() {
    super.initState();
    _type = widget.initialLine?.type ?? TradeInType.tire;
    _conditionPercent = widget.initialLine?.conditionPercent ?? 70;
    _needsRepair = widget.initialLine?.needsRepair ?? false;
    _priceController.text =
        widget.initialLine?.purchasePrice.toStringAsFixed(2) ?? '';
    _notesController.text = widget.initialLine?.notes ?? '';
    _quantityController.text = (widget.initialLine?.quantity ?? 1).toString();
    _selectedRimPhoto = widget.initialLine?.rimPhoto;
    if (_selectedRimPhoto != null) {
      _loadExistingRimPhotoPreview();
    }
    _loadData();
  }

  @override
  void dispose() {
    _tireBrandController.dispose();
    _rimInternalCodeController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _widthController.dispose();
    _aspectController.dispose();
    _modelController.dispose();
    _suggestedSaleController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  bool get _showAspectField {
    final tireType = _selectedTireType?.value;
    return tireType == 'RADIAL' || tireType == 'MILLIMETRIC';
  }

  bool get _ownerIsAldo =>
      (_selectedOwner?.name.trim().toUpperCase() ?? '') == 'ALDO';

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final data = await Future.wait([
        _apiService.fetchChoices(),
        _apiService.fetchRimBrands(),
      ]);
      if (!mounted) {
        return;
      }
      final choices = data[0] as CatalogChoices;
      final rimBrands = data[1] as List<BrandOption>;

      setState(() {
        _choices = choices;
        _rimBrands = rimBrands;
      });

      await _hydrateInitialValues(choices, rimBrands);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _hydrateInitialValues(
    CatalogChoices choices,
    List<BrandOption> rimBrands,
  ) async {
    final line = widget.initialLine;
    if (line == null) {
      return;
    }

    if (line.type == TradeInType.tire && line.tireSpec != null) {
      final spec = line.tireSpec!;
      _selectedOwner = _findOwner(choices.owners, spec.ownerId);
      _selectedTireType = _findChoice(choices.tireTypes, spec.tireType);
      _selectedTireRim = _findChoice(choices.rimDiameters, spec.rimDiameter);
      _selectedOrigin = _findChoice(choices.origins, spec.origin);
      _selectedPly = _findChoice(choices.plyRatings, spec.plyRating);
      _selectedTread = _findChoice(choices.treadTypes, spec.treadType);
      _selectedLetterColor = _findChoice(
        choices.letterColors,
        spec.letterColor,
      );
      _widthController.text = spec.width.toString();
      _aspectController.text = spec.aspectRatio?.toString() ?? '';
      _modelController.text = spec.model ?? '';
      _suggestedSaleController.text = spec.suggestedSalePrice ?? '';

      final brandName = _extractBrandNameFromSummary(line.specsSummary);
      if (brandName.isNotEmpty) {
        try {
          final searched = await _apiService.searchBrands(brandName);
          if (!mounted) {
            return;
          }
          final matched = searched
              .where((item) => item.id == spec.brandId)
              .cast<BrandOption?>()
              .firstWhere(
                (item) => item != null,
                orElse: () => searched
                    .where(
                      (item) =>
                          item.name.trim().toUpperCase() ==
                          brandName.toUpperCase(),
                    )
                    .cast<BrandOption?>()
                    .firstWhere((item) => item != null, orElse: () => null),
              );
          if (matched != null) {
            setState(() {
              _selectedTireBrand = matched;
              _tireBrandController.text = matched.name;
            });
          }
        } catch (_) {
          // If brand search fails, user can pick brand manually.
        }
      }
      if (mounted) {
        setState(() {});
      }
      return;
    }

    if (line.type == TradeInType.rim && line.rimSpec != null) {
      final spec = line.rimSpec!;
      _selectedOwner = _findOwner(choices.owners, spec.ownerId);
      _selectedRimBrand = rimBrands
          .where((item) => item.id == spec.brandId)
          .cast<BrandOption?>()
          .firstWhere((item) => item != null, orElse: () => null);
      _rimInternalCodeController.text = spec.internalCode;
      _selectedRimDiameter = _findChoice(
        choices.rimDiameters,
        spec.rimDiameter,
      );
      _selectedRimHoles = _findChoice(choices.rimHoles, spec.holes.toString());
      _selectedRimWidth = _findChoice(
        choices.rimWidthsIn,
        spec.widthIn.toString(),
      );
      _selectedRimMaterial = _findChoice(choices.rimMaterials, spec.material);
      _isSet = spec.isSet;
      _suggestedSaleController.text = spec.suggestedSalePrice ?? '';
      if (_isSet) {
        _quantityController.text = '1';
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

  CatalogChoiceOption? _findChoice(
    List<CatalogChoiceOption> options,
    String? value,
  ) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    for (final option in options) {
      if (option.value == value) {
        return option;
      }
    }
    return null;
  }

  Owner? _findOwner(List<Owner> owners, int? ownerId) {
    if (ownerId == null) {
      return null;
    }
    for (final owner in owners) {
      if (owner.id == ownerId) {
        return owner;
      }
    }
    return null;
  }

  String _extractBrandNameFromSummary(String summary) {
    final parts = summary.split('|').map((item) => item.trim()).toList();
    if (parts.length < 2) {
      return '';
    }
    return parts[1];
  }

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return 'El campo $field es obligatorio';
    }
    return null;
  }

  String? _positiveInt(String? value, String field) {
    final requiredError = _required(value, field);
    if (requiredError != null) {
      return requiredError;
    }
    final parsed = int.tryParse(value!.trim());
    if (parsed == null || parsed <= 0) {
      return 'Ingresa $field > 0';
    }
    return null;
  }

  String? _positiveDecimal(
    String? value,
    String field, {
    bool required = true,
  }) {
    if (!required && (value == null || value.trim().isEmpty)) {
      return null;
    }
    final requiredError = _required(value, field);
    if (requiredError != null) {
      return requiredError;
    }
    final parsed = double.tryParse(value!.trim());
    if (parsed == null || parsed <= 0) {
      return 'Ingresa $field > 0';
    }
    return null;
  }

  String? _toPriceOrNull(String raw) {
    if (raw.trim().isEmpty) {
      return null;
    }
    return double.parse(raw.trim()).toStringAsFixed(2);
  }

  int _tradeInQuantity() {
    if (_type == TradeInType.rim && _isSet) {
      return 1;
    }
    return int.parse(_quantityController.text.trim());
  }

  TradeInTireSpec _buildTireSpec() {
    return TradeInTireSpec(
      ownerId: _selectedOwner?.id,
      brandId: _selectedTireBrand!.id,
      tireType: _selectedTireType!.value,
      rimDiameter: _selectedTireRim!.value,
      origin: _selectedOrigin!.value,
      plyRating: _selectedPly!.value,
      treadType: _selectedTread!.value,
      letterColor: _selectedLetterColor!.value,
      width: int.parse(_widthController.text.trim()),
      aspectRatio: _showAspectField
          ? int.parse(_aspectController.text.trim())
          : null,
      model: _modelController.text.trim().isEmpty
          ? null
          : _modelController.text.trim(),
      suggestedSalePrice: _toPriceOrNull(_suggestedSaleController.text),
    );
  }

  TradeInRimSpec _buildRimSpec() {
    return TradeInRimSpec(
      ownerId: _selectedOwner?.id,
      brandId: _selectedRimBrand!.id,
      internalCode: _rimInternalCodeController.text.trim(),
      rimDiameter: _selectedRimDiameter!.value,
      holes: int.parse(_selectedRimHoles!.value),
      widthIn: int.parse(_selectedRimWidth!.value),
      material: _selectedRimMaterial!.value,
      isSet: _isSet,
      suggestedSalePrice: _toPriceOrNull(_suggestedSaleController.text),
    );
  }

  String _buildSummary() {
    if (_type == TradeInType.tire) {
      final code = _showAspectField
          ? '${_widthController.text.trim()}/${_aspectController.text.trim()}${_selectedTireRim?.value ?? ''}'
          : '${_widthController.text.trim()}${_selectedTireRim?.value ?? ''}';
      return 'Llanta USED | ${_selectedTireBrand?.name ?? '-'} | $code';
    }
    return 'Aro USED | ${_selectedRimBrand?.name ?? '-'} | ${_rimInternalCodeController.text.trim()}';
  }

  Future<void> _loadExistingRimPhotoPreview() async {
    try {
      final bytes = await _selectedRimPhoto!.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedRimPhotoBytes = bytes;
      });
    } catch (_) {
      // ignore preview read failure
    }
  }

  Future<void> _pickRimPhoto(ImageSource source) async {
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
        _selectedRimPhoto = picked;
        _selectedRimPhotoBytes = bytes;
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

  Widget _buildRimPhotoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Foto (opcional)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickRimPhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Tomar foto'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickRimPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Elegir de galería'),
                  ),
                ),
              ],
            ),
            if (_selectedRimPhotoBytes != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _selectedRimPhotoBytes!,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedRimPhoto?.name ?? 'Foto seleccionada',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedRimPhoto = null;
                        _selectedRimPhotoBytes = null;
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
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_ownerIsAldo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No está permitido seleccionar ALDO para trade-in.'),
        ),
      );
      return;
    }
    if (_choices == null) {
      return;
    }

    if (_type == TradeInType.tire) {
      if (_selectedTireBrand == null ||
          _selectedTireType == null ||
          _selectedTireRim == null ||
          _selectedOrigin == null ||
          _selectedPly == null ||
          _selectedTread == null ||
          _selectedLetterColor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Completa todos los campos requeridos de la llanta USED.',
            ),
          ),
        );
        return;
      }
    } else {
      if (_selectedRimBrand == null ||
          _selectedRimDiameter == null ||
          _selectedRimHoles == null ||
          _selectedRimWidth == null ||
          _selectedRimMaterial == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completa todos los campos requeridos del aro USED.'),
          ),
        );
        return;
      }
    }

    final result = TradeInFormResult(
      type: _type,
      quantity: _tradeInQuantity(),
      purchasePrice: double.parse(_priceController.text.trim()),
      specsSummary: _buildSummary(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      tireSpec: _type == TradeInType.tire ? _buildTireSpec() : null,
      rimSpec: _type == TradeInType.rim ? _buildRimSpec() : null,
      conditionPercent: _type == TradeInType.tire ? _conditionPercent : null,
      needsRepair: _type == TradeInType.rim ? _needsRepair : null,
      rimPhoto: _type == TradeInType.rim ? _selectedRimPhoto : null,
    );
    Navigator.of(context).pop(result);
  }

  Widget _ownerField(List<Owner> owners) {
    return DropdownButtonFormField<Owner?>(
      initialValue: _selectedOwner,
      decoration: const InputDecoration(labelText: 'Dueño (opcional)'),
      items: <DropdownMenuItem<Owner?>>[
        const DropdownMenuItem<Owner?>(value: null, child: Text('Sin dueño')),
        ...owners.map(
          (owner) =>
              DropdownMenuItem<Owner?>(value: owner, child: Text(owner.name)),
        ),
      ],
      onChanged: (value) {
        if ((value?.name.trim().toUpperCase() ?? '') == 'ALDO') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No está permitido seleccionar ALDO para trade-in.',
              ),
            ),
          );
          return;
        }
        setState(() {
          _selectedOwner = value;
        });
      },
    );
  }

  Widget _buildTireFields(CatalogChoices choices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BrandAutocompleteField(
          controller: _tireBrandController,
          initialValue: _selectedTireBrand,
          searchBrands: _apiService.searchBrands,
          onSelected: (brand) {
            _selectedTireBrand = brand;
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CatalogChoiceOption>(
          initialValue: _selectedTireType,
          decoration: const InputDecoration(labelText: 'Tipo de neumático *'),
          items: choices.tireTypes
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option.label)),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedTireType = value;
              if (!_showAspectField) {
                _aspectController.clear();
              }
            });
          },
          validator: (value) =>
              value == null ? 'Selecciona tipo de neumático' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CatalogChoiceOption>(
          initialValue: _selectedTireRim,
          decoration: const InputDecoration(labelText: 'Aro *'),
          items: choices.rimDiameters
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option.label)),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedTireRim = value),
          validator: (value) => value == null ? 'Selecciona aro' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _widthController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Ancho *'),
          validator: (value) => _positiveInt(value, 'Ancho'),
        ),
        if (_showAspectField) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _aspectController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Perfil *'),
            validator: (value) => _positiveInt(value, 'Perfil'),
          ),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<CatalogChoiceOption>(
          initialValue: _selectedOrigin,
          decoration: const InputDecoration(labelText: 'Origen *'),
          items: choices.origins
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option.label)),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedOrigin = value),
          validator: (value) => value == null ? 'Selecciona origen' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CatalogChoiceOption>(
          initialValue: _selectedPly,
          decoration: const InputDecoration(labelText: 'PR *'),
          items: choices.plyRatings
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option.label)),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedPly = value),
          validator: (value) => value == null ? 'Selecciona PR' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CatalogChoiceOption>(
          initialValue: _selectedTread,
          decoration: const InputDecoration(labelText: 'Diseño *'),
          items: choices.treadTypes
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option.label)),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedTread = value),
          validator: (value) => value == null ? 'Selecciona diseño' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CatalogChoiceOption>(
          initialValue: _selectedLetterColor,
          decoration: const InputDecoration(labelText: 'Color letra *'),
          items: choices.letterColors
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option.label)),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedLetterColor = value),
          validator: (value) =>
              value == null ? 'Selecciona color de letra' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _modelController,
          decoration: const InputDecoration(
            labelText: 'Modelo',
            hintText: 'Opcional',
          ),
        ),
      ],
    );
  }

  Widget _buildRimFields(CatalogChoices choices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<BrandOption>(
          initialValue: _selectedRimBrand,
          decoration: const InputDecoration(labelText: 'Marca *'),
          items: _rimBrands
              .map(
                (brand) =>
                    DropdownMenuItem(value: brand, child: Text(brand.name)),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedRimBrand = value),
          validator: (value) => value == null ? 'Selecciona marca' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _rimInternalCodeController,
          decoration: const InputDecoration(labelText: 'Código interno *'),
          validator: (value) => _required(value, 'Código interno'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CatalogChoiceOption>(
          initialValue: _selectedRimDiameter,
          decoration: const InputDecoration(labelText: 'Diámetro *'),
          items: choices.rimDiameters
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option.label)),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedRimDiameter = value),
          validator: (value) => value == null ? 'Selecciona diámetro' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CatalogChoiceOption>(
          initialValue: _selectedRimHoles,
          decoration: const InputDecoration(labelText: 'Huecos *'),
          items: choices.rimHoles
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option.label)),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedRimHoles = value),
          validator: (value) => value == null ? 'Selecciona huecos' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CatalogChoiceOption>(
          initialValue: _selectedRimWidth,
          decoration: const InputDecoration(labelText: 'Ancho *'),
          items: choices.rimWidthsIn
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option.label)),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedRimWidth = value),
          validator: (value) => value == null ? 'Selecciona ancho' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CatalogChoiceOption>(
          initialValue: _selectedRimMaterial,
          decoration: const InputDecoration(labelText: 'Material *'),
          items: choices.rimMaterials
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option.label)),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedRimMaterial = value),
          validator: (value) => value == null ? 'Selecciona material' : null,
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _isSet,
          contentPadding: EdgeInsets.zero,
          title: const Text('Juego completo'),
          onChanged: (value) {
            setState(() {
              _isSet = value ?? false;
              if (_isSet) {
                _quantityController.text = '1';
              }
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_loadError != null || _choices == null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _loadError ?? 'No se pudo cargar Trade-in',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.initialLine == null
                      ? 'Agregar Trade-in (ingreso USED)'
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
                      if (_type == TradeInType.rim && _isSet) {
                        _quantityController.text = '1';
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                _ownerField(_choices!.owners),
                const SizedBox(height: 12),
                if (_type == TradeInType.tire)
                  _buildTireFields(_choices!)
                else
                  _buildRimFields(_choices!),
                if (_type == TradeInType.rim) ...[
                  const SizedBox(height: 12),
                  _buildRimPhotoSection(),
                ],
                const SizedBox(height: 12),
                if (_type == TradeInType.tire) ...[
                  Text(
                    'Estado/Condición: $_conditionPercent%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Slider(
                    min: 10,
                    max: 100,
                    divisions: 9,
                    value: _conditionPercent.toDouble(),
                    label: '$_conditionPercent%',
                    onChanged: (value) {
                      setState(() {
                        _conditionPercent = ((value / 10).round() * 10).clamp(
                          10,
                          100,
                        );
                      });
                    },
                  ),
                ] else ...[
                  CheckboxListTile(
                    value: _needsRepair,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Requiere reparación'),
                    onChanged: (value) =>
                        setState(() => _needsRepair = value ?? false),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  enabled: !(_type == TradeInType.rim && _isSet),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: (_type == TradeInType.rim && _isSet)
                        ? 'Cantidad (forzada a 1 por juego)'
                        : 'Cantidad *',
                  ),
                  validator: (value) => (_type == TradeInType.rim && _isSet)
                      ? null
                      : _positiveInt(value, 'Cantidad'),
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
                  decoration: const InputDecoration(
                    labelText: 'Precio compra unitario (USED) *',
                  ),
                  validator: (value) =>
                      _positiveDecimal(value, 'Precio compra unitario'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _suggestedSaleController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Precio sugerido',
                    hintText: 'Opcional',
                  ),
                  validator: (value) => _positiveDecimal(
                    value,
                    'Precio sugerido',
                    required: false,
                  ),
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
                  onPressed: _submit,
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
