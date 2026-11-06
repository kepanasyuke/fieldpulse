import 'dart:io';

import 'package:flutter/material.dart';

import 'package:fieldpulse/features/orders/domain/entities/order.dart';

class PhotoStrip extends StatelessWidget {
  const PhotoStrip({super.key, required this.photos, this.onAdd});

  final List<OrderPhoto> photos;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty && onAdd == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: photos.length + (onAdd != null ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => index == photos.length
            ? _AddPhotoTile(onTap: onAdd!)
            : _PhotoTile(photo: photos[index]),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo});

  final OrderPhoto photo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final file = photo.localPath == null ? null : File(photo.localPath!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: 92,
        child: DecoratedBox(
          decoration: BoxDecoration(color: scheme.surfaceContainerHighest),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo.isUploaded)
                Image.network(
                  photo.url,
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                  errorBuilder: (context, error, stack) => Icon(
                    Icons.broken_image_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else if (file != null)
                Image.file(file, fit: BoxFit.cover, cacheWidth: 300)
              else
                Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
              if (!photo.isUploaded)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: 16,
                    color: scheme.tertiary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Icon(Icons.add_a_photo_outlined, color: scheme.primary),
      ),
    );
  }
}
