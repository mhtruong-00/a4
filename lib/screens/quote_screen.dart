import 'package:flutter/material.dart';

import '../models/house.dart';
import '../services/firestore_service.dart';
import '../services/product_api.dart';
import '../services/quote_calculator.dart';

/// Quote screen for a house. Loads the rooms + windows + floor spaces, fetches
/// product rates from the API (falling back to default rates if it's offline),
/// and shows a per-room breakdown with a running total.
class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key, required this.house});

  final House house;

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  final FirestoreService _db = FirestoreService();
  final ProductApi _api = ProductApi();
  final QuoteCalculator _calculator = QuoteCalculator();

  List<RoomQuote> _roomQuotes = [];
  bool _loading = true;
  bool _usingDefaults = false;
  double _discountPercent = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final data = await _db.loadQuoteData(widget.house.id);
    final products = await _api.fetchProducts();

    final rates = <String, double>{};
    for (final p in products) {
      if (p.id.isNotEmpty) rates[p.id] = p.pricePerSqm;
    }

    if (!mounted) return;
    setState(() {
      _usingDefaults = products.isEmpty;
      _roomQuotes = _calculator.buildRoomQuotes(
        rooms: data.rooms,
        windowsByRoom: data.windowsByRoom,
        floorsByRoom: data.floorsByRoom,
        productRates: rates,
      );
      _loading = false;
    });
  }

  String _money(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quote - ${widget.house.name}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _buildList()),
                _summaryCard(),
              ],
            ),
    );
  }

  Widget _buildList() {
    if (_roomQuotes.isEmpty) {
      return const Center(child: Text('No rooms in this house yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _roomQuotes.length,
      itemBuilder: (context, index) => _roomCard(_roomQuotes[index]),
    );
  }

  Widget _roomCard(RoomQuote rq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rq.room.name.isEmpty ? 'Unnamed Room' : rq.room.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: rq.isIncluded,
                  onChanged: (value) => setState(() => rq.isIncluded = value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in rq.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.itemName.isEmpty
                              ? '${item.typeLabel} item'
                              : item.itemName),
                          Text(
                            '${item.typeLabel} · ${item.dimensionLabel}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(_money(item.itemPrice)),
                  ],
                ),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rq.isIncluded
                      ? 'Items ${_money(rq.subtotal)} + Labour '
                          '${_money(rq.labour(QuoteCalculator.roomLabour))}'
                      : 'Room excluded from quote',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  rq.isIncluded
                      ? _money(rq.roomTotal(QuoteCalculator.roomLabour))
                      : '-',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    final subtotal = _calculator.houseSubtotal(_roomQuotes);
    final discount = _calculator.discountAmount(_roomQuotes, _discountPercent);
    final total = _calculator.finalTotal(_roomQuotes, _discountPercent);
    return Material(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_usingDefaults)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Using default rates (\$50 window · \$100 floor) - product '
                  'API unavailable.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text(_money(subtotal)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Discount'),
                const SizedBox(width: 12),
                SizedBox(
                  width: 64,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '0',
                      suffixText: '%',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _discountPercent =
                            (double.tryParse(value) ?? 0).clamp(0, 100);
                      });
                    },
                  ),
                ),
                const Spacer(),
                Text(
                  _discountPercent > 0 ? '-${_money(discount)}' : _money(0),
                  style: TextStyle(
                    color: _discountPercent > 0 ? Colors.orange : null,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('FINAL TOTAL',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  _money(total),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}





