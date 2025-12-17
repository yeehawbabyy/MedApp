# Offline-First Synchronization Mechanism

## Table of Contents

1. [Overview](#overview)
2. [Why Offline-First?](#why-offline-first)
3. [Architecture Overview](#architecture-overview)
4. [Component Deep Dive](#component-deep-dive)
5. [Data Flow](#data-flow)
6. [Sync Queue Lifecycle](#sync-queue-lifecycle)
7. [Retry Strategy](#retry-strategy)
8. [Network Monitoring](#network-monitoring)
9. [Mock API for Development](#mock-api-for-development)
10. [Database Schema](#database-schema)
11. [Code Examples](#code-examples)
12. [Best Practices](#best-practices)

---

## Overview

The synchronization mechanism in this application follows an **offline-first** architecture pattern. This means that all data operations are performed locally first, and synchronization with the server happens asynchronously in the background.

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER ACTION                              │
│                    (e.g., Submit Assessment)                    │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     1. SAVE LOCALLY                             │
│                   (SQLite Database)                             │
│                   ✓ Immediate, Always Works                     │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                  2. ADD TO SYNC QUEUE                           │
│                (SyncQueueItem with deadline)                    │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                  3. PROCESS WHEN ONLINE                         │
│              (Automatic or Manual Trigger)                      |
└─────────────────────────────────────────────────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
            ┌───────────────┐       ┌───────────────┐
            │   SUCCESS     │       │   FAILURE     │
            │ Mark Complete │       │ Retry Later   │
            └───────────────┘       └───────────────┘
```

---

## Why Offline-First?

### Clinical Trial Requirements

In a medical/clinical trial context, offline-first is not just a convenience—it's a requirement:

1. **Data Integrity**: Patient data must never be lost, even if the network fails mid-submission
2. **User Experience**: Patients should not wait for network responses to complete their daily tasks
3. **Regulatory Compliance**: FDA 21 CFR Part 11 requires audit trails and data integrity
4. **Real-World Conditions**: Patients may be in hospitals, rural areas, or traveling with poor connectivity

### Benefits

| Benefit | Description |
|---------|-------------|
| **Reliability** | App works regardless of network state |
| **Speed** | Instant feedback to users (no network latency) |
| **Battery Efficient** | Batch syncs reduce radio usage |
| **Resilient** | Automatic retry handles transient failures |
| **Auditable** | Every sync attempt is tracked |

---

## Architecture Overview

The sync system consists of five main components:

```
┌─────────────────────────────────────────────────────────────────┐
│                         UI LAYER                                │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              SyncStatusWidget                           │    │
│  │  • SyncStatusIndicator (app bar icon)                   │    │
│  │  • SyncStatusBanner (offline warning)                   │    │
│  │  • SyncStatusCard (detailed view)                       │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ watches
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      STATE LAYER                                │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              SyncProvider                               │    │
│  │  • Exposes sync status to UI                            │    │
│  │  • Triggers sync operations                             │    │
│  │  • Listens to connectivity changes                      │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ uses
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     SERVICE LAYER                               │
│  ┌────────────────────┐    ┌────────────────────┐               │
│  │   SyncService      │    │  NetworkService    │               │
│  │  • Queue mgmt      │    │  • Connectivity    │               │
│  │  • Batch sync      │    │  • Online/Offline  │               │
│  │  • Retry logic     │    │  • Quality check   │               │
│  └────────────────────┘    └────────────────────┘               │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ uses
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     NETWORK LAYER                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              ApiClient                                  │    │
│  │  • HTTP requests (GET, POST, PUT, DELETE)               │    │
│  │  • Token management                                     │    │
│  │  • Mock mode for development                            │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ configured by
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                   CONFIGURATION                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              ApiConfig                                  │    │
│  │  • Endpoints, timeouts, retry settings                  │    │
│  │  • Error codes, alert types                             │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Deep Dive

### 1. ApiConfig (`lib/core/network/api_config.dart`)

Central configuration for all API-related settings. This file acts as a single source of truth for:

```dart
class ApiConfig {
  // Environment
  static const bool useMockApi = true;           // Toggle mock/real API
  static const String baseUrl = 'https://api.medpharm-trials.com/v1';

  // Endpoints
  static const String assessmentsSync = '/assessments/sync';
  static const String assessmentsSyncBatch = '/assessments/sync/batch';

  // Timeouts
  static const int connectionTimeoutSeconds = 30;

  // Retry Configuration
  static const int maxRetryAttempts = 3;
  static const int retryBaseDelayMs = 1000;      // 1 second
  static const double retryBackoffMultiplier = 2.0;

  // Sync Deadlines (for regulatory compliance)
  static const int syncDeadlineHours = 48;       // Must sync within 48 hours
}
```

**Why separate configuration?**
- Easy to switch between development/production
- All magic numbers in one place
- Can be modified without touching business logic

### 2. ApiClient (`lib/core/network/api_client.dart`)

HTTP client wrapper that handles all network communication:

```dart
class ApiClient {
  final http.Client _httpClient;
  String? _authToken;
  final bool _useMockApi;

  // Automatic token injection
  Map<String, String> _buildHeaders(bool requiresAuth) {
    final headers = {
      'Content-Type': 'application/json',
      'X-Request-Id': _generateRequestId(),  // For tracing
    };
    if (requiresAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // Unified request method with error handling
  Future<ApiResponse> _makeRequest({...}) async {
    if (_useMockApi) {
      return _mockRequest(method, url.path, body);  // Development mode
    }
    // Real HTTP request with timeout and error handling
  }
}
```

**Key features:**
- Automatic Bearer token injection
- Request ID generation for tracing/debugging
- Unified error handling
- Mock mode for development without backend

### 3. SyncService (`lib/features/sync/services/sync_service.dart`)

The heart of the sync mechanism. Manages the sync queue and coordinates synchronization:

```dart
class SyncService {
  // Add item to queue (called after local save)
  Future<void> addToQueue({
    required String studyId,
    required SyncItemType itemType,
    required String dataId,
    required Map<String, dynamic> payload,
  }) async {
    final item = SyncQueueItem(
      studyId: studyId,
      itemType: itemType,
      dataId: dataId,
      payload: jsonEncode(payload),
      deadline: DateTime.now().add(Duration(hours: 48)),  // Regulatory requirement
    );
    await db.insert('sync_queue', item.toMap());
  }

  // Process all pending items
  Future<int> processQueue() async {
    final pendingItems = await getPendingItems();

    // Group by type for efficient batch processing
    final assessments = pendingItems.where((i) => i.itemType == SyncItemType.assessment);
    final auditLogs = pendingItems.where((i) => i.itemType == SyncItemType.auditLog);

    // Batch sync for efficiency
    await _batchSyncAssessments(assessments);
    await _batchSyncAuditLogs(auditLogs);

    // Individual sync for other types
    for (final item in others) {
      await _syncSingleItem(item);
    }
  }
}
```

**Key responsibilities:**
- Queue management (add, get, update, delete)
- Batch synchronization for efficiency
- Status tracking (pending, syncing, completed, failed, expired)
- Retry coordination

### 4. NetworkService (`lib/features/sync/services/network_service.dart`)

Monitors network connectivity and provides real-time status:

```dart
class NetworkService {
  final _connectivityController = StreamController<bool>.broadcast();

  // Stream that UI/providers can listen to
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  // Actual connectivity check (DNS lookup)
  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
```

**Why DNS lookup instead of just checking WiFi/cellular?**
- WiFi can be connected but have no internet (captive portals, etc.)
- Actually testing connectivity is more reliable
- Small overhead, big reliability gain

### 5. SyncProvider (`lib/features/sync/providers/sync_provider.dart`)

State management layer that connects services to UI:

```dart
class SyncProvider extends ChangeNotifier {
  // State exposed to UI
  SyncStatus _syncStatus;
  bool _isOnline = false;
  bool _isSyncing = false;

  // Listen for connectivity changes
  void _onConnectivityChanged(bool isConnected) {
    final wasOffline = !_isOnline;
    _isOnline = isConnected;
    notifyListeners();  // Update UI

    // Auto-sync when coming online
    if (wasOffline && isConnected) {
      syncNow();
    }
  }

  // Manual sync trigger
  Future<void> syncNow() async {
    if (_isSyncing || !_isOnline) return;

    _isSyncing = true;
    notifyListeners();

    await _syncService.processQueue();
    await _syncService.retryFailedItems();

    _isSyncing = false;
    notifyListeners();
  }
}
```

**Key patterns:**
- Reactive: UI automatically updates via `notifyListeners()`
- Auto-sync: Triggers when device comes online
- Debouncing: Prevents multiple simultaneous syncs

---

## Data Flow

### Complete Flow: Assessment Submission

```
1. USER SUBMITS ASSESSMENT
   │
   ▼
2. AssessmentProvider.submitAssessment()
   │
   ├──► AssessmentService.saveAssessment()
   │    └── INSERT INTO assessments (...)
   │        ✓ Data is now safely stored locally
   │
   └──► SyncProvider.queueForSync()
        │
        ▼
3. SyncService.addToQueue()
   │
   └── INSERT INTO sync_queue (
         id: 'sync_123',
         item_type: 'assessment',
         data_id: 'assessment_456',
         payload: '{"nrsScore": 5, ...}',
         status: 'pending',
         deadline: '2024-12-06T10:00:00Z'  // 48 hours from now
       )
   │
   ▼
4. IF ONLINE: SyncProvider.syncNow() (after 2-second delay for batching)
   │
   ▼
5. SyncService.processQueue()
   │
   ├── Get all pending items
   ├── Group by type (assessments, audit logs, etc.)
   │
   └── For assessments (batch):
       │
       ▼
6. ApiClient.post('/assessments/sync/batch', body: {...})
   │
   ├── SUCCESS (HTTP 2xx):
   │   └── UPDATE sync_queue SET status = 'completed', synced_at = NOW()
   │
   └── FAILURE:
       └── UPDATE sync_queue SET
             status = 'failed',
             retry_count = retry_count + 1,
             last_error = 'Network timeout'
       │
       ▼
7. IF FAILED: Schedule retry with exponential backoff
```

### Sequence Diagram

```
┌──────┐     ┌──────────┐     ┌───────────┐     ┌───────────┐     ┌─────────┐
│ User │     │ Provider │     │  Service  │     │  Database │     │   API   │
└──┬───┘     └────┬─────┘     └─────┬─────┘     └─────┬─────┘     └────┬────┘
   │              │                 │                 │                 │
   │  Submit      │                 │                 │                 │
   │─────────────►│                 │                 │                 │
   │              │                 │                 │                 │
   │              │  saveAssessment │                 │                 │
   │              │────────────────►│                 │                 │
   │              │                 │                 │                 │
   │              │                 │  INSERT         │                 │
   │              │                 │────────────────►│                 │
   │              │                 │                 │                 │
   │              │                 │  OK             │                 │
   │              │                 │◄────────────────│                 │
   │              │                 │                 │                 │
   │              │  queueForSync   │                 │                 │
   │              │────────────────►│                 │                 │
   │              │                 │                 │                 │
   │              │                 │  INSERT queue   │                 │
   │              │                 │────────────────►│                 │
   │              │                 │                 │                 │
   │  Success!    │                 │                 │                 │
   │◄─────────────│                 │                 │                 │
   │              │                 │                 │                 │
   │              │  [2s delay]     │                 │                 │
   │              │  syncNow()      │                 │                 │
   │              │────────────────►│                 │                 │
   │              │                 │                 │                 │
   │              │                 │  POST /sync     │                 │
   │              │                 │──────────────────────────────────►│
   │              │                 │                 │                 │
   │              │                 │  200 OK         │                 │
   │              │                 │◄──────────────────────────────────│
   │              │                 │                 │                 │
   │              │                 │  UPDATE status  │                 │
   │              │                 │────────────────►│                 │
   │              │                 │                 │                 │
```

---

## Sync Queue Lifecycle

Each item in the sync queue goes through a defined lifecycle:

```
                    ┌─────────────────────────────────────────┐
                    │                                         │
                    ▼                                         │
              ┌──────────┐                                    │
              │ PENDING  │ ◄─── Item created                  │
              └────┬─────┘                                    │
                   │                                          │
                   │ syncNow() called                         │
                   ▼                                          │
              ┌──────────┐                                    │
              │ SYNCING  │ ◄─── HTTP request in progress      │
              └────┬─────┘                                    │
                   │                                          │
         ┌─────────┴─────────┐                                │
         │                   │                                │
         ▼                   ▼                                │
   ┌───────────┐       ┌──────────┐                           │
   │ COMPLETED │       │  FAILED  │ ──── retry_count < 5 ─────┘
   └───────────┘       └────┬─────┘
                            │
                            │ retry_count >= 5 OR deadline passed
                            ▼
                       ┌──────────┐
                       │ EXPIRED  │ ◄─── Needs manual attention
                       └──────────┘
```

### Status Definitions

| Status | Description | Next Action |
|--------|-------------|-------------|
| `pending` | Waiting to be synced | Will be picked up on next sync |
| `syncing` | Currently being sent to server | Wait for result |
| `completed` | Successfully synced | Cleanup after 7 days |
| `failed` | Sync failed, will retry | Automatic retry with backoff |
| `expired` | Past 48-hour deadline | Alert user, manual intervention |

---

## Retry Strategy

### Exponential Backoff

When a sync fails, we don't retry immediately. Instead, we wait progressively longer:

```
Attempt 1: Wait 1 second   (1000ms × 2^0)
Attempt 2: Wait 2 seconds  (1000ms × 2^1)
Attempt 3: Wait 4 seconds  (1000ms × 2^2)
Attempt 4: Wait 8 seconds  (1000ms × 2^3)
Attempt 5: Wait 16 seconds (1000ms × 2^4)
── Maximum 5 attempts, then marked as expired ──
```

**Why exponential backoff?**
1. **Server recovery**: If server is overloaded, constant retries make it worse
2. **Network recovery**: Transient issues often resolve themselves
3. **Battery efficiency**: Reduces unnecessary network calls
4. **Fair usage**: Doesn't flood the server with retries

### Implementation

```dart
// In ApiConfig
static int calculateRetryDelay(int attemptNumber) {
  final delay = retryBaseDelayMs *
      (retryBackoffMultiplier * attemptNumber).toInt();
  return delay.clamp(retryBaseDelayMs, retryMaxDelayMs);  // Cap at 60 seconds
}

// In SyncService
Future<List<SyncQueueItem>> getItemsToRetry() async {
  final failedItems = await getPendingItems();

  return failedItems.where((item) {
    if (!item.shouldRetry) return false;  // Max retries reached
    if (item.lastAttemptAt == null) return true;  // Never tried

    // Check if enough time has passed
    final delayMs = ApiConfig.calculateRetryDelay(item.retryCount);
    final nextRetryTime = item.lastAttemptAt!.add(
      Duration(milliseconds: delayMs),
    );

    return DateTime.now().isAfter(nextRetryTime);
  }).toList();
}
```

---

## Network Monitoring

### How Connectivity is Detected

```dart
Future<bool> _checkConnectivity() async {
  try {
    // Attempt DNS lookup
    final result = await InternetAddress.lookup('google.com')
        .timeout(Duration(seconds: 5));

    // Check if we got valid results
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException {
    return false;  // No network
  } on TimeoutException {
    return false;  // Network too slow
  }
}
```

### Connectivity Events

```dart
// In SyncProvider
void _onConnectivityChanged(bool isConnected) {
  final wasOffline = !_isOnline;
  _isOnline = isConnected;
  notifyListeners();

  // KEY BEHAVIOR: Auto-sync when coming online
  if (wasOffline && isConnected) {
    print('Sync: Came online, triggering sync...');
    syncNow();
  }
}
```

### Periodic Checks

```dart
// NetworkService checks every 30 seconds
_checkTimer = Timer.periodic(
  Duration(seconds: 30),
  (_) => _checkConnectivity(),
);

// SyncProvider auto-syncs every 15 minutes if online and has pending items
_autoSyncTimer = Timer.periodic(
  Duration(minutes: 15),
  (_) => _autoSync(),
);
```

---

## Mock API for Development

### Why Mock Mode?

During development, you often don't have a real backend. Mock mode allows:
- Development without network dependency
- Consistent test scenarios
- Simulating various server responses
- Faster development iteration

### How It Works

```dart
class ApiClient {
  Future<ApiResponse> _makeRequest({...}) async {
    // Check if mock mode is enabled
    if (_useMockApi) {
      return _mockRequest(method, url.path, body);
    }

    // Otherwise, make real HTTP request
    // ...
  }

  Future<ApiResponse> _mockRequest(
    String method,
    String endpoint,
    Map<String, dynamic>? body,
  ) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 800));

    // Route to appropriate mock handler
    if (endpoint.contains('/assessments/sync/batch')) {
      return _mockBatchSync(body);
    } else if (endpoint.contains('/assessments/sync')) {
      return _mockAssessmentSync(body);
    }
    // ... more endpoints
  }

  ApiResponse _mockAssessmentSync(Map<String, dynamic>? body) {
    return ApiResponse(
      statusCode: 201,
      body: {
        'status': 'success',
        'data': {
          'assessmentId': body?['assessmentId'],
          'syncedAt': DateTime.now().toIso8601String(),
          'message': 'Assessment successfully recorded.',
        },
      },
    );
  }
}
```

### Switching Between Mock and Real

```dart
// In api_config.dart
class ApiConfig {
  // Set to false when connecting to real backend
  static const bool useMockApi = true;

  // Update this to your real server
  static const String baseUrl = 'https://api.medpharm-trials.com/v1';
}
```

---

## Database Schema

### sync_queue Table

```sql
CREATE TABLE sync_queue (
  id TEXT PRIMARY KEY,           -- Unique identifier
  study_id TEXT NOT NULL,        -- Patient study ID
  item_type TEXT NOT NULL,       -- 'assessment', 'consent', 'auditLog', 'alert'
  data_id TEXT NOT NULL,         -- ID of the data being synced
  payload TEXT NOT NULL,         -- JSON payload to send
  status TEXT DEFAULT 'pending', -- Current status
  retry_count INTEGER DEFAULT 0, -- Number of failed attempts
  last_error TEXT,               -- Last error message
  created_at TEXT NOT NULL,      -- When item was queued
  last_attempt_at TEXT,          -- Last sync attempt time
  synced_at TEXT,                -- When successfully synced
  deadline TEXT NOT NULL         -- Must sync by this time (48h)
);

-- Indexes for efficient queries
CREATE INDEX idx_sync_queue_status ON sync_queue(status);
CREATE INDEX idx_sync_queue_deadline ON sync_queue(deadline);
```

### SyncQueueItem Model

```dart
class SyncQueueItem {
  final String id;
  final String studyId;
  final SyncItemType itemType;
  final String dataId;
  final String payload;
  final SyncItemStatus status;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final DateTime? syncedAt;
  final DateTime deadline;

  // Computed properties
  bool get isOverdue => DateTime.now().isAfter(deadline);

  bool get isApproachingDeadline {
    final warningTime = deadline.subtract(Duration(hours: 12));
    return DateTime.now().isAfter(warningTime) && !isOverdue;
  }

  bool get shouldRetry {
    return status == SyncItemStatus.failed &&
        retryCount < 5 &&
        !isOverdue;
  }
}
```

---

## Code Examples

### Example 1: Queueing Data for Sync

```dart
// After saving an assessment locally
Future<void> submitAssessment(AssessmentModel assessment) async {
  // 1. Save to local database
  await _assessmentService.saveAssessment(assessment);

  // 2. Queue for sync
  await _syncProvider.queueForSync(
    studyId: assessment.studyId,
    itemType: SyncItemType.assessment,
    dataId: assessment.id,
    payload: assessment.toApiPayload(),
  );
}
```

### Example 2: Displaying Sync Status

```dart
// In your widget
Widget build(BuildContext context) {
  return Consumer<SyncProvider>(
    builder: (context, syncProvider, child) {
      return Column(
        children: [
          // Show banner if offline or has issues
          if (!syncProvider.isOnline || syncProvider.hasFailedItems)
            SyncStatusBanner(),

          // Show sync indicator in app bar
          AppBar(
            actions: [
              SyncStatusIndicator(showLabel: true),
            ],
          ),

          // Main content
          // ...
        ],
      );
    },
  );
}
```

### Example 3: Manual Sync Trigger

```dart
ElevatedButton(
  onPressed: syncProvider.isOnline && !syncProvider.isSyncing
      ? () => syncProvider.syncNow()
      : null,
  child: syncProvider.isSyncing
      ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Syncing...'),
          ],
        )
      : Text('Sync Now'),
)
```

### Example 4: Handling Sync Completion

```dart
// In SyncProvider
Future<void> syncNow() async {
  try {
    _isSyncing = true;
    notifyListeners();

    // Process the queue
    final syncedCount = await _syncService.processQueue();

    // Retry failed items
    final retriedCount = await _syncService.retryFailedItems();

    _lastSyncedCount = syncedCount + retriedCount;

    // Refresh status
    await refreshSyncStatus();

    // Cleanup old completed items (older than 7 days)
    await _syncService.cleanupCompletedItems();

  } catch (e) {
    _errorMessage = 'Sync failed: $e';
  } finally {
    _isSyncing = false;
    notifyListeners();
  }
}
```

---

## Best Practices

### 1. Always Save Locally First

```dart
// GOOD: Local save before queue
await localDatabase.insert(data);
await syncQueue.add(data);

// BAD: Only sync (data lost if sync fails)
await api.post(data);
```

### 2. Use Meaningful Error Messages

```dart
// GOOD: Specific error
await _markItemFailed(item, 'NETWORK_TIMEOUT',
    'Server did not respond within 30 seconds');

// BAD: Generic error
await _markItemFailed(item, 'ERROR', 'Failed');
```

### 3. Respect Deadlines

```dart
// Check deadline before sync attempt
if (item.isOverdue) {
  await _markItemExpired(item);
  await _notifyUserOfOverdueItem(item);
  return;
}
```

### 4. Batch When Possible

```dart
// GOOD: Batch multiple items
await api.post('/sync/batch', body: {'items': items});

// BAD: Individual requests (N network calls)
for (final item in items) {
  await api.post('/sync', body: item);
}
```

### 5. Clean Up Old Data

```dart
// Remove completed items older than 7 days
Future<void> cleanupCompletedItems() async {
  final cutoffDate = DateTime.now()
      .subtract(Duration(days: 7))
      .toIso8601String();

  await db.delete(
    'sync_queue',
    where: 'status = ? AND synced_at < ?',
    whereArgs: ['completed', cutoffDate],
  );
}
```

### 6. Provide User Feedback

```dart
// Show progress
SyncStatusIndicator(showLabel: true)

// Show warnings
SyncStatusBanner()  // Appears when offline or items failed

// Show details on demand
SyncStatusCard()    // Full status information
```

---

## Summary

The offline-first sync mechanism provides:

1. **Reliability**: Data is never lost, even without network
2. **Performance**: Instant local saves, background sync
3. **Resilience**: Automatic retry with exponential backoff
4. **Compliance**: Deadline tracking for regulatory requirements
5. **Visibility**: Clear UI feedback on sync status
6. **Flexibility**: Mock mode for development, real mode for production

This architecture is essential for medical apps where data integrity and user experience are critical requirements.
