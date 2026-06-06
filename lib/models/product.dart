// Product + variant models for the KIT305 product API.
// The API returns interior products (window coverings + floor coverings). I keep
// the same fields as my iOS/Android apps so the compatibility check and quote
// maths line up.

class ProductVariant {
  final String id;
  final String name;

  const ProductVariant({this.id = '', this.name = ''});
}

class Product {
  final String id;
  final String name;
  final String description;
  final String category; // "window" or "floor"
  final String? imageUrl;
  final double pricePerSqm;
  final List<ProductVariant> variants;
  final int minWidth;
  final int maxWidth;
  final int minHeight;
  final int maxHeight;
  final int maxPanelCount;

  const Product({
    this.id = '',
    this.name = '',
    this.description = '',
    this.category = '',
    this.imageUrl,
    this.pricePerSqm = 0,
    this.variants = const [],
    this.minWidth = 0,
    this.maxWidth = 9999,
    this.minHeight = 0,
    this.maxHeight = 9999,
    this.maxPanelCount = 1,
  });

  bool get isWindow => category == 'window';
}

