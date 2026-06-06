import 'package:flutter/material.dart';

import '../models/house.dart';
import '../services/firestore_service.dart';

/// Home screen: shows every house/customer from Firestore in a live list.
/// This is the top of the navigation - tapping a house will (later) drill in
/// to its rooms.
class HouseListScreen extends StatefulWidget {
  const HouseListScreen({super.key});

  @override
  State<HouseListScreen> createState() => _HouseListScreenState();
}

class _HouseListScreenState extends State<HouseListScreen> {
  final FirestoreService _db = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Houses'),
      ),
      body: StreamBuilder<List<House>>(
        stream: _db.housesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final houses = snapshot.data!;
          if (houses.isEmpty) {
            return const Center(
              child: Text('No houses yet. Tap + to add one.'),
            );
          }

          return ListView.builder(
            itemCount: houses.length,
            itemBuilder: (context, index) {
              final house = houses[index];
              return ListTile(
                leading: const Icon(Icons.home_outlined),
                title: Text(house.name.isEmpty ? '(no name)' : house.name),
                subtitle: house.address.isEmpty ? null : Text(house.address),
              );
            },
          );
        },
      ),
    );
  }
}

