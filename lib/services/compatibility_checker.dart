import '../models/product.dart';

/// Result of checking whether a product fits a given space.
class CompatibilityResult {
  final bool compatible;
  final int panelCount;
  final String message;

  const CompatibilityResult({
    required this.compatible,
    required this.panelCount,
    required this.message,
  });
}

/// Checks whether a window product fits a space, working out how many panels it
/// needs. Floor products are always compatible. This mirrors the rules from my
/// Android/iOS apps so the same products behave the same way.
class CompatibilityChecker {
  static CompatibilityResult check(Product product, int widthMm, int heightMm) {
    // Floor products have no size limits.
    if (!product.isWindow) {
      return const CompatibilityResult(
        compatible: true,
        panelCount: 1,
        message: '',
      );
    }

    if (widthMm <= 0 && heightMm <= 0) {
      return const CompatibilityResult(
        compatible: true,
        panelCount: 1,
        message: 'No dimensions set',
      );
    }

    // Height must be within the product's range.
    if (heightMm > 0) {
      if (heightMm < product.minHeight) {
        return CompatibilityResult(
          compatible: false,
          panelCount: 1,
          message: 'Too short: ${heightMm}mm (min ${product.minHeight}mm)',
        );
      }
      if (heightMm > product.maxHeight) {
        return CompatibilityResult(
          compatible: false,
          panelCount: 1,
          message: 'Too tall: ${heightMm}mm (max ${product.maxHeight}mm)',
        );
      }
    }

    // Width: try splitting into 1..maxPanels and see if any panel width fits.
    if (widthMm > 0) {
      final maxPanels = product.maxPanelCount < 1 ? 1 : product.maxPanelCount;
      for (var panels = 1; panels <= maxPanels; panels++) {
        final panelWidth = widthMm / panels;
        if (panelWidth >= product.minWidth && panelWidth <= product.maxWidth) {
          final message = panels == 1
              ? 'Single panel - ${widthMm}mm wide'
              : '$panels panels - each ~${panelWidth.round()}mm wide';
          return CompatibilityResult(
            compatible: true,
            panelCount: panels,
            message: message,
          );
        }
      }

      final String failMessage;
      if (widthMm < product.minWidth) {
        failMessage =
            'Too narrow: ${widthMm}mm (min ${product.minWidth}mm per panel)';
      } else if (product.maxPanelCount <= 1) {
        failMessage =
            'Too wide: ${widthMm}mm exceeds ${product.maxWidth}mm (single panel only)';
      } else {
        failMessage =
            'Cannot fit ${widthMm}mm into 1-${product.maxPanelCount} panels of ${product.minWidth}-${product.maxWidth}mm';
      }
      return CompatibilityResult(
        compatible: false,
        panelCount: 1,
        message: failMessage,
      );
    }

    return const CompatibilityResult(
      compatible: true,
      panelCount: 1,
      message: 'No width set',
    );
  }
}

