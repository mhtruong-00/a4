import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/floor_space.dart';
import '../models/house.dart';
import '../models/room.dart';
import '../models/window_item.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import 'floor_space_edit_screen.dart';
import 'room_edit_screen.dart';
import 'window_edit_screen.dart';

/// Shows one room's windows and floor spaces in two sections. This is where the
/// surveyor adds the actual items that get priced on the quote.
class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({super.key, required this.house, required this.room});

  final House house;
  final Room room;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final FirestoreService _db = FirestoreService();

  void _addWindow() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => WindowEditScreen(roomId: widget.room.id),
    ));
  }

  void _editWindow(WindowItem window) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => WindowEditScreen(roomId: widget.room.id, existing: window),
    ));
  }

  void _addFloor() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => FloorSpaceEditScreen(roomId: widget.room.id),
    ));
  }

  void _editFloor(FloorSpace floor) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) =>
          FloorSpaceEditScreen(roomId: widget.room.id, existing: floor),
    ));
  }

  void _editRoom() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) =>
          RoomEditScreen(houseId: widget.house.id, existing: widget.room),
    ));
  }

  Future<bool> _confirmDelete(String what) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $what?'),
        content: Text('This will remove this $what. This cannot be undone.'),
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
        title: Text(widget.room.name.isEmpty ? 'Room' : widget.room.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit room',
            onPressed: _editRoom,
          ),
        ],
      ),
      body: ListView(
        children: [
          if (widget.room.photoBase64 != null) _roomPhoto(),
          _windowsSection(),
          const Divider(height: 1),
          _floorsSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _roomPhoto() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          base64Decode(widget.room.photoBase64!),
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, VoidCallback onAdd, String addLabel,
      Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(addLabel),
            style: TextButton.styleFrom(foregroundColor: color),
          ),
        ],
      ),
    );
  }

  Widget _windowsSection() {
    return StreamBuilder<List<WindowItem>>(
      stream: _db.windowsStream(widget.room.id),
      builder: (context, snapshot) {
        final windows = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeader(
              windows.isEmpty ? 'Windows (none)' : 'Windows (${windows.length})',
              _addWindow,
              'Add Window',
              AppColors.windowTint,
            ),
            if (windows.isEmpty) _emptyHint('No windows added yet.'),
            for (final window in windows)
              Dismissible(
                key: ValueKey('w_${window.id}'),
                direction: DismissDirection.endToStart,
                background: _deleteBackground(),
                confirmDismiss: (_) => _confirmDelete('window'),
                onDismissed: (_) => _db.deleteWindow(window.id),
                child: ListTile(
                  leading: const Icon(Icons.window_outlined,
                      color: AppColors.windowTint),
                  title: Text(window.name.isEmpty ? 'Unnamed' : window.name),
                  subtitle: Text(_windowSubtitle(window)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editWindow(window),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _floorsSection() {
    return StreamBuilder<List<FloorSpace>>(
      stream: _db.floorSpacesStream(widget.room.id),
      builder: (context, snapshot) {
        final floors = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeader(
              floors.isEmpty
                  ? 'Floor Spaces (none)'
                  : 'Floor Spaces (${floors.length})',
              _addFloor,
              'Add Floor Space',
              AppColors.floorTint,
            ),
            if (floors.isEmpty) _emptyHint('No floor spaces added yet.'),
            for (final floor in floors)
              Dismissible(
                key: ValueKey('f_${floor.id}'),
                direction: DismissDirection.endToStart,
                background: _deleteBackground(),
                confirmDismiss: (_) => _confirmDelete('floor space'),
                onDismissed: (_) => _db.deleteFloorSpace(floor.id),
                child: ListTile(
                  leading: const Icon(Icons.grid_on_outlined,
                      color: AppColors.floorTint),
                  title: Text(floor.name.isEmpty ? 'Unnamed' : floor.name),
                  subtitle: Text(_floorSubtitle(floor)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editFloor(floor),
                ),
              ),
          ],
        );
      },
    );
  }

  String _windowSubtitle(WindowItem w) {
    final dims = '${w.widthMm}W x ${w.heightMm}H mm';
    final panels = w.panelCount > 1 ? ' · ${w.panelCount} panels' : '';
    if (w.selectedProductName.isEmpty) return '$dims$panels';
    return '$dims · ${w.selectedProductName}$panels';
  }

  String _floorSubtitle(FloorSpace f) {
    final dims = '${f.widthMm}W x ${f.depthMm}D mm';
    if (f.selectedProductName.isEmpty) return dims;
    return '$dims · ${f.selectedProductName}';
  }

  Widget _deleteBackground() {
    return Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 16),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Widget _emptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Theme.of(context).disabledColor),
      ),
    );
  }
}









