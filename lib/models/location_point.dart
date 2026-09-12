import 'dart:convert';

class LocationPoint {
  final String tripId;
  final double latitude;
  final double longitude;
  final double speed;
  final double accuracy;
  final DateTime timestamp;
  final bool isSynced;

  LocationPoint({
    required this.tripId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.accuracy,
    required this.timestamp,
    this.isSynced = false,
  });

  LocationPoint copyWith({
    String? tripId,
    double? latitude,
    double? longitude,
    double? speed,
    double? accuracy,
    DateTime? timestamp,
    bool? isSynced,
  }) {
    return LocationPoint(
      tripId: tripId ?? this.tripId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'accuracy': accuracy,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      tripId: map['tripId'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
      isSynced: map['isSynced'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory LocationPoint.fromJson(String source) =>
      LocationPoint.fromMap(json.decode(source));
}
