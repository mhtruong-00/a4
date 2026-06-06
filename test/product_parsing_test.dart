// Unit tests for parsing the product API JSON into Product objects.
import 'package:a4kit305/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Product.fromJson', () {
    test('parses a window product like the API returns', () {
      final product = Product.fromJson({
        'id': 'win-001',
        'name': 'Standard Roller Blind',
        'description': 'A blind',
        'price_per_sqm': 45,
        'min_width': 300,
        'max_width': 1200,
        'max_panels': 1,
        'min_height': 500,
        'max_height': 2400,
        'imageUrl': 'https://example.com/win-001.png',
        'category': 'window',
        'variants': ['White', 'Beige', 'Grey'],
      });

      expect(product, isNotNull);
      expect(product!.id, 'win-001');
      expect(product.name, 'Standard Roller Blind');
      expect(product.pricePerSqm, 45);
      expect(product.minWidth, 300);
      expect(product.maxWidth, 1200);
      expect(product.maxPanelCount, 1);
      expect(product.isWindow, isTrue);
      expect(product.imageUrl, 'https://example.com/win-001.png');
      expect(product.variants.length, 3);
      expect(product.variants.first.name, 'White');
    });

    test('coerces a numeric id and string price', () {
      final product = Product.fromJson({
        'id': 42,
        'name': 'Carpet',
        'price_per_sqm': '99.5',
        'category': 'floor',
      });

      expect(product!.id, '42');
      expect(product.pricePerSqm, 99.5);
      expect(product.isWindow, isFalse);
    });

    test('returns null when the record has no id or name', () {
      expect(Product.fromJson({'name': 'No id'}), isNull);
      expect(Product.fromJson({'id': 'x'}), isNull);
    });
  });
}


