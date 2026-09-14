import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/trip_model.dart';
import '../models/location_point.dart';
import '../firebase_options.dart';

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
    try {
      return FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: DefaultFirebaseOptions.rtdbUrl,
      );
    } catch (_) {
      try {
        return FirebaseDatabase.instance;
      } catch (_) {
        return null;
      }
    }
  }

  Future<bool> saveTrip(TripModel trip) async {
    if (!isAvailable || _database == null) return false;
    try {
      await _database!
          .ref('trips/${trip.tripId}')
          .update(trip.toMap())
          .timeout(const Duration(seconds: 8));
      return true;
    } catch (e) {
      debugPrint('Firebase saveTrip error: $e');
      return false;
    }
  }

  Future<bool> uploadLocation(LocationPoint point) async {
    if (!isAvailable || _database == null) return false;
    try {
      final String key =
          point.timestamp.millisecondsSinceEpoch.toString();
      await _database!
          .ref('trips/${point.tripId}/locations/$key')
          .set(point.toMap())
          .timeout(const Duration(seconds: 8));
      return true;
    } catch (e) {
      debugPrint('Firebase uploadLocation error: $e');
      return false;
    }
  }

  Future<bool> syncBatchLocations(List<LocationPoint> points) async {
    if (!isAvailable || _database == null || points.isEmpty) return false;
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
          .timeout(const Duration(seconds: 12));
      return true;
    } catch (e) {
      debugPrint('Firebase syncBatchLocations error: $e');
      return false;
    }
  }

  Future<TripModel?> getTrip(String tripId) async {
    if (!isAvailable || _database == null) return null;
    try {
      final snapshot = await _database!
          .ref('trips/$tripId')
          .get()
          .timeout(const Duration(seconds: 8));
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return TripModel.fromMap(data);
      }
      return null;
    } catch (e) {
      debugPrint('Firebase getTrip error: $e');
      return null;
    }
  }
}
