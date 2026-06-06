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

  /// Build a Product from one API record. The API isn't totally consistent so I
  /// accept both snake_case and camelCase keys, and numbers that come back as
  /// String/int/double. Returns null if the record has no usable id or name.
  static Product? fromJson(Map<String, dynamic> json) {
    final id = _stringId(json['id']);
    final name = (json['name'] as String?) ?? '';
    if (id.isEmpty || name.isEmpty) return null;

    return Product(
      id: id,
      name: name,
      description: (json['description'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      imageUrl: (json['image_url'] ?? json['imageUrl']) as String?,
      pricePerSqm: _toDouble(json['price_per_sqm'] ?? json['pricePerSqm']),
      variants: _parseVariants(json['variants'], id),
      minWidth: _toInt(json['min_width'] ?? json['minWidth'], 0),
      maxWidth: _toInt(json['max_width'] ?? json['maxWidth'], 9999),
      minHeight: _toInt(json['min_height'] ?? json['minHeight'], 0),
      maxHeight: _toInt(json['max_height'] ?? json['maxHeight'], 9999),
      maxPanelCount: _toInt(
        json['max_panels'] ?? json['maxPanels'] ?? json['maxPanelCount'],
        1,
      ),
    );
  }
}

String _stringId(Object? value) {
  if (value is String) return value;
  if (value is int) return value.toString();
  return '';
}

double _toDouble(Object? value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _toInt(Object? value, int fallback) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Variants can come back as a list of plain strings or a list of objects with
/// a name/variant key. Handle both shapes.
List<ProductVariant> _parseVariants(Object? raw, String productId) {
  if (raw is List) {
    final result = <ProductVariant>[];
    for (var i = 0; i < raw.length; i++) {
      final entry = raw[i];
      if (entry is String && entry.isNotEmpty) {
        result.add(ProductVariant(id: '${productId}_v$i', name: entry));
      } else if (entry is Map<String, dynamic>) {
        final name = (entry['name'] ?? entry['variant']) as String?;
        if (name != null && name.isNotEmpty) {
          final vid = (entry['id'] as String?) ?? '${productId}_v$i';
          result.add(ProductVariant(id: vid, name: name));
        }
      }
    }
    return result;
  }
  return const [];
}



