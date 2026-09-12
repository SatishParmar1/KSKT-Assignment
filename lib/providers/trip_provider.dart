import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/trip_model.dart';
import '../models/location_point.dart';
import '../services/location_service.dart';
import '../services/gps_filter_service.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';
import '../services/connectivity_service.dart';

enum TripStatus { idle, active, completed }

class TripProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final GpsFilterService _gpsFilterService = GpsFilterService();
  final StorageService _storageService = StorageService();
  final FirebaseService _firebaseService = FirebaseService();
  final ConnectivityService _connectivityService = ConnectivityService();

  TripModel? _currentTrip;
  LocationPoint? _lastValidLocation;
  TripStatus _status = TripStatus.idle;

  Duration _tripDuration = Duration.zero;
  Timer? _durationTimer;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<bool>? _connectivitySubscription;

  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingSyncCount = 0;
  bool _isProcessing = false;
  bool _isRecoveredTrip = false;
  String? _errorMessage;
  String? _lastRejectionReason;

  List<TripModel> _completedTrips = [];

  TripModel? get currentTrip => _currentTrip;
  LocationPoint? get lastValidLocation => _lastValidLocation;
  TripStatus get status => _status;
  Duration get tripDuration => _tripDuration;
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingSyncCount => _pendingSyncCount;
  bool get isProcessing => _isProcessing;
  bool get isRecoveredTrip => _isRecoveredTrip;
  String? get errorMessage => _errorMessage;
  String? get lastRejectionReason => _lastRejectionReason;
  List<TripModel> get completedTrips => _completedTrips;
  bool get isFirebaseAvailable => _firebaseService.isAvailable;

  double get currentSpeed => _currentTrip?.currentSpeed ?? 0.0;
  double get maxSpeed => _currentTrip?.maxSpeed ?? 0.0;
  double get totalDistanceKm =>
      (_currentTrip != null) ? (_currentTrip!.totalDistance / 1000.0) : 0.0;
  double get totalDistanceMeters => _currentTrip?.totalDistance ?? 0.0;
  int get acceptedPointsCount => _currentTrip?.totalLocations ?? 0;
  int get rejectedPointsCount => _currentTrip?.rejectedLocations ?? 0;

  Future<void> init() async {
    _isOnline = await _connectivityService.isConnected();
    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen((online) {
      _isOnline = online;
      notifyListeners();
      if (online) {
        syncPendingData();
      }
    });

    await _checkPendingSyncCount();
    await _loadCompletedTrips();
    await _checkAndRecoverActiveTrip();
  }

  Future<void> _checkPendingSyncCount() async {
    final pending = await _storageService.getPendingLocations();
    _pendingSyncCount = pending.length;
    notifyListeners();
  }

  Future<void> _loadCompletedTrips() async {
    _completedTrips = await _storageService.getCompletedTrips();
    notifyListeners();
  }

  Future<void> _checkAndRecoverActiveTrip() async {
    final activeTrip = await _storageService.getActiveTrip();
    if (activeTrip != null && activeTrip.status == 'active') {
      _currentTrip = activeTrip;
      _status = TripStatus.active;
      _isRecoveredTrip = true;

      final elapsed = DateTime.now().difference(activeTrip.startTime);
      _tripDuration = elapsed.isNegative ? Duration.zero : elapsed;

      _startDurationTimer();
      await _startLocationStream();
      notifyListeners();
    }
  }

  void dismissRecoveryBanner() {
    _isRecoveredTrip = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> startTrip() async {
    if (_isProcessing || _status == TripStatus.active) return false;
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bool hasPermission = await _locationService.checkPermission();
      if (!hasPermission) {
        _errorMessage = 'Location permission is required to start trip tracking';
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      final String tripId = 'TRIP-${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      _currentTrip = TripModel(
        tripId: tripId,
        startTime: now,
        status: 'active',
        totalDistance: 0.0,
        currentSpeed: 0.0,
        maxSpeed: 0.0,
        averageSpeed: 0.0,
        totalLocations: 0,
        rejectedLocations: 0,
        isSynced: false,
      );

      _lastValidLocation = null;
      _status = TripStatus.active;
      _isRecoveredTrip = false;
      _tripDuration = Duration.zero;
      _lastRejectionReason = null;

      await _storageService.saveActiveTrip(_currentTrip!);

      if (_isOnline) {
        final success = await _firebaseService.saveTripStart(_currentTrip!);
        if (success) {
          _currentTrip = _currentTrip!.copyWith(isSynced: true);
          await _storageService.saveActiveTrip(_currentTrip!);
        }
      }

      _startDurationTimer();
      await _startLocationStream();

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to start trip: $e';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> endTrip() async {
    if (_isProcessing || _status != TripStatus.active || _currentTrip == null) {
      return false;
    }
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _stopLocationStream();
      _stopDurationTimer();

      final now = DateTime.now();
      final double durationHours = _tripDuration.inSeconds / 3600.0;
      final double avgSpeed = durationHours > 0
          ? ((_currentTrip!.totalDistance / 1000.0) / durationHours)
          : 0.0;

      _currentTrip = _currentTrip!.copyWith(
        endTime: now,
        status: 'completed',
        currentSpeed: 0.0,
        averageSpeed: double.parse(avgSpeed.toStringAsFixed(1)),
      );

      await _storageService.saveCompletedTrip(_currentTrip!);
      await _storageService.clearActiveTrip();

      if (_isOnline) {
        await _firebaseService.saveTripEnd(_currentTrip!);
      }

      _status = TripStatus.completed;
      _isProcessing = false;
      await _loadCompletedTrips();
      await syncPendingData();

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to end trip: $e';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  void resetToIdle() {
    if (_status == TripStatus.active) return;
    _currentTrip = null;
    _lastValidLocation = null;
    _status = TripStatus.idle;
    _tripDuration = Duration.zero;
    _isRecoveredTrip = false;
    _errorMessage = null;
    _lastRejectionReason = null;
    notifyListeners();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTrip != null) {
        final elapsed = DateTime.now().difference(_currentTrip!.startTime);
        _tripDuration = elapsed.isNegative ? Duration.zero : elapsed;
        notifyListeners();
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  Future<void> _startLocationStream() async {
    await _stopLocationStream();
    final stream = _locationService.getPositionStream();
    _positionSubscription = stream.listen(
      (position) {
        processIncomingLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          speedMps: position.speed,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
        );
      },
      onError: (e) {
        _errorMessage = 'GPS Error: $e';
        notifyListeners();
      },
    );
  }

  Future<void> _stopLocationStream() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> processIncomingLocation({
    required double latitude,
    required double longitude,
    required double speedMps,
    required double accuracy,
    required DateTime timestamp,
  }) async {
    if (_status != TripStatus.active || _currentTrip == null) return;

    final GpsValidationResult result = _gpsFilterService.validateLocation(
      previousLocation: _lastValidLocation,
      latitude: latitude,
      longitude: longitude,
      rawSpeedMps: speedMps,
      accuracy: accuracy,
      timestamp: timestamp,
    );

    if (!result.isValid) {
      _lastRejectionReason = result.rejectionReason;
      final int newRejected = _currentTrip!.rejectedLocations + 1;
      _currentTrip = _currentTrip!.copyWith(rejectedLocations: newRejected);
      await _storageService.saveActiveTrip(_currentTrip!);
      notifyListeners();
      return;
    }

    _lastRejectionReason = null;

    final double newDistance =
        _currentTrip!.totalDistance + result.distanceMeters;
    final double updatedMaxSpeed = result.filteredSpeed > _currentTrip!.maxSpeed
        ? result.filteredSpeed
        : _currentTrip!.maxSpeed;
    final int updatedTotalLocations = _currentTrip!.totalLocations + 1;

    final LocationPoint point = LocationPoint(
      tripId: _currentTrip!.tripId,
      latitude: latitude,
      longitude: longitude,
      speed: double.parse(result.filteredSpeed.toStringAsFixed(1)),
      accuracy: double.parse(accuracy.toStringAsFixed(1)),
      timestamp: timestamp,
      isSynced: false,
    );

    _lastValidLocation = point;

    _currentTrip = _currentTrip!.copyWith(
      totalDistance: double.parse(newDistance.toStringAsFixed(1)),
      currentSpeed: double.parse(result.filteredSpeed.toStringAsFixed(1)),
      maxSpeed: double.parse(updatedMaxSpeed.toStringAsFixed(1)),
      totalLocations: updatedTotalLocations,
    );

    await _storageService.saveActiveTrip(_currentTrip!);
    await _storageService.savePendingLocation(point);
    _pendingSyncCount++;
    notifyListeners();

    if (_isOnline && _firebaseService.isAvailable) {
      final success = await _firebaseService.uploadLocation(point);
      if (success) {
        await _storageService.removePendingLocations([point]);
        _pendingSyncCount = (_pendingSyncCount - 1).clamp(0, 999999);
        notifyListeners();
      }
    }
  }

  Future<void> syncPendingData() async {
    if (_isSyncing || !_isOnline || !_firebaseService.isAvailable) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final pendingPoints = await _storageService.getPendingLocations();
      if (pendingPoints.isEmpty) {
        _pendingSyncCount = 0;
        _isSyncing = false;
        notifyListeners();
        return;
      }

      final success =
          await _firebaseService.syncBatchLocations(pendingPoints);
      if (success) {
        await _storageService.removePendingLocations(pendingPoints);
        _pendingSyncCount = 0;
      }
    } catch (_) {
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> simulateLocationStep({
    double deltaLat = 0.0005,
    double deltaLon = 0.0005,
    double speedKmh = 38.0,
    double accuracy = 6.5,
  }) async {
    if (_status != TripStatus.active || _currentTrip == null) return;

    final double baseLat = _lastValidLocation?.latitude ?? 28.6139;
    final double baseLon = _lastValidLocation?.longitude ?? 77.2090;

    final double newLat = baseLat + deltaLat;
    final double newLon = baseLon + deltaLon;
    final double speedMps = speedKmh / 3.6;

    await processIncomingLocation(
      latitude: newLat,
      longitude: newLon,
      speedMps: speedMps,
      accuracy: accuracy,
      timestamp: DateTime.now(),
    );
  }

  Future<void> simulateGpsJump() async {
    if (_status != TripStatus.active || _currentTrip == null) return;

    final double baseLat = _lastValidLocation?.latitude ?? 28.6139;
    final double baseLon = _lastValidLocation?.longitude ?? 77.2090;

    await processIncomingLocation(
      latitude: baseLat + 0.08,
      longitude: baseLon + 0.08,
      speedMps: 200.0,
      accuracy: 8.0,
      timestamp: DateTime.now(),
    );
  }

  Future<void> simulatePoorAccuracy() async {
    if (_status != TripStatus.active || _currentTrip == null) return;

    final double baseLat = _lastValidLocation?.latitude ?? 28.6139;
    final double baseLon = _lastValidLocation?.longitude ?? 77.2090;

    await processIncomingLocation(
      latitude: baseLat + 0.0002,
      longitude: baseLon + 0.0002,
      speedMps: 8.0,
      accuracy: 75.0,
      timestamp: DateTime.now(),
    );
  }

  Future<void> simulateStationaryDrift() async {
    if (_status != TripStatus.active || _currentTrip == null) return;

    final double baseLat = _lastValidLocation?.latitude ?? 28.6139;
    final double baseLon = _lastValidLocation?.longitude ?? 77.2090;

    await processIncomingLocation(
      latitude: baseLat + 0.00001,
      longitude: baseLon + 0.00001,
      speedMps: 0.1,
      accuracy: 5.0,
      timestamp: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _positionSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
