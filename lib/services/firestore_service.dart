import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/house.dart';
import '../models/room.dart';
import '../models/window_item.dart';

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

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection('rooms');

  /// Live list of rooms for a single house. The rooms collection is top-level
  /// and linked back to its house with the `houseId` field.
  Stream<List<Room>> roomsStream(String houseId) {
    return _rooms
        .where('houseId', isEqualTo: houseId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Room.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<String> addRoom(Room room) async {
    final ref = await _rooms.add(room.toMap());
    return ref.id;
  }

  Future<void> updateRoom(Room room) {
    return _rooms.doc(room.id).update(room.toMap());
  }

  Future<void> deleteRoom(String id) {
    return _rooms.doc(id).delete();
  }

  CollectionReference<Map<String, dynamic>> get _windows =>
      _db.collection('windows');

  /// Live list of windows in a room.
  Stream<List<WindowItem>> windowsStream(String roomId) {
    return _windows
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WindowItem.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<String> addWindow(WindowItem window) async {
    final ref = await _windows.add(window.toMap());
    return ref.id;
  }

  Future<void> updateWindow(WindowItem window) {
    return _windows.doc(window.id).update(window.toMap());
  }

  Future<void> deleteWindow(String id) {
    return _windows.doc(id).delete();
  }
}





