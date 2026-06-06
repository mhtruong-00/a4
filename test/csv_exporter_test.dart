// Unit tests for the CSV export. Builds a small quote and checks the CSV has
// the expected header, item row and totals.
import 'package:flutter_test/flutter_test.dart';

import 'package:a4kit305/models/room.dart';
import 'package:a4kit305/models/window_item.dart';
import 'package:a4kit305/services/csv_exporter.dart';
import 'package:a4kit305/services/quote_calculator.dart';

void main() {
  test('CSV has the header, item and totals', () {
    final calc = QuoteCalculator();
    const rooms = [Room(id: 'r1', name: 'Lounge')];
    const windows = <String, List<WindowItem>>{
      'r1': [
        WindowItem(
          id: 'w1',
          roomId: 'r1',
          name: 'Bay',
          widthMm: 1000,
          heightMm: 2000,
          selectedProductId: 'p1',
          selectedProductName: 'Roller Blind',
        ),
      ],
    };

    final quotes = calc.buildRoomQuotes(
      rooms: rooms,
      windowsByRoom: windows,
      floorsByRoom: const {},
      productRates: const {'p1': 50},
    );

    final csv = CsvExporter().generateCsv(
      houseName: 'Smith',
      address: '1 Main St',
      roomQuotes: quotes,
      discountPercent: 10,
      usingDefaults: false,
    );

    final lines = csv.split('\n');
    expect(lines.first.startsWith('type,house,address'), isTrue);
    expect(csv.contains('Smith'), isTrue);
    expect(csv.contains('Roller Blind'), isTrue);
    expect(csv.contains('final_total'), isTrue);
    // Subtotal $300 with 10% discount => $270.00 final total.
    expect(csv.contains('270.00'), isTrue);
  });
}

