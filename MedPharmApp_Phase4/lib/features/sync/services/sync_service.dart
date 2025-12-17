
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../core/services/database_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../models/sync_models.dart';

class SyncService {
  final DatabaseService _databaseService;
  final ApiClient _apiClient;

  SyncService(this._databaseService, this._apiClient);

  Future<void> addToQueue({
    required String studyId,
    required SyncItemType itemType,
    required String dataId,
    required Map<String, dynamic> payload,
  }) async {
    final db = await _databaseService.database;

    final item = SyncQueueItem(
      studyId: studyId,
      itemType: itemType,
      dataId: dataId,
      payload: jsonEncode(payload),
    );

    await db.insert(
      'sync_queue',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print('Sync: Added ${itemType.name} $dataId to queue');
  }

  Future<List<SyncQueueItem>> getPendingItems() async {
    final db = await _databaseService.database;

    final results = await db.query(
      'sync_queue',
      where: 'status IN (?, ?)',
      whereArgs: [SyncItemStatus.pending.name, SyncItemStatus.failed.name],
      orderBy: 'created_at ASC',
    );

    return results.map((map) => SyncQueueItem.fromMap(map)).toList();
  }

  /// Get items that are approaching their deadline
  Future<List<SyncQueueItem>> getUrgentItems() async {
    final items = await getPendingItems();
    return items.where((item) => item.isApproachingDeadline).toList();
  }

  /// Get overdue items that need immediate attention
  Future<List<SyncQueueItem>> getOverdueItems() async {
    final items = await getPendingItems();
    return items.where((item) => item.isOverdue).toList();
  }

  /// Get current sync status summary
  Future<SyncStatus> getSyncStatus() async {
    final db = await _databaseService.database;

    // Count pending items
    final pendingResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM sync_queue
      WHERE status IN ('pending', 'syncing')
    ''');
    final pendingCount = Sqflite.firstIntValue(pendingResult) ?? 0;

    // Count failed items
    final failedResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM sync_queue
      WHERE status = 'failed'
    ''');
    final failedCount = Sqflite.firstIntValue(failedResult) ?? 0;

    // Count overdue items
    final now = DateTime.now().toIso8601String();
    final overdueResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM sync_queue
      WHERE status IN ('pending', 'failed') AND deadline < ?
    ''', [now]);
    final overdueCount = Sqflite.firstIntValue(overdueResult) ?? 0;

    // Get last sync time
    final lastSyncResult = await db.rawQuery('''
      SELECT MAX(synced_at) as last_sync FROM sync_queue
      WHERE status = 'completed'
    ''');
    final lastSyncStr = lastSyncResult.first['last_sync'] as String?;
    final lastSyncAt = lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;

    return SyncStatus(
      pendingCount: pendingCount,
      failedCount: failedCount,
      overdueCount: overdueCount,
      lastSyncAt: lastSyncAt,
    );
  }

  Future<int> processQueue() async {
    final pendingItems = await getPendingItems();

    if (pendingItems.isEmpty) {
      print('Sync: No pending items to process');
      return 0;
    }

    print('Sync: Processing ${pendingItems.length} pending items');

    int successCount = 0;

    // Group items by type for batch processing
    final assessments = pendingItems
        .where((i) => i.itemType == SyncItemType.assessment)
        .toList();
    final auditLogs = pendingItems
        .where((i) => i.itemType == SyncItemType.auditLog)
        .toList();
    final others = pendingItems
        .where((i) =>
            i.itemType != SyncItemType.assessment &&
            i.itemType != SyncItemType.auditLog)
        .toList();

    // Batch sync assessments
    if (assessments.isNotEmpty) {
      successCount += await _batchSyncAssessments(assessments);
    }

    // Batch sync audit logs
    if (auditLogs.isNotEmpty) {
      successCount += await _batchSyncAuditLogs(auditLogs);
    }

    // Process other items individually
    for (final item in others) {
      final success = await _syncSingleItem(item);
      if (success) successCount++;
    }

    print('Sync: Completed. $successCount/${pendingItems.length} succeeded');

    return successCount;
  }

  /// Sync assessments in a batch for efficiency
  Future<int> _batchSyncAssessments(List<SyncQueueItem> items) async {
    if (items.length == 1) {
      // Single item, use regular endpoint
      final success = await _syncSingleItem(items.first);
      return success ? 1 : 0;
    }

    // Mark all as syncing
    for (final item in items) {
      await _updateItemStatus(item, SyncItemStatus.syncing);
    }

    try {
      // Prepare batch payload
      final payloads = items
          .map((item) => jsonDecode(item.payload) as Map<String, dynamic>)
          .toList();

      final response = await _apiClient.post(
        ApiConfig.assessmentsSyncBatch,
        body: {'assessments': payloads},
      );

      if (response.isSuccess) {
        final data = response.data;
        final results = data?['results'] as List? ?? [];

        int successCount = 0;

        for (var i = 0; i < items.length; i++) {
          final item = items[i];
          final result = results.length > i
              ? results[i] as Map<String, dynamic>
              : {'status': 'success'};

          if (result['status'] == 'success') {
            await _markItemSynced(item);
            successCount++;
          } else {
            await _markItemFailed(
              item,
              result['errorCode'] as String? ?? 'UNKNOWN',
              result['errorMessage'] as String? ?? 'Batch item failed',
            );
          }
        }

        return successCount;
      } else {
        // Batch failed, mark all as failed
        for (final item in items) {
          await _markItemFailed(
            item,
            response.errorCode ?? 'BATCH_FAILED',
            response.errorMessage ?? 'Batch sync failed',
          );
        }
        return 0;
      }
    } catch (e) {
      // Error occurred, mark all as failed
      for (final item in items) {
        await _markItemFailed(item, 'EXCEPTION', e.toString());
      }
      return 0;
    }
  }

  /// Sync audit logs in a batch
  Future<int> _batchSyncAuditLogs(List<SyncQueueItem> items) async {
    // Mark all as syncing
    for (final item in items) {
      await _updateItemStatus(item, SyncItemStatus.syncing);
    }

    try {
      final payloads = items
          .map((item) => jsonDecode(item.payload) as Map<String, dynamic>)
          .toList();

      final response = await _apiClient.post(
        ApiConfig.auditLog,
        body: {'logs': payloads},
      );

      if (response.isSuccess) {
        for (final item in items) {
          await _markItemSynced(item);
        }
        return items.length;
      } else {
        for (final item in items) {
          await _markItemFailed(
            item,
            response.errorCode ?? 'AUDIT_FAILED',
            response.errorMessage ?? 'Audit log sync failed',
          );
        }
        return 0;
      }
    } catch (e) {
      for (final item in items) {
        await _markItemFailed(item, 'EXCEPTION', e.toString());
      }
      return 0;
    }
  }

  /// Sync a single item to the server
  Future<bool> _syncSingleItem(SyncQueueItem item) async {
    await _updateItemStatus(item, SyncItemStatus.syncing);

    try {
      final payload = jsonDecode(item.payload) as Map<String, dynamic>;
      final endpoint = _getEndpointForType(item.itemType);

      final response = await _apiClient.post(endpoint, body: payload);

      if (response.isSuccess) {
        await _markItemSynced(item);
        return true;
      } else {
        await _markItemFailed(
          item,
          response.errorCode ?? 'UNKNOWN',
          response.errorMessage ?? 'Sync failed',
        );
        return false;
      }
    } catch (e) {
      await _markItemFailed(item, 'EXCEPTION', e.toString());
      return false;
    }
  }

  /// Get the API endpoint for a sync item type
  String _getEndpointForType(SyncItemType type) {
    switch (type) {
      case SyncItemType.assessment:
        return ApiConfig.assessmentsSync;
      case SyncItemType.consent:
        return ApiConfig.enrollmentConsent;
      case SyncItemType.auditLog:
        return ApiConfig.auditLog;
      case SyncItemType.alert:
        return ApiConfig.alerts;
      case SyncItemType.gamification:
        return ApiConfig.syncStatus; // Placeholder
    }
  }

  Future<void> _updateItemStatus(
    SyncQueueItem item,
    SyncItemStatus status,
  ) async {
    final db = await _databaseService.database;

    await db.update(
      'sync_queue',
      {
        'status': status.name,
        'last_attempt_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Mark item as successfully synced
  Future<void> _markItemSynced(SyncQueueItem item) async {
    final db = await _databaseService.database;

    await db.update(
      'sync_queue',
      {
        'status': SyncItemStatus.completed.name,
        'synced_at': DateTime.now().toIso8601String(),
        'last_attempt_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );

    print('Sync: ${item.itemType.name} ${item.dataId} synced successfully');
  }

  /// Mark item as failed and increment retry count
  Future<void> _markItemFailed(
    SyncQueueItem item,
    String errorCode,
    String errorMessage,
  ) async {
    final db = await _databaseService.database;
    final newRetryCount = item.retryCount + 1;

    // Check if item is now overdue
    final status = item.isOverdue
        ? SyncItemStatus.expired
        : SyncItemStatus.failed;

    await db.update(
      'sync_queue',
      {
        'status': status.name,
        'retry_count': newRetryCount,
        'last_error': '$errorCode: $errorMessage',
        'last_attempt_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );

    print('Sync: ${item.itemType.name} ${item.dataId} failed '
        '(attempt $newRetryCount): $errorMessage');
  }

  Future<List<SyncQueueItem>> getItemsToRetry() async {
    final failedItems = await getPendingItems();

    return failedItems.where((item) {
      if (!item.shouldRetry) return false;
      if (item.lastAttemptAt == null) return true;

      // Calculate backoff delay
      final delayMs = ApiConfig.calculateRetryDelay(item.retryCount);
      final nextRetryTime = item.lastAttemptAt!.add(
        Duration(milliseconds: delayMs),
      );

      return DateTime.now().isAfter(nextRetryTime);
    }).toList();
  }

  /// Retry failed items that are ready for retry
  Future<int> retryFailedItems() async {
    final itemsToRetry = await getItemsToRetry();

    if (itemsToRetry.isEmpty) {
      return 0;
    }

    print('Sync: Retrying ${itemsToRetry.length} failed items');

    int successCount = 0;
    for (final item in itemsToRetry) {
      final success = await _syncSingleItem(item);
      if (success) successCount++;
    }

    return successCount;
  }

  Future<int> cleanupCompletedItems() async {
    final db = await _databaseService.database;

    final cutoffDate = DateTime.now()
        .subtract(const Duration(days: 7))
        .toIso8601String();

    final result = await db.delete(
      'sync_queue',
      where: 'status = ? AND synced_at < ?',
      whereArgs: [SyncItemStatus.completed.name, cutoffDate],
    );

    if (result > 0) {
      print('Sync: Cleaned up $result old completed items');
    }

    return result;
  }

  /// Clear all items from queue (for development/testing)
  Future<void> clearQueue() async {
    final db = await _databaseService.database;
    await db.delete('sync_queue');
    print('Sync: Queue cleared');
  }
}
