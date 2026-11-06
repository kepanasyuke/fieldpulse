import 'package:flutter_test/flutter_test.dart';

import 'package:lab_camera_ocr/src/reading_parser.dart';

void main() {
  const parser = ReadingParser();

  group('ReadingParser', () {
    test('разбирает показания с единицей и пробелом-разделителем', () {
      final reading = parser.parse('Счётчик 12 345,6 кВт·ч');

      expect(reading, isNotNull);
      expect(reading!.value, 12345.6);
      expect(reading.unit, 'кВт·ч');
      expect(reading.isConfident, isTrue);
    });

    test('понимает кубометры', () {
      final reading = parser.parse('Показания: 00412 м3');

      expect(reading?.value, 412);
      expect(reading?.unit, 'м³');
    });

    test('без единицы уверенность ниже порога', () {
      final reading = parser.parse('1234');

      expect(reading?.unit, '');
      expect(reading?.isConfident, isFalse);
    });

    test('возвращает null, если цифр нет', () {
      expect(parser.parse('сфотографируйте счётчик'), isNull);
    });

    test('текст без чисел после нормализации не ломает парсер', () {
      expect(parser.parse('   '), isNull);
    });

    test('форматирование округляет дробную часть', () {
      final reading = parser.parse('12,75 кВт');

      expect(reading?.formatted, '12.8 кВт·ч');
    });
  });
}
