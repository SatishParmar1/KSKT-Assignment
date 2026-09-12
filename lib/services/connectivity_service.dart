import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.any((result) => result != ConnectivityResult.none);
    });
  }

  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }
}
