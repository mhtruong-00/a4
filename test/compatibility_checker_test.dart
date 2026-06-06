// Unit tests for the window product compatibility rules.
import 'package:a4kit305/models/product.dart';
import 'package:a4kit305/services/compatibility_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompatibilityChecker', () {
    test('floor products are always compatible', () {
      const floor = Product(category: 'floor');
      final result = CompatibilityChecker.check(floor, 5000, 4000);
      expect(result.compatible, isTrue);
      expect(result.panelCount, 1);
    });

    test('single-panel window fits within range', () {
      const window = Product(
        category: 'window',
        minWidth: 300,
        maxWidth: 1200,
        minHeight: 500,
        maxHeight: 2400,
        maxPanelCount: 1,
      );
      final result = CompatibilityChecker.check(window, 1000, 2000);
      expect(result.compatible, isTrue);
      expect(result.panelCount, 1);
    });

    test('window too tall is rejected', () {
      const window = Product(
        category: 'window',
        minHeight: 500,
        maxHeight: 2400,
        maxPanelCount: 1,
      );
      final result = CompatibilityChecker.check(window, 1000, 3000);
      expect(result.compatible, isFalse);
    });

    test('wide window is split across multiple panels', () {
      const window = Product(
        category: 'window',
        minWidth: 600,
        maxWidth: 1000,
        minHeight: 1000,
        maxHeight: 3000,
        maxPanelCount: 4,
      );
      // 1800mm doesn't fit one panel (>1000) but two panels of 900mm do.
      final result = CompatibilityChecker.check(window, 1800, 2000);
      expect(result.compatible, isTrue);
      expect(result.panelCount, 2);
    });

    test('too-wide single-panel window is rejected', () {
      const window = Product(
        category: 'window',
        minWidth: 300,
        maxWidth: 1200,
        minHeight: 500,
        maxHeight: 2400,
        maxPanelCount: 1,
      );
      final result = CompatibilityChecker.check(window, 1500, 2000);
      expect(result.compatible, isFalse);
    });

    test('too-narrow window is rejected', () {
      const window = Product(
        category: 'window',
        minWidth: 600,
        maxWidth: 1200,
        minHeight: 500,
        maxHeight: 2400,
        maxPanelCount: 1,
      );
      final result = CompatibilityChecker.check(window, 400, 1000);
      expect(result.compatible, isFalse);
    });

    test('no dimensions set is treated as compatible', () {
      const window = Product(category: 'window', maxPanelCount: 1);
      final result = CompatibilityChecker.check(window, 0, 0);
      expect(result.compatible, isTrue);
      expect(result.message, 'No dimensions set');
    });
  });
}



