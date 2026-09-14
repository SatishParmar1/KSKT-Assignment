import 'dart:convert';

class TripModel {
  final String tripId;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final double totalDistance;
  final double currentSpeed;
  final double maxSpeed;
  final double? lastLatitude;
  final double? lastLongitude;
  final double? lastAccuracy;
  final bool isSynced;

  TripModel({
    required this.tripId,
    required this.startTime,
    this.endTime,
    required this.status,
    this.totalDistance = 0.0,
    this.currentSpeed = 0.0,
    this.maxSpeed = 0.0,
    this.lastLatitude,
    this.lastLongitude,
    this.lastAccuracy,
    this.isSynced = false,
  });

  TripModel copyWith({
    String? tripId,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    double? totalDistance,
    double? currentSpeed,
    double? maxSpeed,
    double? lastLatitude,
    double? lastLongitude,
    double? lastAccuracy,
    bool? isSynced,
  }) {
    return TripModel(
      tripId: tripId ?? this.tripId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      totalDistance: totalDistance ?? this.totalDistance,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      lastAccuracy: lastAccuracy ?? this.lastAccuracy,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status,
      'totalDistance': totalDistance,
      'currentSpeed': currentSpeed,
      'maxSpeed': maxSpeed,
      'lastLatitude': lastLatitude,
      'lastLongitude': lastLongitude,
      'lastAccuracy': lastAccuracy,
      'isSynced': isSynced,
    };
  }

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      tripId: map['tripId'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      status: map['status'] ?? 'idle',
      totalDistance: (map['totalDistance'] as num?)?.toDouble() ?? 0.0,
      currentSpeed: (map['currentSpeed'] as num?)?.toDouble() ?? 0.0,
      maxSpeed: (map['maxSpeed'] as num?)?.toDouble() ?? 0.0,
      lastLatitude: (map['lastLatitude'] as num?)?.toDouble(),
      lastLongitude: (map['lastLongitude'] as num?)?.toDouble(),
      lastAccuracy: (map['lastAccuracy'] as num?)?.toDouble(),
      isSynced: map['isSynced'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory TripModel.fromJson(String source) => TripModel.fromMap(json.decode(source));
}
