class MeterReading {
  const MeterReading({
    required this.value,
    required this.unit,
    required this.confidence,
  });

  final double value;
  final String unit;
  final double confidence;

  bool get isConfident => confidence >= 0.8;

  String get formatted => unit.isEmpty
      ? value.toStringAsFixed(0)
      : '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} $unit';

  @override
  String toString() => 'MeterReading($formatted, confidence=$confidence)';
}

class ReadingParser {
  const ReadingParser();

  static final RegExp _digits = RegExp(r'\d[\d\s\u00A0]*[.,]?\d*');

  MeterReading? parse(String ocrText) {
    final normalized = ocrText.toLowerCase().replaceAll('\u00A0', ' ');
    final match = _digits.firstMatch(normalized);
    if (match == null) {
      return null;
    }

    final raw = match.group(0)!.replaceAll(' ', '').replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null) {
      return null;
    }

    final unit = _unitOf(normalized);
    final hasDigitsBlock = RegExp(r'\d{4,}').hasMatch(raw.replaceAll('.', ''));
    final confidence = switch ((unit.isNotEmpty, hasDigitsBlock)) {
      (true, true) => 0.95,
      (true, false) => 0.85,
      (false, true) => 0.7,
      (false, false) => 0.55,
    };

    return MeterReading(value: value, unit: unit, confidence: confidence);
  }

  String _unitOf(String text) {
    if (text.contains('квт')) {
      return 'кВт·ч';
    }
    if (text.contains('м3') || text.contains('м³') || text.contains('куб')) {
      return 'м³';
    }
    return '';
  }
}
