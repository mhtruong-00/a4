import 'package:flutter/material.dart';

import '../models/room.dart';
import '../services/firestore_service.dart';
import '../widgets/photo_field.dart';

/// Add / edit form for a room. New rooms need the [houseId] they belong to;
/// when [existing] is supplied we are editing that room instead.
class RoomEditScreen extends StatefulWidget {
  const RoomEditScreen({super.key, required this.houseId, this.existing});

  final String houseId;
  final Room? existing;

  bool get isEditing => existing != null;

  @override
  State<RoomEditScreen> createState() => _RoomEditScreenState();
}

class _RoomEditScreenState extends State<RoomEditScreen> {
  final FirestoreService _db = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;

  String? _photoBase64;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _photoBase64 = widget.existing?.photoBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final room = (widget.existing ?? Room(houseId: widget.houseId)).copyWith(
      houseId: widget.houseId,
      name: _nameController.text.trim(),
      photoBase64: _photoBase64 ?? '',
    );

    try {
      if (widget.isEditing) {
        await _db.updateRoom(room);
      } else {
        await _db.addRoom(room);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Room' : 'Add Room'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Room name'),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              PhotoField(
                photoBase64: _photoBase64,
                onChanged: (value) => setState(() => _photoBase64 = value),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save),
                label: Text(_saving ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}










