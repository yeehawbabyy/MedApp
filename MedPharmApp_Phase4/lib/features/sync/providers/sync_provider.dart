
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/sync_service.dart';
import '../services/network_service.dart';
import '../models/sync_models.dart';

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService;
  final NetworkService _networkService;

  SyncStatus _syncStatus = const SyncStatus();
  bool _isOnline = false;
  bool _isSyncing = false;
  String? _errorMessage;
  int _lastSyncedCount = 0;


  StreamSubscription? _connectivitySubscription;
  Timer? _autoSyncTimer;

  SyncProvider(this._syncService, this._networkService) {
    _initialize();
  }

  SyncStatus get syncStatus => _syncStatus;

  bool get isOnline => _isOnline;

  bool get isSyncing => _isSyncing;

  String? get errorMessage => _errorMessage;

  int get lastSyncedCount => _lastSyncedCount;

  bool get hasPendingItems => _syncStatus.pendingCount > 0;

  bool get hasFailedItems => _syncStatus.failedCount > 0;

  bool get hasOverdueItems => _syncStatus.overdueCount > 0;

  bool get isFullySynced => _syncStatus.isFullySynced;

  String get statusMessage {
    if (_isSyncing) return 'Syncing...';
    if (!_isOnline) return 'Offline';
    if (hasOverdueItems) return '${_syncStatus.overdueCount} overdue!';
    if (hasFailedItems) return '${_syncStatus.failedCount} failed';
    if (hasPendingItems) return '${_syncStatus.pendingCount} pending';
    if (isFullySynced) return 'All synced';
    return 'Ready';
  }

  void _initialize() {
    _checkConnectivity();

    _connectivitySubscription = _networkService.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    refreshSyncStatus();

    _startAutoSyncTimer();
  }

  Future<void> _checkConnectivity() async {
    _isOnline = await _networkService.isConnected();
    notifyListeners();
  }

  void _onConnectivityChanged(bool isConnected) {
    final wasOffline = !_isOnline;
    _isOnline = isConnected;
    notifyListeners();

    if (wasOffline && isConnected) {
      print('Sync: Came online, triggering sync...');
      syncNow();
    }
  }

  void _startAutoSyncTimer() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _autoSync(),
    );
  }

  Future<void> _autoSync() async {
    if (_isOnline && !_isSyncing && hasPendingItems) {
      print('Sync: Auto-sync triggered');
      await syncNow();
    }
  }

  Future<void> refreshSyncStatus() async {
    try {
      _syncStatus = await _syncService.getSyncStatus();
      _syncStatus = _syncStatus.copyWith(
        isOnline: _isOnline,
        isSyncing: _isSyncing,
      );
      notifyListeners();
    } catch (e) {
      print('Sync: Error refreshing status: $e');
    }
  }

  Future<void> syncNow() async {
    if (_isSyncing) {
      print('Sync: Already syncing, skipping');
      return;
    }

    if (!_isOnline) {
      _errorMessage = 'Cannot sync while offline';
      notifyListeners();
      return;
    }

    try {
      _isSyncing = true;
      _errorMessage = null;
      notifyListeners();

      // Process the queue
      final syncedCount = await _syncService.processQueue();
      _lastSyncedCount = syncedCount;

      // Retry failed items
      final retriedCount = await _syncService.retryFailedItems();
      _lastSyncedCount += retriedCount;

      // Refresh status
      await refreshSyncStatus();

      // Cleanup old items
      await _syncService.cleanupCompletedItems();

      _isSyncing = false;
      notifyListeners();

      print('Sync: Completed. Synced $_lastSyncedCount items');
    } catch (e) {
      _isSyncing = false;
      _errorMessage = 'Sync failed: $e';
      notifyListeners();
      print('Sync: Error during sync: $e');
    }
  }

  Future<void> queueForSync({
    required String studyId,
    required SyncItemType itemType,
    required String dataId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _syncService.addToQueue(
        studyId: studyId,
        itemType: itemType,
        dataId: dataId,
        payload: payload,
      );

      await refreshSyncStatus();

      // If online, try to sync immediately
      if (_isOnline && !_isSyncing) {
        // Small delay to batch nearby saves
        Future.delayed(const Duration(seconds: 2), () {
          if (_isOnline && !_isSyncing) {
            syncNow();
          }
        });
      }
    } catch (e) {
      _errorMessage = 'Failed to queue for sync: $e';
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}
