# Phase 4: Offline-First Synchronization

## Overview

In Phase 4, you will implement an offline-first synchronization system. This is a critical feature for clinical trial apps where data must be captured even without internet connectivity. The scaffolding level is 20%, meaning you have minimal guidance and must apply patterns learned from previous phases.

## Prerequisites

Before starting Phase 4, you must have completed:
- Phase 1: Authentication (enrollment, consent)
- Phase 2: Pain Assessment (NRS, VAS, history)
- Phase 3: Gamification (points, badges, streaks)

If you skipped earlier phases, the code may not work correctly.

## Learning Goals

By completing Phase 4, you will learn:
1. Offline-first architecture patterns
2. Queue-based synchronization with retry logic
3. Network connectivity monitoring
4. Exponential backoff for failed requests
5. Batch sync operations for efficiency
6. Deadline tracking for regulatory compliance
7. HTTP client implementation with mock mode

## Project Structure

Phase 4 adds the following files:

```
lib/
├── core/
│   └── network/
│       ├── api_config.dart          # API endpoints, timeouts, error codes
│       └── api_client.dart          # HTTP client with mock mode
└── features/
    └── sync/
        ├── models/
        │   └── sync_models.dart     # SyncQueueItem, SyncStatus, etc.
        ├── services/
        │   ├── sync_service.dart    # Queue management, batch sync
        │   └── network_service.dart # Connectivity monitoring
        ├── providers/
        │   └── sync_provider.dart   # UI state management
        └── widgets/
            └── sync_status_widget.dart # UI components
```

## Key Concepts

### Offline-First Architecture

The app follows an offline-first pattern:
1. Data is always saved locally first
2. Items are added to a sync queue
3. When online, the queue is processed
4. Failed items are retried with exponential backoff
5. Overdue items (past 48-hour deadline) are flagged

### Sync Queue Item Lifecycle

```
[Created] -> [Pending] -> [Syncing] -> [Completed]
                |             |
                v             v
            [Failed] <--------|
                |
                v (after 48 hours)
            [Expired]
```

### Exponential Backoff

When a sync fails, the retry delay increases:
- Attempt 1: Wait 1 second
- Attempt 2: Wait 2 seconds
- Attempt 3: Wait 4 seconds
- Attempt 4: Wait 8 seconds
- Attempt 5: Wait 16 seconds (max 5 retries)

## What You Need to Implement

### Step 1: Integrate Sync with Assessment Submission

**File:** `lib/features/assessment/providers/assessment_provider.dart`

After saving an assessment locally, queue it for sync:

```dart
Future<void> submitAssessment(AssessmentModel assessment) async {
  // 1. Save locally (already implemented)
  await _assessmentService.saveAssessment(assessment);

  // 2. TODO: Queue for sync
  // Get the SyncProvider and call queueForSync()
  // You need to pass:
  // - studyId: assessment.studyId
  // - itemType: SyncItemType.assessment
  // - dataId: assessment.id
  // - payload: assessment.toApiPayload() (you need to implement this)
}
```

### Step 2: Add toApiPayload() to AssessmentModel

**File:** `lib/features/assessment/models/assessment_model.dart`

Add a method to convert the assessment to API format:

```dart
Map<String, dynamic> toApiPayload() {
  return {
    'assessmentId': id,
    'studyId': studyId,
    'timestamp': timestamp.toIso8601String(),
    'scores': {
      'nrs': nrsScore,
      'vas': vasScore,
    },
    'completedAt': DateTime.now().toIso8601String(),
  };
}
```

### Step 3: Add Sync Status to Home Screen

**File:** `lib/features/gamification/screens/home_screen.dart`

Add the sync status indicator to the app bar:

```dart
import '../../sync/widgets/sync_status_widget.dart';

// In the build method, add to AppBar:
AppBar(
  title: Text('Home'),
  actions: [
    SyncStatusIndicator(showLabel: true),
    // ... other actions
  ],
)
```

### Step 4: Add Sync Banner to Screens

Wrap your main screens with the SyncRequiredWrapper to show warnings:

```dart
import '../../sync/widgets/sync_status_widget.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SyncRequiredWrapper(
      child: // ... your screen content
    ),
  );
}
```

### Step 5: Trigger Sync After Assessment

**File:** `lib/features/assessment/screens/vas_screen.dart`

After successful submission, trigger a sync:

```dart
void _onSubmitSuccess() async {
  // Show success message

  // Trigger sync if online
  final syncProvider = context.read<SyncProvider>();
  if (syncProvider.isOnline) {
    await syncProvider.syncNow();
  }

  // Navigate to completion screen
}
```

### Step 6: Add Manual Sync Button

Create a settings or sync screen where users can manually trigger sync:

