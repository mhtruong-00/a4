// Floor space model. Stored in the top-level Firestore `floorspaces`
// collection, linked to a room by `roomId`. Uses width x depth (mm).
class FloorSpace {
  final String id;
  final String roomId;
  final String name;
  final int widthMm;
  final int depthMm;
  final String selectedProductId;
  final String selectedProductName;
  final String selectedProductVariant;
  final String? photoBase64;

  const FloorSpace({
    this.id = '',
    this.roomId = '',
    this.name = '',
    this.widthMm = 0,
    this.depthMm = 0,
    this.selectedProductId = '',
    this.selectedProductName = '',
    this.selectedProductVariant = '',
    this.photoBase64,
  });

  /// Area in square metres derived from the millimetre dimensions.
  double get areaSqm => (widthMm / 1000.0) * (depthMm / 1000.0);

  factory FloorSpace.fromMap(String id, Map<String, dynamic> data) {
    return FloorSpace(
      id: id,
      roomId: (data['roomId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      widthMm: _toInt(data['widthMm']),
      depthMm: _toInt(data['depthMm']),
      selectedProductId: (data['selectedProductId'] as String?) ?? '',
      selectedProductName: (data['selectedProductName'] as String?) ?? '',
      selectedProductVariant:
          (data['selectedProductVariant'] as String?) ?? '',
      photoBase64: _nilIfEmpty(data['photoBase64']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'name': name,
      'widthMm': widthMm,
      'depthMm': depthMm,
      'selectedProductId': selectedProductId,
      'selectedProductName': selectedProductName,
      'selectedProductVariant': selectedProductVariant,
      'photoBase64': photoBase64 ?? '',
    };
  }

  FloorSpace copyWith({
    String? id,
    String? roomId,
    String? name,
    int? widthMm,
    int? depthMm,
    String? selectedProductId,
    String? selectedProductName,
    String? selectedProductVariant,
    String? photoBase64,
  }) {
    return FloorSpace(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      widthMm: widthMm ?? this.widthMm,
      depthMm: depthMm ?? this.depthMm,
      selectedProductId: selectedProductId ?? this.selectedProductId,
      selectedProductName: selectedProductName ?? this.selectedProductName,
      selectedProductVariant:
          selectedProductVariant ?? this.selectedProductVariant,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }
}

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

