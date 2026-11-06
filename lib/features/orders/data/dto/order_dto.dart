import 'package:fieldpulse/core/models/coordinates.dart';

class OrderPhotoDto {
  const OrderPhotoDto({
    required this.id,
    required this.url,
    required this.capturedAt,
  });

  final String id;
  final String url;
  final DateTime capturedAt;

  factory OrderPhotoDto.fromJson(Map<String, dynamic> json) => OrderPhotoDto(
    id: json['id'] as String? ?? '',
    url: json['url'] as String? ?? '',
    capturedAt: _parseDate(json['captured_at']) ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'captured_at': capturedAt.toUtc().toIso8601String(),
  };
}

class OrderDto {
  const OrderDto({
    required this.id,
    required this.number,
    required this.title,
    required this.customer,
    required this.address,
    required this.status,
    required this.priority,
    required this.updatedAt,
    this.slaDueAt,
    this.coordinates,
    this.comment,
    this.photos = const [],
  });

  final String id;
  final String number;
  final String title;
  final String customer;
  final String address;
  final String status;
  final String priority;
  final DateTime updatedAt;
  final DateTime? slaDueAt;
  final Coordinates? coordinates;
  final String? comment;
  final List<OrderPhotoDto> photos;

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final photos = json['photos'];

    return OrderDto(
      id: json['id'] as String? ?? '',
      number: json['number'] as String? ?? '',
      title: json['title'] as String? ?? '',
      customer: json['customer'] as String? ?? '',
      address: json['address'] as String? ?? '',
      status: json['status'] as String? ?? 'created',
      priority: json['priority'] as String? ?? 'normal',
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
      slaDueAt: _parseDate(json['sla_due_at']),
      coordinates: location is Map ? _coordinates(location) : null,
      comment: json['comment'] as String?,
      photos: photos is List
          ? photos
                .whereType<Map<String, dynamic>>()
                .map(OrderPhotoDto.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'title': title,
    'customer': customer,
    'address': address,
    'status': status,
    'priority': priority,
    'updated_at': updatedAt.toUtc().toIso8601String(),
    if (slaDueAt != null) 'sla_due_at': slaDueAt!.toUtc().toIso8601String(),
    if (coordinates != null)
      'location': {
        'lat': coordinates!.latitude,
        'lng': coordinates!.longitude,
        if (coordinates!.accuracyMeters != null)
          'accuracy': coordinates!.accuracyMeters,
      },
    if (comment != null) 'comment': comment,
    if (photos.isNotEmpty)
      'photos': photos.map((photo) => photo.toJson()).toList(growable: false),
  };
}

Coordinates? _coordinates(Map<dynamic, dynamic> location) {
  final lat = _toDouble(location['lat']);
  final lng = _toDouble(location['lng']);
  if (lat == null || lng == null) {
    return null;
  }
  return Coordinates(
    latitude: lat,
    longitude: lng,
    accuracyMeters: _toDouble(location['accuracy']),
  );
}

double? _toDouble(Object? value) => switch (value) {
  final num number => number.toDouble(),
  final String text => double.tryParse(text),
  _ => null,
};

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
