import 'dart:math';

final Random _random = Random.secure();

String newRequestId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(0xFFFFFF).toRadixString(16)}';
