import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/window_item.dart';
import '../services/firestore_service.dart';
import '../services/image_helper.dart';
import '../services/quote_calculator.dart';
import 'product_list_screen.dart';

/// Add / edit form for a window. Lets the user enter dimensions, pick a window
/// product (filtered for compatibility), and attach a gallery photo. A live
/// price estimate updates as the dimensions/product change.
class WindowEditScreen extends StatefulWidget {
  const WindowEditScreen({super.key, required this.roomId, this.existing});

  final String roomId;
  final WindowItem? existing;

  bool get isEditing => existing != null;

  @override
  State<WindowEditScreen> createState() => _WindowEditScreenState();
}

class _WindowEditScreenState extends State<WindowEditScreen> {
  static const int _minMm = 1;
  static const int _maxMm = 20000;

  final FirestoreService _db = FirestoreService();
  final ImageHelper _imageHelper = ImageHelper();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;

  String _productId = '';
  String _productName = '';
  String _variantName = '';
  int _panelCount = 1;
  double _selectedRate = 0;
  String? _photoBase64;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final w = widget.existing;
    _nameController = TextEditingController(text: w?.name ?? '');
    _widthController =
        TextEditingController(text: (w?.widthMm ?? 0) > 0 ? '${w!.widthMm}' : '');
    _heightController = TextEditingController(
        text: (w?.heightMm ?? 0) > 0 ? '${w!.heightMm}' : '');
    _productId = w?.selectedProductId ?? '';
    _productName = w?.selectedProductName ?? '';
    _variantName = w?.selectedProductVariant ?? '';
    _panelCount = w?.panelCount ?? 1;
    _photoBase64 = w?.photoBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  int get _width => int.tryParse(_widthController.text) ?? 0;
  int get _height => int.tryParse(_heightController.text) ?? 0;

  String get _productLabel {
    if (_productId.isEmpty) return 'No product selected';
    return _variantName.isEmpty ? _productName : '$_productName - $_variantName';
  }

  String get _priceLabel {
    if (_productId.isEmpty || _width <= 0 || _height <= 0) {
      return 'Item price: -';
    }
    final area = (_width / 1000.0) * (_height / 1000.0);
    final rate =
        _selectedRate > 0 ? _selectedRate : QuoteCalculator.defaultWindowRate;
    final price = rate * area;
    return 'Item price: \$${price.toStringAsFixed(2)} (${area.toStringAsFixed(4)} sqm)';
  }

  Future<void> _pickProduct() async {
    final selection = await Navigator.of(context).push<ProductSelection>(
      MaterialPageRoute(
        builder: (_) => ProductListScreen(
          category: 'window',
          spaceWidthMm: _width,
          spaceHeightMm: _height,
        ),
      ),
    );
    if (selection == null) return;
    setState(() {
      _productId = selection.product.id;
      _productName = selection.product.name;
      _variantName = selection.variant?.name ?? '';
      _panelCount = selection.panelCount;
      _selectedRate = selection.product.pricePerSqm;
    });
  }

  Future<void> _pickPhoto() async {
    final base64 = await _imageHelper.pickFromGalleryAsBase64();
    if (base64 != null) {
      setState(() => _photoBase64 = base64);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final name = _nameController.text.trim();

    final window = (widget.existing ?? WindowItem(roomId: widget.roomId))
        .copyWith(
      roomId: widget.roomId,
      name: name.isEmpty ? 'Unnamed' : name,
      widthMm: _width,
      heightMm: _height,
      selectedProductId: _productId,
      selectedProductName: _productName,
      selectedProductVariant: _variantName,
      panelCount: _panelCount,
      photoBase64: _photoBase64 ?? '',
    );

    try {
      if (widget.isEditing) {
        await _db.updateWindow(window);
      } else {
        await _db.addWindow(window);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    }
  }

  String? _dimensionValidator(String? value) {
    final n = int.tryParse(value ?? '');
    if (n == null || n < _minMm || n > _maxMm) {
      return 'Enter $_minMm-$_maxMm mm';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Window' : 'Add Window'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Window name (e.g. Living Room Bay)',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _widthController,
                      decoration: const InputDecoration(labelText: 'Width (mm)'),
                      keyboardType: TextInputType.number,
                      validator: _dimensionValidator,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration:
                          const InputDecoration(labelText: 'Height (mm)'),
                      keyboardType: TextInputType.number,
                      validator: _dimensionValidator,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _productSection(),
              const SizedBox(height: 20),
              _photoSection(),
              const SizedBox(height: 12),
              Text(_priceLabel,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save),
                label: Text(_saving ? 'Saving…' : 'Save Window'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(_productLabel),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickProduct,
          icon: const Icon(Icons.inventory_2_outlined),
          label: const Text('Select Window Product'),
        ),
      ],
    );
  }

  Widget _photoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Photo', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: _photoBase64 == null
                ? const Center(
                    child: Icon(Icons.image_outlined,
                        size: 48, color: Colors.grey),
                  )
                : Image.memory(base64Decode(_photoBase64!), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Pick from gallery'),
              ),
            ),
            if (_photoBase64 != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Remove photo',
                onPressed: () => setState(() => _photoBase64 = null),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

