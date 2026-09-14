import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_model.dart';
import '../models/location_point.dart';

class StorageService {
  static const String keyActiveTrip = 'active_trip';
  static const String keyPendingLocations = 'pending_locations';
  static const String keyCompletedTrips = 'completed_trips';

  Future<void> saveActiveTrip(TripModel trip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyActiveTrip, trip.toJson());
  }

  Future<TripModel?> getActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(keyActiveTrip);
    if (data == null || data.isEmpty) return null;
    try {
      return TripModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyActiveTrip);
  }

  Future<void> savePendingLocation(LocationPoint point) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(keyPendingLocations) ?? [];
    list.add(point.toJson());
    await prefs.setStringList(keyPendingLocations, list);
  }

  Future<List<LocationPoint>> getPendingLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(keyPendingLocations) ?? [];
    final List<LocationPoint> points = [];
    for (final item in list) {
      try {
        points.add(LocationPoint.fromJson(item));
      } catch (_) {}
    }
    return points;
  }

  Future<void> removePendingLocations(List<LocationPoint> syncedPoints) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(keyPendingLocations) ?? [];
    final Set<String> syncedTimestamps =
        syncedPoints.map((p) => p.timestamp.toIso8601String()).toSet();

    final List<String> remaining = [];
    for (final item in list) {
      try {
        final decoded = json.decode(item);
        final String ts = decoded['timestamp'] ?? '';
        if (!syncedTimestamps.contains(ts)) {
          remaining.add(item);
        }
      } catch (_) {}
    }

    await prefs.setStringList(keyPendingLocations, remaining);
  }

  Future<void> clearPendingLocations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyPendingLocations);
  }

  Future<void> saveCompletedTrip(TripModel trip) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(keyCompletedTrips) ?? [];
    list.insert(0, trip.toJson());
    await prefs.setStringList(keyCompletedTrips, list);
  }

  Future<void> updateCompletedTripSync(String tripId, bool isSynced) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(keyCompletedTrips) ?? [];
    final List<String> updated = [];
    for (final item in list) {
      try {
        final trip = TripModel.fromJson(item);
        if (trip.tripId == tripId) {
          updated.add(trip.copyWith(isSynced: isSynced).toJson());
        } else {
          updated.add(item);
        }
      } catch (_) {
        updated.add(item);
      }
    }
    await prefs.setStringList(keyCompletedTrips, updated);
  }

  Future<List<TripModel>> getCompletedTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(keyCompletedTrips) ?? [];
    final List<TripModel> trips = [];
    for (final item in list) {
      try {
        trips.add(TripModel.fromJson(item));
      } catch (_) {}
    }
    return trips;
  }
}
