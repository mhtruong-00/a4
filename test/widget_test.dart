// Unit tests for the quote calculation logic. These don't touch Firebase or the
// UI, they just check the maths in QuoteCalculator behaves like the Android/iOS
// apps (default rates, $200 room labour, and the whole-house discount).
import 'package:a4kit305/models/floor_space.dart';
import 'package:a4kit305/models/room.dart';
import 'package:a4kit305/models/window_item.dart';
import 'package:a4kit305/services/quote_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final calc = QuoteCalculator();

  group('QuoteCalculator', () {
    test('window uses the product rate and adds room labour', () {
      const rooms = [Room(id: 'r1', name: 'Lounge')];
      const windows = <String, List<WindowItem>>{
        'r1': [
          WindowItem(
            id: 'w1',
            roomId: 'r1',
            widthMm: 1000,
            heightMm: 2000,
            selectedProductId: 'p1',
          ),
        ],
      };

      final quotes = calc.buildRoomQuotes(
        rooms: rooms,
        windowsByRoom: windows,
        floorsByRoom: const {},
        productRates: const {'p1': 50},
      );

      // 2 sqm * $50 = $100 of items, then +$200 labour = $300.
      expect(quotes.single.subtotal, 100);
      expect(quotes.single.roomTotal(QuoteCalculator.roomLabour), 300);
    });

    test('falls back to the default window rate when no product set', () {
      const rooms = [Room(id: 'r1')];
      const windows = <String, List<WindowItem>>{
        'r1': [WindowItem(id: 'w1', roomId: 'r1', widthMm: 1000, heightMm: 1000)],
      };

      final quotes = calc.buildRoomQuotes(
        rooms: rooms,
        windowsByRoom: windows,
        floorsByRoom: const {},
        productRates: const {},
      );

      // 1 sqm * default $50 = $50 + $200 labour = $250.
      expect(quotes.single.roomTotal(QuoteCalculator.roomLabour), 250);
      expect(quotes.single.items.single.usedDefaultRate, isTrue);
    });

    test('discount reduces the final total', () {
      const rooms = [Room(id: 'r1')];
      const floors = <String, List<FloorSpace>>{
        'r1': [
          FloorSpace(
            id: 'f1',
            roomId: 'r1',
            widthMm: 1000,
            depthMm: 1000,
            selectedProductId: 'p2',
          ),
        ],
      };

      final quotes = calc.buildRoomQuotes(
        rooms: rooms,
        windowsByRoom: const {},
        floorsByRoom: floors,
        productRates: const {'p2': 100},
      );

      // 1 sqm * $100 = $100 + $200 labour = $300 subtotal.
      expect(calc.houseSubtotal(quotes), 300);
      expect(calc.discountAmount(quotes, 10), 30);
      expect(calc.finalTotal(quotes, 10), 270);
    });

    test('an excluded room contributes nothing', () {
      const rooms = [Room(id: 'r1')];
      const windows = <String, List<WindowItem>>{
        'r1': [
          WindowItem(
            id: 'w1',
            roomId: 'r1',
            widthMm: 1000,
            heightMm: 1000,
            selectedProductId: 'p1',
          ),
        ],
      };

      final quotes = calc.buildRoomQuotes(
        rooms: rooms,
        windowsByRoom: windows,
        floorsByRoom: const {},
        productRates: const {'p1': 50},
      );
      quotes.single.isIncluded = false;

      expect(calc.houseSubtotal(quotes), 0);
    });

    test('discount is clamped to the 0-100 range', () {
      const rooms = [Room(id: 'r1')];
      const floors = <String, List<FloorSpace>>{
        'r1': [
          FloorSpace(
            id: 'f1',
            roomId: 'r1',
            widthMm: 1000,
            depthMm: 1000,
            selectedProductId: 'p2',
          ),
        ],
      };
      final quotes = calc.buildRoomQuotes(
        rooms: rooms,
        windowsByRoom: const {},
        floorsByRoom: floors,
        productRates: const {'p2': 100},
      );
      // Subtotal is $300. Over-100% clamps to 100% (total 0); negative to 0%.
      expect(calc.finalTotal(quotes, 150), 0);
      expect(calc.finalTotal(quotes, -5), 300);
    });
  });
}
