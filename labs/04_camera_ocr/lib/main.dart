import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lab_camera_ocr/src/reading_parser.dart';

const String _sampleOcr = 'Счётчик 12 345,6 кВт·ч\nПоказания на 01.11.2026';

void main() => runApp(const CameraOcrApp());

class CameraOcrApp extends StatelessWidget {
  const CameraOcrApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Lab 04 · Camera + OCR',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEA8600)),
    ),
    home: const CapturePage(),
  );
}

class CapturePage extends StatefulWidget {
  const CapturePage({super.key});

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  final ImagePicker _picker = ImagePicker();
  final ReadingParser _parser = const ReadingParser();
  final List<MeterReading> _readings = [];
  File? _photo;
  String? _error;

  Future<void> _capture(ImageSource source) async {
    _showError(null);
    try {
      final photo = await _pick(source);
      if (photo != null) {
        _applyPhoto(photo);
      }
    } on Exception catch (error) {
      _showError('Камера недоступна: $error');
    }
  }

  Future<File?> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );

    return picked == null ? null : File(picked.path);
  }

  void _applyPhoto(File photo) {
    final reading = _parser.parse(_sampleOcr);
    setState(() {
      _photo = photo;
      _error = reading == null ? 'На фото не найдено показаний' : null;
      if (reading != null) {
        _readings.insert(0, reading);
      }
    });
  }

  void _showError(String? message) => setState(() => _error = message);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Показания со снимка')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_photo != null) _PhotoPreview(photo: _photo!),
          const SizedBox(height: 12),
          _CaptureActions(onCapture: _capture),
          if (_error != null) _ErrorLabel(message: _error!),
          const SizedBox(height: 16),
          for (final reading in _readings) _ReadingTile(reading: reading),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photo});

  final File photo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.file(photo, height: 180, fit: BoxFit.cover),
    );
  }
}

class _CaptureActions extends StatelessWidget {
  const _CaptureActions({required this.onCapture});

  final Future<void> Function(ImageSource source) onCapture;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => onCapture(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Снять счётчик'),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.outlined(
          tooltip: 'Из галереи',
          onPressed: () => onCapture(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
        ),
      ],
    );
  }
}

class _ErrorLabel extends StatelessWidget {
  const _ErrorLabel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({required this.reading});

  final MeterReading reading;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(_icon, color: _iconColor(context)),
        title: Text(reading.formatted),
        subtitle: Text('уверенность ${(reading.confidence * 100).round()}%'),
      ),
    );
  }

  IconData get _icon =>
      reading.isConfident ? Icons.check_circle_outline : Icons.help_outline;

  Color _iconColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return reading.isConfident ? scheme.primary : scheme.error;
  }
}
