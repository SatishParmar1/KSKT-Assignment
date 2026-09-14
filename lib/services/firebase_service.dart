import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/trip_model.dart';
import '../models/location_point.dart';

class FirebaseService {
  bool get isAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseDatabase? get _database {
    if (!isAvailable) return null;
    return FirebaseDatabase.instance;
  }

  Future<bool> saveTripStart(TripModel trip) async {
    if (!isAvailable) return false;
    try {
      await _database!
          .ref('trips/${trip.tripId}')
          .set(trip.toMap())
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> uploadLocation(LocationPoint point) async {
    if (!isAvailable) return false;
    try {
      final String key =
          point.timestamp.millisecondsSinceEpoch.toString();
      await _database!
          .ref('trips/${point.tripId}/locations/$key')
          .set(point.toMap())
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveTripEnd(TripModel trip) async {
    if (!isAvailable) return false;
    try {
      await _database!
          .ref('trips/${trip.tripId}')
          .update(trip.toMap())
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> syncBatchLocations(List<LocationPoint> points) async {
    if (!isAvailable || points.isEmpty) return false;
    try {
      final Map<String, dynamic> updates = {};
      for (final point in points) {
        final String key =
            point.timestamp.millisecondsSinceEpoch.toString();
        updates['trips/${point.tripId}/locations/$key'] = point.toMap();
      }
      await _database!
          .ref()
          .update(updates)
          .timeout(const Duration(seconds: 10));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<TripModel?> getTrip(String tripId) async {
    if (!isAvailable) return null;
    try {
      final snapshot = await _database!
          .ref('trips/$tripId')
          .get()
          .timeout(const Duration(seconds: 5));
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return TripModel.fromMap(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
