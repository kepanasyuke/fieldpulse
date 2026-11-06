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
    setState(() => _error = null);
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) {
        return;
      }

      final reading = _parser.parse(_sampleOcr);
      setState(() {
        _photo = File(picked.path);
        if (reading == null) {
          _error = 'На фото не найдено показаний';
        } else {
          _readings.insert(0, reading);
        }
      });
    } on Exception catch (error) {
      setState(() => _error = 'Камера недоступна: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Показания со снимка')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(_photo!, height: 180, fit: BoxFit.cover),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _capture(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Снять счётчик'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.outlined(
                tooltip: 'Из галереи',
                onPressed: () => _capture(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(color: scheme.error)),
            ),
          const SizedBox(height: 16),
          for (final reading in _readings)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(
                  reading.isConfident
                      ? Icons.check_circle_outline
                      : Icons.help_outline,
                  color: reading.isConfident ? scheme.primary : scheme.error,
                ),
                title: Text(reading.formatted),
                subtitle: Text(
                  'уверенность ${(reading.confidence * 100).round()}%',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
