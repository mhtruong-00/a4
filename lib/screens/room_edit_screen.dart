import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/room.dart';
import '../services/firestore_service.dart';
import '../services/image_helper.dart';

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
  final ImageHelper _imageHelper = ImageHelper();
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

  Future<void> _pickPhoto() async {
    final base64 = await _imageHelper.pickFromGalleryAsBase64();
    if (base64 != null) {
      setState(() => _photoBase64 = base64);
    }
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
              _photoSection(),
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

  /// Photo preview + the gallery picker button. Shows a placeholder box until a
  /// photo is chosen.
  Widget _photoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: _photoBase64 == null
                ? const Center(
                    child: Icon(Icons.image_outlined,
                        size: 48, color: Colors.grey),
                  )
                : Image.memory(base64Decode(_photoBase64!), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Pick from gallery'),
              ),
            ),
            if (_photoBase64 != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Remove photo',
                onPressed: () => setState(() => _photoBase64 = null),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
      ],
    );
  }
}






