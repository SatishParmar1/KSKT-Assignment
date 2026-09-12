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
  String? _errorMessage;

  TripModel? get currentTrip => _currentTrip;
  LocationPoint? get lastValidLocation => _lastValidLocation;
  TripStatus get status => _status;
  Duration get tripDuration => _tripDuration;
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingSyncCount => _pendingSyncCount;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;

  double get currentSpeed => _currentTrip?.currentSpeed ?? 0.0;
  double get maxSpeed => _currentTrip?.maxSpeed ?? 0.0;
  double get totalDistanceKm =>
      (_currentTrip != null) ? (_currentTrip!.totalDistance / 1000.0) : 0.0;

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
    await _checkActiveTrip();
  }

  Future<void> _checkPendingSyncCount() async {
    final pending = await _storageService.getPendingLocations();
    _pendingSyncCount = pending.length;
    notifyListeners();
  }

  Future<void> _checkActiveTrip() async {
    final activeTrip = await _storageService.getActiveTrip();
    if (activeTrip != null && activeTrip.status == 'active') {
      _currentTrip = activeTrip;
      _status = TripStatus.active;

      final elapsed = DateTime.now().difference(activeTrip.startTime);
      _tripDuration = elapsed.isNegative ? Duration.zero : elapsed;

      _startDurationTimer();
      await _startLocationStream();
      notifyListeners();
    }
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
        _errorMessage = 'Location permission is required';
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
      );

      _lastValidLocation = null;
      _status = TripStatus.active;
      _tripDuration = Duration.zero;

      await _storageService.saveActiveTrip(_currentTrip!);

      if (_isOnline) {
        await _firebaseService.saveTripStart(_currentTrip!);
      }

      _startDurationTimer();
      await _startLocationStream();

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Could not start trip: $e';
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

      _currentTrip = _currentTrip!.copyWith(
        endTime: DateTime.now(),
        status: 'completed',
        currentSpeed: 0.0,
      );

      await _storageService.saveCompletedTrip(_currentTrip!);
      await _storageService.clearActiveTrip();

      if (_isOnline) {
        await _firebaseService.saveTripEnd(_currentTrip!);
      }

      _status = TripStatus.completed;
      _isProcessing = false;
      await syncPendingData();

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Could not end trip: $e';
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
    _errorMessage = null;
    notifyListeners();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
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
        _errorMessage = 'Location error: $e';
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
      return;
    }

    final double newDistance =
        _currentTrip!.totalDistance + result.distanceMeters;
    final double updatedMaxSpeed = result.filteredSpeed > _currentTrip!.maxSpeed
        ? result.filteredSpeed
        : _currentTrip!.maxSpeed;

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
      lastLatitude: latitude,
      lastLongitude: longitude,
      lastAccuracy: accuracy,
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

  @override
  void dispose() {
    _durationTimer?.cancel();
    _positionSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
