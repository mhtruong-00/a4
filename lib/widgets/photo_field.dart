import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/image_helper.dart';

/// Reusable photo control: shows a preview (or a placeholder), a "pick from
/// gallery" button, and a remove button. Used by the room, window and floor
/// space editors so the photo UI is written once.
class PhotoField extends StatelessWidget {
  PhotoField({super.key, required this.photoBase64, required this.onChanged});

  /// Current photo as base64, or null when there's none.
  final String? photoBase64;

  /// Called with the new base64 when a photo is picked, or null when removed.
  final ValueChanged<String?> onChanged;

  final ImageHelper _imageHelper = ImageHelper();

  Future<void> _pick() async {
    final base64 = await _imageHelper.pickFromGalleryAsBase64();
    if (base64 != null) onChanged(base64);
  }

  @override
  Widget build(BuildContext context) {
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
            child: photoBase64 == null
                ? const Center(
                    child: Icon(Icons.image_outlined,
                        size: 48, color: Colors.grey),
                  )
                : Image.memory(base64Decode(photoBase64!), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pick,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Pick from gallery'),
              ),
            ),
            if (photoBase64 != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Remove photo',
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

