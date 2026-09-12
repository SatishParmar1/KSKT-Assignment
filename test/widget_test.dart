import 'package:flutter_test/flutter_test.dart';
import 'package:kskt_agromate/models/location_point.dart';
import 'package:kskt_agromate/services/gps_filter_service.dart';

void main() {
  group('GpsFilterService Tests', () {
    late GpsFilterService filterService;

    setUp(() {
      filterService = GpsFilterService();
    });

    test('accepts first location fix with good accuracy', () {
      final result = filterService.validateLocation(
        previousLocation: null,
        latitude: 28.6139,
        longitude: 77.2090,
        rawSpeedMps: 10.0,
        accuracy: 8.0,
        timestamp: DateTime.now(),
      );

      expect(result.isValid, isTrue);
      expect(result.distanceMeters, equals(0.0));
      expect(result.filteredSpeed, equals(36.0));
    });

    test('rejects location fix with poor accuracy', () {
      final result = filterService.validateLocation(
        previousLocation: null,
        latitude: 28.6139,
        longitude: 77.2090,
        rawSpeedMps: 10.0,
        accuracy: 45.0,
        timestamp: DateTime.now(),
      );

      expect(result.isValid, isFalse);
      expect(result.rejectionReason, contains('Poor GPS accuracy'));
    });

    test('rejects unrealistic GPS jump (teleportation)', () {
      final baseTime = DateTime.now();
      final prevPoint = LocationPoint(
        tripId: 'TRIP-1',
        latitude: 28.6139,
        longitude: 77.2090,
        speed: 30.0,
        accuracy: 5.0,
        timestamp: baseTime,
      );

      final nextTime = baseTime.add(const Duration(seconds: 2));
      final result = filterService.validateLocation(
        previousLocation: prevPoint,
        latitude: 28.6900,
        longitude: 77.2900,
        rawSpeedMps: 200.0,
        accuracy: 6.0,
        timestamp: nextTime,
      );

      expect(result.isValid, isFalse);
      expect(result.rejectionReason, contains('Unrealistic location jump'));
    });

    test('rejects duplicate or backward timestamp', () {
      final baseTime = DateTime.now();
      final prevPoint = LocationPoint(
        tripId: 'TRIP-1',
        latitude: 28.6139,
        longitude: 77.2090,
        speed: 30.0,
        accuracy: 5.0,
        timestamp: baseTime,
      );

      final result = filterService.validateLocation(
        previousLocation: prevPoint,
        latitude: 28.6140,
        longitude: 77.2091,
        rawSpeedMps: 10.0,
        accuracy: 6.0,
        timestamp: baseTime,
      );

      expect(result.isValid, isFalse);
      expect(result.rejectionReason, contains('Invalid or duplicate timestamp'));
    });

    test('suppresses stationary GPS drift when rider is stopped', () {
      final baseTime = DateTime.now();
      final prevPoint = LocationPoint(
        tripId: 'TRIP-1',
        latitude: 28.613900,
        longitude: 77.209000,
        speed: 0.0,
        accuracy: 4.0,
        timestamp: baseTime,
      );

      final nextTime = baseTime.add(const Duration(seconds: 2));
      final result = filterService.validateLocation(
        previousLocation: prevPoint,
        latitude: 28.613905,
        longitude: 77.209005,
        rawSpeedMps: 0.1,
        accuracy: 4.0,
        timestamp: nextTime,
      );

      expect(result.isValid, isTrue);
      expect(result.isStationaryJitter, isTrue);
      expect(result.distanceMeters, equals(0.0));
      expect(result.filteredSpeed, equals(0.0));
    });
  });
}
