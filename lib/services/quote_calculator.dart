import '../models/floor_space.dart';
import '../models/quote_line_item.dart';
import '../models/room.dart';
import '../models/window_item.dart';

/// Per-room totals built by [QuoteCalculator].
class RoomQuote {
  final Room room;
  final List<QuoteLineItem> items;
  bool isIncluded;

  RoomQuote({
    required this.room,
    required this.items,
    this.isIncluded = true,
  });

  double get subtotal => items
      .where((i) => i.isIncluded)
      .fold(0.0, (sum, i) => sum + i.itemPrice);

  bool get hasMeasuredIncludedItem =>
      items.any((i) => i.isIncluded && i.areaSqm > 0);

  /// Labour only applies if the room is included AND has a measured item.
  double labour(double roomLabour) =>
      (isIncluded && hasMeasuredIncludedItem) ? roomLabour : 0;

  double roomTotal(double roomLabour) =>
      isIncluded ? subtotal + labour(roomLabour) : 0;
}

/// Builds the quote from the saved rooms/windows/floors plus product rates from
/// the API. Defaults match my Android quote screen: $50/window, $100/floor, and
/// a $200 labour charge per measured room. A whole-house % discount is applied
/// at the end.
class QuoteCalculator {
  static const double defaultWindowRate = 50.0;
  static const double defaultFloorRate = 100.0;
  static const double roomLabour = 200.0;

  List<RoomQuote> buildRoomQuotes({
    required List<Room> rooms,
    required Map<String, List<WindowItem>> windowsByRoom,
    required Map<String, List<FloorSpace>> floorsByRoom,
    required Map<String, double> productRates,
  }) {
    return rooms.map((room) {
      final items = <QuoteLineItem>[];

      for (final w in windowsByRoom[room.id] ?? const []) {
        final resolved = _resolveRate(
          w.selectedProductId,
          productRates,
          defaultWindowRate,
        );
        items.add(QuoteLineItem(
          id: w.id,
          roomId: room.id,
          roomName: room.name,
          itemType: QuoteItemType.window,
          itemName: w.name,
          productId: w.selectedProductId,
          productName:
              w.selectedProductName.isEmpty ? 'Basic Window' : w.selectedProductName,
          variantName: w.selectedProductVariant,
          widthMm: w.widthMm,
          heightOrDepthMm: w.heightMm,
          panelCount: w.panelCount,
          pricePerSqm: resolved.rate,
          usedDefaultRate: resolved.isDefault,
        ));
      }

      for (final f in floorsByRoom[room.id] ?? const []) {
        final resolved = _resolveRate(
          f.selectedProductId,
          productRates,
          defaultFloorRate,
        );
        items.add(QuoteLineItem(
          id: f.id,
          roomId: room.id,
          roomName: room.name,
          itemType: QuoteItemType.floor,
          itemName: f.name,
          productId: f.selectedProductId,
          productName:
              f.selectedProductName.isEmpty ? 'Basic Floor' : f.selectedProductName,
          variantName: f.selectedProductVariant,
          widthMm: f.widthMm,
          heightOrDepthMm: f.depthMm,
          pricePerSqm: resolved.rate,
          usedDefaultRate: resolved.isDefault,
        ));
      }

      return RoomQuote(room: room, items: items);
    }).toList();
  }

  double houseSubtotal(List<RoomQuote> roomQuotes) =>
      roomQuotes.fold(0.0, (sum, rq) => sum + rq.roomTotal(roomLabour));

  double discountAmount(List<RoomQuote> roomQuotes, double discountPercent) {
    final sub = houseSubtotal(roomQuotes);
    final d = discountPercent.clamp(0, 100);
    return sub * (d / 100.0);
  }

  double finalTotal(List<RoomQuote> roomQuotes, double discountPercent) {
    final sub = houseSubtotal(roomQuotes);
    final d = discountPercent.clamp(0, 100);
    return sub * (1.0 - d / 100.0);
  }

  _ResolvedRate _resolveRate(
    String productId,
    Map<String, double> rates,
    double defaultRate,
  ) {
    if (productId.isEmpty) return _ResolvedRate(defaultRate, true);
    final rate = rates[productId];
    if (rate != null) return _ResolvedRate(rate, false);
    return _ResolvedRate(defaultRate, true);
  }
}

class _ResolvedRate {
  final double rate;
  final bool isDefault;
  const _ResolvedRate(this.rate, this.isDefault);
}

