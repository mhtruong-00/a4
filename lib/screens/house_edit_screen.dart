import 'package:flutter/material.dart';

import '../models/house.dart';
import '../services/firestore_service.dart';

/// Add / edit form for a house. If [existing] is null we are adding a new
/// house, otherwise we are editing the one that was passed in.
class HouseEditScreen extends StatefulWidget {
  const HouseEditScreen({super.key, this.existing});

  final House? existing;

  bool get isEditing => existing != null;

  @override
  State<HouseEditScreen> createState() => _HouseEditScreenState();
}

class _HouseEditScreenState extends State<HouseEditScreen> {
  final FirestoreService _db = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final house = widget.existing;
    _nameController = TextEditingController(text: house?.name ?? '');
    _addressController = TextEditingController(text: house?.address ?? '');
    _notesController = TextEditingController(text: house?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final house = (widget.existing ?? const House()).copyWith(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      notes: _notesController.text.trim(),
    );

    try {
      if (widget.isEditing) {
        await _db.updateHouse(house);
      } else {
        await _db.addHouse(house);
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
        title: Text(widget.isEditing ? 'Edit House' : 'Add House'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer / house name',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
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
      ),
    );
  }
}


