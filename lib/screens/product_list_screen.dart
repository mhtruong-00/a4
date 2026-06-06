import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/compatibility_checker.dart';
import '../services/product_api.dart';

/// What the product picker hands back to the editor: the chosen product, an
/// optional variant, and the panel count worked out by the compatibility check.
class ProductSelection {
  final Product product;
  final ProductVariant? variant;
  final int panelCount;

  const ProductSelection({
    required this.product,
    this.variant,
    this.panelCount = 1,
  });
}

/// Lists products from the API for a category ("window" or "floor"). For window
/// products it also shows whether each one fits the space's dimensions. Pops
/// with a [ProductSelection] when the user picks one.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({
    super.key,
    required this.category,
    this.spaceWidthMm = 0,
    this.spaceHeightMm = 0,
    this.selectedProductId,
  });

  final String category;
  final int spaceWidthMm;
  final int spaceHeightMm;
  final String? selectedProductId;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductApi _api = ProductApi();

  List<Product> _products = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final products = await _api.fetchProducts(category: widget.category);
    if (!mounted) return;
    setState(() {
      _products = products;
      _loading = false;
    });
  }

  List<Product> get _filtered {
    if (_search.isEmpty) return _products;
    final q = _search.toLowerCase();
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q))
        .toList();
  }

  String get _title =>
      widget.category == 'window' ? 'Window Products' : 'Floor Products';

  Future<void> _selectProduct(Product product) async {
    var panelCount = 1;
    if (product.isWindow) {
      final compat = CompatibilityChecker.check(
        product,
        widget.spaceWidthMm,
        widget.spaceHeightMm,
      );
      if (!compat.compatible) {
        _showCannotSelect(compat.message);
        return;
      }
      panelCount = compat.panelCount;
    }

    if (product.variants.isEmpty) {
      Navigator.of(context).pop(
        ProductSelection(product: product, panelCount: panelCount),
      );
      return;
    }

    final variant = await _pickVariant(product);
    if (variant != null && mounted) {
      Navigator.of(context).pop(
        ProductSelection(
          product: product,
          variant: variant,
          panelCount: panelCount,
        ),
      );
    }
  }

  Future<ProductVariant?> _pickVariant(Product product) {
    return showModalBottomSheet<ProductVariant>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('\$${product.pricePerSqm.toStringAsFixed(2)} / m²'),
                    if (product.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          product.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose an option:',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
              for (final variant in product.variants)
                ListTile(
                  title: Text(variant.name),
                  onTap: () => Navigator.of(context).pop(variant),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showCannotSelect(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cannot select'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search products',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = _filtered;
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 200),
            Center(child: Text('No products found.')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) => _productTile(items[index]),
      ),
    );
  }

  Widget _productTile(Product product) {
    final compat = product.isWindow
        ? CompatibilityChecker.check(
            product, widget.spaceWidthMm, widget.spaceHeightMm)
        : null;
    final incompatible = compat != null && !compat.compatible;
    final isSelected = product.id == widget.selectedProductId;

    return ListTile(
      selected: isSelected,
      leading: _productImage(product),
      title: Text(product.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('\$${product.pricePerSqm.toStringAsFixed(2)} / m²'),
          if (compat != null && compat.message.isNotEmpty)
            Text(
              compat.message,
              style: TextStyle(
                color: incompatible ? Colors.red : Colors.green.shade700,
                fontSize: 12,
              ),
            ),
        ],
      ),
      trailing: incompatible
          ? const Icon(Icons.block, color: Colors.red)
          : isSelected
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.chevron_right),
      onTap: () => _selectProduct(product),
    );
  }

  Widget _productImage(Product product) {
    final url = product.imageUrl;
    if (url == null || url.isEmpty) {
      return const Icon(Icons.inventory_2_outlined, size: 40);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.inventory_2_outlined, size: 40),
      ),
    );
  }
}






