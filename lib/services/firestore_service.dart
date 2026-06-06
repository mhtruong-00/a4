import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/floor_space.dart';
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
      final rooms = snapshot.docs
          .map((doc) => Room.fromMap(doc.id, doc.data()))
          .toList();
      rooms.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return rooms;
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
      final windows = snapshot.docs
          .map((doc) => WindowItem.fromMap(doc.id, doc.data()))
          .toList();
      windows.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return windows;
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

  CollectionReference<Map<String, dynamic>> get _floorSpaces =>
      _db.collection('floorspaces');

  /// Live list of floor spaces in a room.
  Stream<List<FloorSpace>> floorSpacesStream(String roomId) {
    return _floorSpaces
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map((snapshot) {
      final floors = snapshot.docs
          .map((doc) => FloorSpace.fromMap(doc.id, doc.data()))
          .toList();
      floors.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return floors;
    });
  }

  Future<String> addFloorSpace(FloorSpace floor) async {
    final ref = await _floorSpaces.add(floor.toMap());
    return ref.id;
  }

  Future<void> updateFloorSpace(FloorSpace floor) {
    return _floorSpaces.doc(floor.id).update(floor.toMap());
  }

  Future<void> deleteFloorSpace(String id) {
    return _floorSpaces.doc(id).delete();
  }

  /// Loads everything the quote screen needs for a house in one go: the rooms,
  /// and the windows + floor spaces grouped by room id.
  Future<QuoteData> loadQuoteData(String houseId) async {
    final roomsSnap = await _rooms.where('houseId', isEqualTo: houseId).get();
    final rooms = roomsSnap.docs
        .map((d) => Room.fromMap(d.id, d.data()))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final windowsByRoom = <String, List<WindowItem>>{};
    final floorsByRoom = <String, List<FloorSpace>>{};

    for (final room in rooms) {
      final wSnap = await _windows.where('roomId', isEqualTo: room.id).get();
      windowsByRoom[room.id] =
          wSnap.docs.map((d) => WindowItem.fromMap(d.id, d.data())).toList();

      final fSnap =
          await _floorSpaces.where('roomId', isEqualTo: room.id).get();
      floorsByRoom[room.id] =
          fSnap.docs.map((d) => FloorSpace.fromMap(d.id, d.data())).toList();
    }

    return QuoteData(
      rooms: rooms,
      windowsByRoom: windowsByRoom,
      floorsByRoom: floorsByRoom,
    );
  }
}

/// Bundle of the data the quote screen loads for a house.
class QuoteData {
  final List<Room> rooms;
  final Map<String, List<WindowItem>> windowsByRoom;
  final Map<String, List<FloorSpace>> floorsByRoom;

  const QuoteData({
    required this.rooms,
    required this.windowsByRoom,
    required this.floorsByRoom,
  });
}











