import 'dart:isolate';

class PayloadDecoder {
  const PayloadDecoder();

  Future<T> decode<T>(String rawBody, T Function(String body) parser) =>
      Isolate.run(() => parser(rawBody));
}
