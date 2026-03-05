import 'dart:async';

import 'package:flutter/material.dart';

import '../models/brand_option.dart';

class BrandAutocompleteField extends StatefulWidget {
  const BrandAutocompleteField({
    super.key,
    required this.controller,
    required this.onSelected,
    required this.searchBrands,
    this.initialValue,
  });

  final TextEditingController controller;
  final ValueChanged<BrandOption?> onSelected;
  final Future<List<BrandOption>> Function(String query) searchBrands;
  final BrandOption? initialValue;

  @override
  State<BrandAutocompleteField> createState() => _BrandAutocompleteFieldState();
}

class _BrandAutocompleteFieldState extends State<BrandAutocompleteField> {
  List<BrandOption> _options = const [];
  bool _isLoading = false;
  Timer? _debounce;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      widget.controller.text = widget.initialValue!.name;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _refreshOptions(String query) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await widget.searchBrands(query);
        if (!mounted) {
          return;
        }
        setState(() {
          _lastQuery = query;
          _options = result;
        });
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _lastQuery = query;
          _options = const [];
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<BrandOption>(
      displayStringForOption: (option) => option.name,
      initialValue: TextEditingValue(text: widget.controller.text),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim();
        if (query != _lastQuery) {
          _refreshOptions(query);
        }

        if (query.isEmpty) {
          return _options;
        }

        return _options.where(
          (option) => option.name.toLowerCase().contains(query.toLowerCase()),
        );
      },
      onSelected: (option) {
        widget.controller.text = option.name;
        widget.onSelected(option);
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        if (widget.controller.text.isNotEmpty &&
            textEditingController.text != widget.controller.text) {
          textEditingController.value = TextEditingValue(
            text: widget.controller.text,
            selection: TextSelection.collapsed(offset: widget.controller.text.length),
          );
        }

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Marca *',
            hintText: 'Busca una marca',
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.search),
          ),
          onChanged: (value) {
            widget.controller.text = value;
            widget.onSelected(null);
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Selecciona una marca';
            }
            return null;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final optionsList = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, minWidth: 280),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: optionsList.length,
                itemBuilder: (context, index) {
                  final option = optionsList[index];
                  return ListTile(
                    title: Text(option.name),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
