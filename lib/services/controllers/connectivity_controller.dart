import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ConnectivityController extends GetxController {
  final Connectivity _connectivity = Connectivity();

  // Observable state
  final RxBool isConnected = true.obs;
  final RxBool isCheckingConnection = false.obs;
  final Rx<ConnectivityResult> connectionType = ConnectivityResult.none.obs;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _startListening();
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  // Initialize connectivity status
  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      }
    } catch (e) {
      print('Error checking initial connectivity: $e');
      isConnected.value = false;
    }
  }

  // Listen to connectivity changes
  void _startListening() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        if (results.isNotEmpty) {
          _updateConnectionStatus(results.first);
        }
      },
    );
  }

  // Update connection status and verify with actual internet check
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    connectionType.value = result;

    if (result == ConnectivityResult.none) {
      isConnected.value = false;
    } else {
      // Even if connected to WiFi/Mobile, verify actual internet access
      final hasInternet = await _checkInternetConnection();
      isConnected.value = hasInternet;
    }
  }

  // Actually check if we can reach the internet
  Future<bool> _checkInternetConnection() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.google.com'),
      ).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Manual connectivity check (for retry button)
  Future<void> checkConnection() async {
    isCheckingConnection.value = true;

    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isNotEmpty) {
        await _updateConnectionStatus(results.first);
      }
    } catch (e) {
      print('Error checking connectivity: $e');
      isConnected.value = false;
    } finally {
      isCheckingConnection.value = false;
    }
  }

  // Get connection type as string
  String get connectionTypeString {
    switch (connectionType.value) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
      default:
        return 'No Connection';
    }
  }
}
