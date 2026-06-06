import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/house.dart';

/// Small wrapper around Cloud Firestore so my screens don't have to talk to
/// Firestore directly. I started with just the houses collection and will add
/// rooms / windows / floor spaces here as I build those screens.
class FirestoreService {
  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _houses =>
      _db.collection('houses');

  /// Live list of houses, ordered by the customer name so the list is stable.
  Stream<List<House>> housesStream() {
    return _houses.orderBy('customerName').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => House.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Adds a new house and returns the new document id.
  Future<String> addHouse(House house) async {
    final ref = await _houses.add(house.toMap());
    return ref.id;
  }

  Future<void> updateHouse(House house) {
    return _houses.doc(house.id).update(house.toMap());
  }

  Future<void> deleteHouse(String id) {
    return _houses.doc(id).delete();
  }
}

