// House model. Stored in the top-level Firestore `houses` collection.
// The customer/house name is stored in Firestore under `customerName` so this
// app shares the same schema as my Assignment 2/3 apps.
class House {
  final String id;
  final String name; // stored in Firestore as "customerName"
  final String address;
  final String notes;

  const House({
    this.id = '',
    this.name = '',
    this.address = '',
    this.notes = '',
  });

  factory House.fromMap(String id, Map<String, dynamic> data) {
    return House(
      id: id,
      name: (data['customerName'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      notes: (data['notes'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerName': name,
      'address': address,
      'notes': notes,
    };
  }

  House copyWith({String? id, String? name, String? address, String? notes}) {
    return House(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      notes: notes ?? this.notes,
    );
  }
}

