// Unit tests for the QuoteLineItem helpers (area, price and labels).
import 'package:a4kit305/models/quote_line_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuoteLineItem', () {
    test('area and price are derived from mm dimensions', () {
      final item = QuoteLineItem(
        itemType: QuoteItemType.window,
        widthMm: 1000,
        heightOrDepthMm: 2000,
        pricePerSqm: 50,
      );
      expect(item.areaSqm, 2.0); // 1m x 2m
      expect(item.itemPrice, 100.0); // 2 sqm * $50
    });

    test('window label uses H and floor label uses D', () {
      final window = QuoteLineItem(
        itemType: QuoteItemType.window,
        widthMm: 1200,
        heightOrDepthMm: 1500,
      );
      final floor = QuoteLineItem(
        itemType: QuoteItemType.floor,
        widthMm: 3000,
        heightOrDepthMm: 4000,
      );
      expect(window.typeLabel, 'Window');
      expect(window.dimensionLabel, '1200W x 1500H mm');
      expect(floor.typeLabel, 'Floor');
      expect(floor.dimensionLabel, '3000W x 4000D mm');
    });
  });
}


