// Room model. Stored in the top-level Firestore `rooms` collection, linked to a
// house by `houseId`. Photo is stored inline as a base64 JPEG string.
class Room {
  final String id;
  final String houseId;
  final String name;
  final String? photoBase64;
  final String? photoUrl;

  const Room({
    this.id = '',
    this.houseId = '',
    this.name = '',
    this.photoBase64,
    this.photoUrl,
  });

  factory Room.fromMap(String id, Map<String, dynamic> data) {
    String? nilIfEmpty(Object? v) {
      final s = v as String?;
      return (s == null || s.isEmpty) ? null : s;
    }

    return Room(
      id: id,
      houseId: (data['houseId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      photoBase64: nilIfEmpty(data['photoBase64']),
      photoUrl: nilIfEmpty(data['photoUrl']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'houseId': houseId,
      'name': name,
      'photoBase64': photoBase64 ?? '',
      'photoUrl': photoUrl ?? '',
    };
  }

  Room copyWith({
    String? id,
    String? houseId,
    String? name,
    String? photoBase64,
    String? photoUrl,
  }) {
    return Room(
      id: id ?? this.id,
      houseId: houseId ?? this.houseId,
      name: name ?? this.name,
      photoBase64: photoBase64 ?? this.photoBase64,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