```dart
ElevatedButton.icon(
  onPressed: syncProvider.isOnline && !syncProvider.isSyncing
      ? () => syncProvider.syncNow()
      : null,
  icon: syncProvider.isSyncing
      ? CircularProgressIndicator()
      : Icon(Icons.sync),
  label: Text(syncProvider.isSyncing ? 'Syncing...' : 'Sync Now'),
)
```

## API Endpoints

The sync system uses these endpoints (defined in `api_config.dart`):

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/enrollment/validate` | POST | Validate enrollment code |
| `/enrollment/consent` | POST | Record consent |
| `/assessments/sync` | POST | Sync single assessment |
| `/assessments/sync/batch` | POST | Sync multiple assessments |
| `/sync/status` | GET | Get sync status |
| `/audit/log` | POST | Send audit logs |
| `/alerts` | POST | Send alerts |

## Mock Mode

For development without a real backend, set `useMockApi = true` in `api_config.dart`. The mock API:
- Simulates network delay (800ms)
- Returns success for valid data
- Returns appropriate errors for invalid data
- Supports batch operations

To switch to a real backend:
1. Set `useMockApi = false`
2. Update `baseUrl` to your server URL
3. Ensure your server implements the API spec

## Database Tables

Phase 4 updates the sync_queue table:

```sql
CREATE TABLE sync_queue (
  id TEXT PRIMARY KEY,
  study_id TEXT NOT NULL,
  item_type TEXT NOT NULL,        -- assessment, consent, auditLog, alert
  data_id TEXT NOT NULL,          -- ID of the data being synced
  payload TEXT NOT NULL,          -- JSON payload
  status TEXT DEFAULT 'pending',  -- pending, syncing, completed, failed, expired
  retry_count INTEGER DEFAULT 0,
  last_error TEXT,
  created_at TEXT NOT NULL,
  last_attempt_at TEXT,
  synced_at TEXT,
  deadline TEXT NOT NULL          -- 48 hours from creation
)
```

## Testing Your Implementation

1. **Reset the database** (important if upgrading from Phase 3):
   - Delete the app from your device/emulator
   - Run `flutter clean && flutter pub get`
   - Run the app fresh

2. **Test offline mode:**
   - Enable airplane mode
   - Complete an assessment
   - Verify data is saved locally
   - Check sync status shows "Offline"
   - Check pending count increases

3. **Test sync:**
   - Disable airplane mode
   - Verify sync triggers automatically
   - Check pending count goes to 0
   - Check last sync time updates

4. **Test retry logic:**
   - Set `useMockApi = false` with invalid URL
   - Submit an assessment
   - Watch retry count increase
   - Verify exponential backoff timing

5. **Test batch sync:**
   - Complete multiple assessments offline
   - Go online
   - Verify all sync together efficiently

## Common Issues

**"Provider not found" error:**
- Ensure all sync providers are in main.dart
- Check the order - services must come before providers

**Database errors after upgrading:**
- The new sync_queue schema requires fresh install
- Delete app and reinstall

**Sync not triggering:**
- Check NetworkService connectivity detection
- Verify SyncProvider is listening to connectivity changes
- Check console for sync-related logs

**Items stuck in "syncing":**
- Check for exceptions in _syncSingleItem
- Ensure status is updated on both success and failure

**Overdue items not detected:**
- Check DateTime comparison in isOverdue getter
- Verify deadline is set correctly (48 hours from creation)

## Points System Updates

With sync, you can award bonus points:

| Action | Points |
|--------|--------|
| Immediate sync (within 1 hour) | +25 |
| Same-day sync | +10 |
| Weekly sync streak | +100 |

## Advanced Topics

### Background Sync (Optional)

For true offline-first, implement background sync:

1. Use `workmanager` package for background tasks
2. Schedule periodic sync every 15 minutes
3. Handle app lifecycle (onResume triggers sync)

### Push Notifications (Optional)

When server has updates:
1. Receive push notification
2. Trigger pull sync
3. Update local data

### Conflict Resolution (Optional)

If same data modified on server and client:
1. Compare timestamps
2. Apply "last-write-wins" or merge
3. Log conflicts for audit

## Success Criteria

Your Phase 4 implementation is complete when:
- Assessments are queued for sync after submission
- Sync triggers automatically when coming online
- Failed items retry with exponential backoff
- Overdue items are flagged in UI
- Sync status indicator shows in app bar
- Manual sync button works
- Batch sync works for multiple items

## What You Learned

After completing Phase 4, you should understand:
1. Offline-first architecture principles
2. Queue-based sync with status tracking
3. Network connectivity monitoring
4. Retry logic with exponential backoff
5. Batch operations for efficiency
6. Deadline enforcement for compliance
7. HTTP client abstraction with mock mode

## Next Steps

After Phase 4, you can optionally explore:
- Background sync with WorkManager
- Push notifications for server updates
- Conflict resolution strategies
- Compression for large payloads
- End-to-end encryption for sensitive data
