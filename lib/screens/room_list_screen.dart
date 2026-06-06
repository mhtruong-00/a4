import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/house.dart';
import '../models/room.dart';
import '../services/firestore_service.dart';
import 'quote_screen.dart';
import 'room_detail_screen.dart';
import 'room_edit_screen.dart';

/// Shows the rooms that belong to one house. Reached by tapping a house on the
/// home screen.
class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key, required this.house});

  final House house;

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  final FirestoreService _db = FirestoreService();

  Future<void> _addRoom() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RoomEditScreen(houseId: widget.house.id),
      ),
    );
  }

  Future<void> _editRoom(Room room) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RoomEditScreen(
          houseId: widget.house.id,
          existing: room,
        ),
      ),
    );
  }

  void _openRoom(Room room) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RoomDetailScreen(house: widget.house, room: room),
      ),
    );
  }

  Future<void> _duplicateRoom(Room room) async {
    try {
      await _db.duplicateRoom(room);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duplicated "${room.name}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not duplicate: $e')),
        );
      }
    }
  }

  void _openQuote() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuoteScreen(house: widget.house),
      ),
    );
  }

  Future<bool> _confirmDelete(Room room) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete room?'),
        content: Text(
          'This will remove "${room.name}". This cannot be undone.',
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
        title: Text(widget.house.name.isEmpty ? 'Rooms' : widget.house.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'View quote',
            onPressed: _openQuote,
          ),
        ],
      ),
      body: StreamBuilder<List<Room>>(
        stream: _db.roomsStream(widget.house.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data!;
          if (rooms.isEmpty) {
            return const Center(
              child: Text('No rooms yet. Tap + to add one.'),
            );
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Dismissible(
                key: ValueKey(room.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) => _confirmDelete(room),
                onDismissed: (_) => _db.deleteRoom(room.id),
                child: ListTile(
                  leading: _thumbnail(room),
                  title: Text(room.name.isEmpty ? '(no name)' : room.name),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editRoom(room);
                      } else if (value == 'duplicate') {
                        _duplicateRoom(room);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                          value: 'duplicate', child: Text('Duplicate')),
                    ],
                  ),
                  onTap: () => _openRoom(room),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRoom,
        tooltip: 'Add room',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Tiny preview of the room photo if one was saved, otherwise a placeholder.
  Widget _thumbnail(Room room) {
    if (room.photoBase64 != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          base64Decode(room.photoBase64!),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    }
    return const Icon(Icons.meeting_room_outlined);
  }
}














