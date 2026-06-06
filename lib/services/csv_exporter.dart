import '../services/quote_calculator.dart';

/// Builds the CSV string that gets shared from the quote screen. The columns
/// match the format my Android and iOS apps export so the files look the same.
class CsvExporter {
  String generateCsv({
    required String houseName,
    required String address,
    required List<RoomQuote> roomQuotes,
    required double discountPercent,
    required bool usingDefaults,
    String notes = '',
  }) {
    final calculator = QuoteCalculator();
    final rows = <String>[];

    rows.add(_row([
      'type', 'house', 'address', 'room',
      'item_type', 'item_name',
      'width_mm', 'height_or_depth_mm',
      'product', 'variant',
      'rate_per_sqm', 'area_sqm', 'item_cost',
      'room_subtotal', 'room_labour', 'room_total', 'included',
    ]));

    for (final rq in roomQuotes) {
      for (final item in rq.items) {
        final includeItem = rq.isIncluded && item.isIncluded;
        final cost = includeItem ? item.itemPrice : 0.0;
        rows.add(_row([
          'item',
          houseName, address,
          rq.room.name.isEmpty ? 'Unnamed Room' : rq.room.name,
          item.isWindow ? 'window' : 'floor',
          item.itemName.isEmpty ? 'Unnamed' : item.itemName,
          '${item.widthMm}', '${item.heightOrDepthMm}',
          item.productName, item.variantName,
          _money(item.pricePerSqm), _money(item.areaSqm), _money(cost),
          '', '', '',
          includeItem ? 'true' : 'false',
        ]));
      }

      final labour = rq.labour(QuoteCalculator.roomLabour);
      final total = rq.roomTotal(QuoteCalculator.roomLabour);
      rows.add(_row([
        'room_total',
        houseName, address,
        rq.room.name.isEmpty ? 'Unnamed Room' : rq.room.name,
        '', '', '', '', '', '', '', '',
        _money(rq.subtotal), _money(labour), _money(total),
        rq.isIncluded ? 'true' : 'false',
      ]));
    }

    final houseSubtotal = calculator.houseSubtotal(roomQuotes);
    final discountAmt = calculator.discountAmount(roomQuotes, discountPercent);
    final finalTotal = calculator.finalTotal(roomQuotes, discountPercent);

    rows.add(_row(['summary', houseName, address, ...List.filled(14, '')]));
    rows.add(_row([
      'subtotal', houseName, address, '', '', '', '', '', '', '', '', '',
      _money(houseSubtotal), '', '', '', '',
    ]));
    rows.add(_row([
      'discount', houseName, address, '', '', '', '', '', '', '', '', '',
      _money(discountAmt), '', '', '', _percent(discountPercent),
    ]));
    rows.add(_row([
      'final_total', houseName, address, '', '', '', '', '', '', '', '', '',
      _money(finalTotal), '', '', '', '',
    ]));

    if (usingDefaults) {
      rows.add(_row([
        'note', houseName, address, '', '', '', '', '',
        'Using default product rates', '', '', '', '', '', '', '', '',
      ]));
    }

    final trimmedNotes = notes.trim();
    if (trimmedNotes.isNotEmpty) {
      rows.add(_row([
        'notes', houseName, address, '', '', '', '', '',
        trimmedNotes, '', '', '', '', '', '', '', '',
      ]));
    }

    return rows.join('\n');
  }

  String _row(List<String> values) => values.map(_escape).join(',');

  String _escape(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n')) {
      return '"$escaped"';
    }
    return escaped;
  }

  String _money(double v) => v.toStringAsFixed(2);
  String _percent(double v) => v.toStringAsFixed(1);
}

