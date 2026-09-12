import 'dart:math' as math;
import '../models/location_point.dart';

class GpsValidationResult {
  final bool isValid;
  final String? rejectionReason;
  final double distanceMeters;
  final double filteredSpeed;
  final bool isStationaryJitter;

  GpsValidationResult({
    required this.isValid,
    this.rejectionReason,
    this.distanceMeters = 0.0,
    this.filteredSpeed = 0.0,
    this.isStationaryJitter = false,
  });
}

class GpsFilterService {
  static const double maxAcceptableAccuracyMeters = 30.0;
  static const double maxRealisticSpeedKmh = 130.0;
  static const double minDistanceJitterThresholdMeters = 2.5;
  static const double stationarySpeedThresholdKmh = 1.5;

  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusMeters = 6371000;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180.0;
  }

  GpsValidationResult validateLocation({
    required LocationPoint? previousLocation,
    required double latitude,
    required double longitude,
    required double rawSpeedMps,
    required double accuracy,
    required DateTime timestamp,
  }) {
    if (accuracy <= 0 || accuracy > maxAcceptableAccuracyMeters) {
      return GpsValidationResult(
        isValid: false,
        rejectionReason: 'Poor GPS accuracy ($accuracy m)',
      );
    }

    final double rawSpeedKmh = rawSpeedMps > 0 ? (rawSpeedMps * 3.6) : 0.0;

    if (previousLocation == null) {
      return GpsValidationResult(
        isValid: true,
        distanceMeters: 0.0,
        filteredSpeed: rawSpeedKmh > maxRealisticSpeedKmh ? 0.0 : rawSpeedKmh,
        isStationaryJitter: false,
      );
    }

    final int timeDeltaSeconds =
        timestamp.difference(previousLocation.timestamp).inSeconds;

    if (timeDeltaSeconds <= 0) {
      return GpsValidationResult(
        isValid: false,
        rejectionReason: 'Invalid or duplicate timestamp',
      );
    }

    final double distanceMeters = calculateDistance(
      previousLocation.latitude,
      previousLocation.longitude,
      latitude,
      longitude,
    );

    final double calculatedSpeedKmh =
        (distanceMeters / timeDeltaSeconds) * 3.6;

    if (calculatedSpeedKmh > maxRealisticSpeedKmh) {
      return GpsValidationResult(
        isValid: false,
        rejectionReason:
            'Unrealistic location jump ($calculatedSpeedKmh km/h)',
        distanceMeters: distanceMeters,
      );
    }

    if (distanceMeters < minDistanceJitterThresholdMeters &&
        rawSpeedKmh < stationarySpeedThresholdKmh) {
      return GpsValidationResult(
        isValid: true,
        distanceMeters: 0.0,
        filteredSpeed: 0.0,
        isStationaryJitter: true,
      );
    }

    final double effectiveSpeed = rawSpeedKmh > 0 ? rawSpeedKmh : calculatedSpeedKmh;
    final double finalSpeed =
        effectiveSpeed > maxRealisticSpeedKmh ? maxRealisticSpeedKmh : effectiveSpeed;

    return GpsValidationResult(
      isValid: true,
      distanceMeters: distanceMeters,
      filteredSpeed: finalSpeed,
      isStationaryJitter: false,
    );
  }
}
