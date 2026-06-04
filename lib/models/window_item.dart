// Window model. Stored in the top-level Firestore `windows` collection, linked
// to a room by `roomId`. Dimensions are whole millimetres, matching the
// Android/iOS apps so the same database can be shared.
class WindowItem {
  final String id;
  final String roomId;
  final String name;
  final int widthMm;
  final int heightMm;
  final String selectedProductId;
  final String selectedProductName;
  final String selectedProductVariant;
  final int panelCount;
  final String? photoBase64;

  const WindowItem({
    this.id = '',
    this.roomId = '',
    this.name = '',
    this.widthMm = 0,
    this.heightMm = 0,
    this.selectedProductId = '',
    this.selectedProductName = '',
    this.selectedProductVariant = '',
    this.panelCount = 1,
    this.photoBase64,
  });

  /// Area in square metres derived from the millimetre dimensions.
  double get areaSqm => (widthMm / 1000.0) * (heightMm / 1000.0);

  factory WindowItem.fromMap(String id, Map<String, dynamic> data) {
    return WindowItem(
      id: id,
      roomId: (data['roomId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      widthMm: _toInt(data['widthMm']),
      heightMm: _toInt(data['heightMm']),
      selectedProductId: (data['selectedProductId'] as String?) ?? '',
      selectedProductName: (data['selectedProductName'] as String?) ?? '',
      selectedProductVariant:
          (data['selectedProductVariant'] as String?) ?? '',
      panelCount: _toInt(data['panelCount'], fallback: 1),
      photoBase64: _nilIfEmpty(data['photoBase64']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'name': name,
      'widthMm': widthMm,
      'heightMm': heightMm,
      'selectedProductId': selectedProductId,
      'selectedProductName': selectedProductName,
      'selectedProductVariant': selectedProductVariant,
      'panelCount': panelCount,
      'photoBase64': photoBase64 ?? '',
    };
  }

  WindowItem copyWith({
    String? id,
    String? roomId,
    String? name,
    int? widthMm,
    int? heightMm,
    String? selectedProductId,
    String? selectedProductName,
    String? selectedProductVariant,
    int? panelCount,
    String? photoBase64,
  }) {
    return WindowItem(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      selectedProductId: selectedProductId ?? this.selectedProductId,
      selectedProductName: selectedProductName ?? this.selectedProductName,
      selectedProductVariant:
          selectedProductVariant ?? this.selectedProductVariant,
      panelCount: panelCount ?? this.panelCount,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }
}

/// Firestore can return numbers as int, double or String; coerce safely.
int _toInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String? _nilIfEmpty(Object? v) {
  final s = v as String?;
  return (s == null || s.isEmpty) ? null : s;
}

