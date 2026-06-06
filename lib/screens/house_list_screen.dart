import 'package:flutter/material.dart';

import '../models/house.dart';
import '../services/firestore_service.dart';
import 'house_edit_screen.dart';
import 'room_list_screen.dart';

/// Home screen: shows every house/customer from Firestore in a live list.
/// This is the top of the navigation - tapping a house drills in to its rooms,
/// and the edit button opens the house form.
class HouseListScreen extends StatefulWidget {
  const HouseListScreen({super.key});

  @override
  State<HouseListScreen> createState() => _HouseListScreenState();
}

class _HouseListScreenState extends State<HouseListScreen> {
  final FirestoreService _db = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<House> _filter(List<House> houses) {
    if (_search.trim().isEmpty) return houses;
    final q = _search.toLowerCase();
    return houses
        .where((h) =>
            h.name.toLowerCase().contains(q) ||
            h.address.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _addHouse() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const HouseEditScreen(),
      ),
    );
  }

  Future<void> _editHouse(House house) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HouseEditScreen(existing: house),
      ),
    );
  }

  void _openRooms(House house) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RoomListScreen(house: house),
      ),
    );
  }

  Future<bool> _confirmDelete(House house) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete house?'),
        content: Text(
          'This will remove "${house.name}". This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Houses'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search houses',
                border: const OutlineInputBorder(),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      ),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<House>>(
              stream: _db.housesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Something went wrong: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final houses = _filter(snapshot.data!);
                if (houses.isEmpty) {
                  return Center(
                    child: Text(_search.trim().isEmpty
                        ? 'No houses yet. Tap + to add one.'
                        : 'No houses match "$_search".'),
                  );
                }

                return ListView.builder(
                  itemCount: houses.length,
                  itemBuilder: (context, index) {
                    final house = houses[index];
                    return Dismissible(
                      key: ValueKey(house.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) => _confirmDelete(house),
                      onDismissed: (_) => _db.deleteHouse(house.id),
                      child: ListTile(
                        leading: const Icon(Icons.home_outlined),
                        title:
                            Text(house.name.isEmpty ? '(no name)' : house.name),
                        subtitle:
                            house.address.isEmpty ? null : Text(house.address),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit house',
                          onPressed: () => _editHouse(house),
                        ),
                        onTap: () => _openRooms(house),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHouse,
        tooltip: 'Add house',
        child: const Icon(Icons.add),
      ),
    );
  }
}
















