import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/floor_space.dart';
import '../services/firestore_service.dart';
import '../services/image_helper.dart';
import '../services/quote_calculator.dart';
import '../theme.dart';
import 'product_list_screen.dart';

/// Add / edit form for a floor space. Like the window editor but uses width x
/// depth and floor products (which have no size limits).
class FloorSpaceEditScreen extends StatefulWidget {
  const FloorSpaceEditScreen({super.key, required this.roomId, this.existing});

  final String roomId;
  final FloorSpace? existing;

  bool get isEditing => existing != null;

  @override
  State<FloorSpaceEditScreen> createState() => _FloorSpaceEditScreenState();
}

class _FloorSpaceEditScreenState extends State<FloorSpaceEditScreen> {
  static const int _minMm = 1;
  static const int _maxMm = 20000;

  final FirestoreService _db = FirestoreService();
  final ImageHelper _imageHelper = ImageHelper();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _widthController;
  late final TextEditingController _depthController;

  String _productId = '';
  String _productName = '';
  String _variantName = '';
  double _selectedRate = 0;
  String? _photoBase64;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final f = widget.existing;
    _nameController = TextEditingController(text: f?.name ?? '');
    _widthController = TextEditingController(
        text: (f?.widthMm ?? 0) > 0 ? '${f!.widthMm}' : '');
    _depthController = TextEditingController(
        text: (f?.depthMm ?? 0) > 0 ? '${f!.depthMm}' : '');
    _productId = f?.selectedProductId ?? '';
    _productName = f?.selectedProductName ?? '';
    _variantName = f?.selectedProductVariant ?? '';
    _photoBase64 = f?.photoBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    super.dispose();
  }

  int get _width => int.tryParse(_widthController.text) ?? 0;
  int get _depth => int.tryParse(_depthController.text) ?? 0;

  String get _productLabel {
    if (_productId.isEmpty) return 'No product selected';
    return _variantName.isEmpty ? _productName : '$_productName - $_variantName';
  }

  String get _priceLabel {
    if (_productId.isEmpty || _width <= 0 || _depth <= 0) {
      return 'Item price: -';
    }
    final area = (_width / 1000.0) * (_depth / 1000.0);
    final rate =
        _selectedRate > 0 ? _selectedRate : QuoteCalculator.defaultFloorRate;
    final price = rate * area;
    return 'Item price: \$${price.toStringAsFixed(2)} (${area.toStringAsFixed(4)} sqm)';
  }

  Future<void> _pickProduct() async {
    final selection = await Navigator.of(context).push<ProductSelection>(
      MaterialPageRoute(
        builder: (_) => ProductListScreen(
          category: 'floor',
          spaceWidthMm: _width,
          spaceHeightMm: _depth,
        ),
      ),
    );
    if (selection == null) return;
    setState(() {
      _productId = selection.product.id;
      _productName = selection.product.name;
      _variantName = selection.variant?.name ?? '';
      _selectedRate = selection.product.pricePerSqm;
    });
  }

  Future<void> _pickPhoto() async {
    final base64 = await _imageHelper.pickFromGalleryAsBase64();
    if (base64 != null) {
      setState(() => _photoBase64 = base64);
    }
  }

  void _clearProduct() {
    setState(() {
      _productId = '';
      _productName = '';
      _variantName = '';
      _selectedRate = 0;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final name = _nameController.text.trim();

    final floor = (widget.existing ?? FloorSpace(roomId: widget.roomId))
        .copyWith(
      roomId: widget.roomId,
      name: name.isEmpty ? 'Unnamed' : name,
      widthMm: _width,
      depthMm: _depth,
      selectedProductId: _productId,
      selectedProductName: _productName,
      selectedProductVariant: _variantName,
      photoBase64: _photoBase64 ?? '',
    );

    try {
      if (widget.isEditing) {
        await _db.updateFloorSpace(floor);
      } else {
        await _db.addFloorSpace(floor);
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
        title: Text(widget.isEditing ? 'Edit Floor Space' : 'Add Floor Space'),
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
                  labelText: 'Floor space name (e.g. Main floor)',
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
                      controller: _depthController,
                      decoration: const InputDecoration(labelText: 'Depth (mm)'),
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
                label: Text(_saving ? 'Saving…' : 'Save Floor Space'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.floorTint,
                ),
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
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickProduct,
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Select Floor Product'),
              ),
            ),
            if (_productId.isNotEmpty)
              TextButton(
                onPressed: _clearProduct,
                child: const Text('Clear'),
              ),
          ],
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





