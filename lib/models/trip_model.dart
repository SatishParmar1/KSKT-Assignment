import 'dart:convert';

class TripModel {
  final String tripId;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final double totalDistance;
  final double currentSpeed;
  final double maxSpeed;
  final double averageSpeed;
  final int totalLocations;
  final int rejectedLocations;
  final bool isSynced;

  TripModel({
    required this.tripId,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.totalDistance,
    required this.currentSpeed,
    required this.maxSpeed,
    required this.averageSpeed,
    required this.totalLocations,
    required this.rejectedLocations,
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
    double? averageSpeed,
    int? totalLocations,
    int? rejectedLocations,
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
      averageSpeed: averageSpeed ?? this.averageSpeed,
      totalLocations: totalLocations ?? this.totalLocations,
      rejectedLocations: rejectedLocations ?? this.rejectedLocations,
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
      'averageSpeed': averageSpeed,
      'totalLocations': totalLocations,
      'rejectedLocations': rejectedLocations,
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
      averageSpeed: (map['averageSpeed'] as num?)?.toDouble() ?? 0.0,
      totalLocations: (map['totalLocations'] as num?)?.toInt() ?? 0,
      rejectedLocations: (map['rejectedLocations'] as num?)?.toInt() ?? 0,
      isSynced: map['isSynced'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory TripModel.fromJson(String source) => TripModel.fromMap(json.decode(source));
}
