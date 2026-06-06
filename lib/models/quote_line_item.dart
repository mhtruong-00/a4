// One line on the quote (a window or a floor space). Pricing comes from a
// product-rate map (from the API) with default fallbacks, matching my
// Android/iOS quote screens. `isIncluded` is mutable so the quote screen can
// toggle individual items in or out.

enum QuoteItemType { window, floor }

class QuoteLineItem {
  final String id;
  final String roomId;
  final String roomName;
  final QuoteItemType itemType;
  final String itemName;
  final String productId;
  final String productName;
  final String variantName;
  final int widthMm;
  final int heightOrDepthMm;
  final int panelCount;
  final double pricePerSqm;
  bool isIncluded;

  /// True when no product rate was available and a default fallback was used.
  final bool usedDefaultRate;

  QuoteLineItem({
    this.id = '',
    this.roomId = '',
    this.roomName = '',
    this.itemType = QuoteItemType.window,
    this.itemName = '',
    this.productId = '',
    this.productName = '',
    this.variantName = '',
    this.widthMm = 0,
    this.heightOrDepthMm = 0,
    this.panelCount = 1,
    this.pricePerSqm = 0,
    this.isIncluded = true,
    this.usedDefaultRate = false,
  });

  double get areaSqm => (widthMm / 1000.0) * (heightOrDepthMm / 1000.0);

  double get itemPrice => pricePerSqm * areaSqm;

  bool get isWindow => itemType == QuoteItemType.window;

  String get typeLabel => isWindow ? 'Window' : 'Floor';

  String get dimensionLabel {
    final suffix = isWindow ? 'H' : 'D';
    return '${widthMm}W x $heightOrDepthMm$suffix mm';
  }
}

