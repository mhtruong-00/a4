import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

/// Talks to the KIT305 product API. Same endpoint my iOS/Android apps used.
/// Pass a [category] ("window" or "floor") to filter, or leave it null to get
/// everything (used by the quote screen to build a price lookup).
class ProductApi {
  ProductApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://utasbot.dev/kit305_2026/product';

  Future<List<Product>> fetchProducts({String? category}) async {
    final query = <String, String>{};
    if (category != null && category.isNotEmpty) {
      query['category'] = category;
    }
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: query.isEmpty ? null : query,
    );

    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return [];
      }
      return _parseProducts(response.body);
    } catch (_) {
      // Network/parse errors just mean "no products" - the quote screen then
      // falls back to its default rates.
      return [];
    }
  }

  /// The API sometimes returns a bare array and sometimes wraps it in
  /// `{ "data": [...] }`, so handle both.
  List<Product> _parseProducts(String body) {
    final dynamic raw = jsonDecode(body);
    List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map<String, dynamic> && raw['data'] is List) {
      list = raw['data'] as List<dynamic>;
    } else {
      return [];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .whereType<Product>()
        .toList();
  }
}

