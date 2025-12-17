
import 'dart:async';
import 'dart:io';

class NetworkService {
  final _connectivityController = StreamController<bool>.broadcast();

  bool _isConnected = false;
  Timer? _checkTimer;

  NetworkService() {
    _initialize();
  }

  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  Future<bool> isConnected() async {
    return _checkConnectivity();
  }

  bool get currentState => _isConnected;

  Future<bool> checkNow() async {
    return _checkConnectivity();
  }

  void _initialize() {
    // Initial check
    _checkConnectivity();

    // Periodic checks every 30 seconds
    _checkTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );
  }

  Future<bool> _checkConnectivity() async {
    try {
      // Try to lookup a reliable host
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));

      final connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      // Emit if changed
      if (connected != _isConnected) {
        _isConnected = connected;
        _connectivityController.add(_isConnected);
        print('Network: Connectivity changed to $_isConnected');
      }

      return connected;
    } on SocketException catch (_) {
      if (_isConnected) {
        _isConnected = false;
        _connectivityController.add(_isConnected);
        print('Network: Connectivity changed to false (socket exception)');
      }
      return false;
    } on TimeoutException catch (_) {
      if (_isConnected) {
        _isConnected = false;
        _connectivityController.add(_isConnected);
        print('Network: Connectivity changed to false (timeout)');
      }
      return false;
    } catch (e) {
      print('Network: Error checking connectivity: $e');
      return _isConnected;
    }
  }

  /// Check if we can reach a specific host
  Future<bool> canReach(String host) async {
    try {
      final result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Check network quality by measuring response time
  ///
  /// Returns response time in milliseconds, or null if unreachable.
  Future<int?> measureLatency(String host) async {
    final stopwatch = Stopwatch()..start();
    try {
      await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 10));
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return null;
    }
  }

  /// Get network quality assessment
  ///
  /// Returns: 'good', 'slow', 'poor', or 'offline'
  Future<String> getNetworkQuality() async {
    if (!_isConnected) return 'offline';

    final latency = await measureLatency('google.com');

    if (latency == null) return 'offline';
    if (latency < 100) return 'good';
    if (latency < 500) return 'slow';
    return 'poor';
  }


  void dispose() {
    _checkTimer?.cancel();
    _connectivityController.close();
  }
}
