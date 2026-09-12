import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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

  FirebaseFirestore? get _firestore {
    if (!isAvailable) return null;
    return FirebaseFirestore.instance;
  }

  Future<bool> saveTripStart(TripModel trip) async {
    if (!isAvailable) return false;
    try {
      await _firestore!
          .collection('trips')
          .doc(trip.tripId)
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
      final String docId =
          point.timestamp.millisecondsSinceEpoch.toString();
      await _firestore!
          .collection('trips')
          .doc(point.tripId)
          .collection('locations')
          .doc(docId)
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
      await _firestore!
          .collection('trips')
          .doc(trip.tripId)
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
      final batch = _firestore!.batch();
      for (final point in points) {
        final docRef = _firestore!
            .collection('trips')
            .doc(point.tripId)
            .collection('locations')
            .doc(point.timestamp.millisecondsSinceEpoch.toString());
        batch.set(docRef, point.toMap());
      }
      await batch.commit().timeout(const Duration(seconds: 10));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<TripModel?> getTrip(String tripId) async {
    if (!isAvailable) return null;
    try {
      final snapshot = await _firestore!
          .collection('trips')
          .doc(tripId)
          .get()
          .timeout(const Duration(seconds: 5));
      if (snapshot.exists && snapshot.data() != null) {
        return TripModel.fromMap(snapshot.data()!);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
