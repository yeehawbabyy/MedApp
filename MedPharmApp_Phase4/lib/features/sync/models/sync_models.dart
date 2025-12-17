
enum SyncItemStatus {
  pending,    
  syncing,   
  completed,  
  failed,    
  expired,    
}

enum SyncItemType {
  assessment,    
  consent,       
  auditLog,       
  alert,          
  gamification,   
}


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

  SyncQueueItem({
    String? id,
    required this.studyId,
    required this.itemType,
    required this.dataId,
    required this.payload,
    this.status = SyncItemStatus.pending,
    this.retryCount = 0,
    this.lastError,
    DateTime? createdAt,
    this.lastAttemptAt,
    this.syncedAt,
    DateTime? deadline,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        deadline = deadline ?? DateTime.now().add(const Duration(hours: 48));

  bool get isOverdue => DateTime.now().isAfter(deadline);

  bool get isApproachingDeadline {
    final warningTime = deadline.subtract(const Duration(hours: 12));
    return DateTime.now().isAfter(warningTime) && !isOverdue;
  }

  int get hoursUntilDeadline {
    final remaining = deadline.difference(DateTime.now());
    return remaining.inHours;
  }

  bool get shouldRetry {
    return status == SyncItemStatus.failed &&
        retryCount < 5 &&
        !isOverdue;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'study_id': studyId,
      'item_type': itemType.name,
      'data_id': dataId,
      'payload': payload,
      'status': status.name,
      'retry_count': retryCount,
      'last_error': lastError,
      'created_at': createdAt.toIso8601String(),
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'deadline': deadline.toIso8601String(),
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      studyId: map['study_id'] as String,
      itemType: SyncItemType.values.firstWhere(
        (e) => e.name == map['item_type'],
      ),
      dataId: map['data_id'] as String,
      payload: map['payload'] as String,
      status: SyncItemStatus.values.firstWhere(
        (e) => e.name == map['status'],
      ),
      retryCount: map['retry_count'] as int,
      lastError: map['last_error'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastAttemptAt: map['last_attempt_at'] != null
          ? DateTime.parse(map['last_attempt_at'] as String)
          : null,
      syncedAt: map['synced_at'] != null
          ? DateTime.parse(map['synced_at'] as String)
          : null,
      deadline: DateTime.parse(map['deadline'] as String),
    );
  }

  SyncQueueItem copyWith({
    String? id,
    String? studyId,
    SyncItemType? itemType,
    String? dataId,
    String? payload,
    SyncItemStatus? status,
    int? retryCount,
    String? lastError,
    DateTime? createdAt,
    DateTime? lastAttemptAt,
    DateTime? syncedAt,
    DateTime? deadline,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      studyId: studyId ?? this.studyId,
      itemType: itemType ?? this.itemType,
      dataId: dataId ?? this.dataId,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deadline: deadline ?? this.deadline,
    );
  }

  @override
  String toString() {
    return 'SyncQueueItem($itemType: $dataId, status: $status, retries: $retryCount)';
  }
}

class SyncStatus {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final int failedCount;
  final int overdueCount;
  final DateTime? lastSyncAt;
  final String? lastError;
  final DateTime? nextScheduledSync;

  const SyncStatus({
    this.isOnline = false,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.overdueCount = 0,
    this.lastSyncAt,
    this.lastError,
    this.nextScheduledSync,
  });

  bool get isFullySynced =>
      pendingCount == 0 && failedCount == 0 && overdueCount == 0;

  bool get needsAttention => failedCount > 0 || overdueCount > 0;

  String get statusMessage {
    if (isSyncing) return 'Syncing...';
    if (!isOnline) return 'Offline';
    if (isFullySynced) return 'All synced';
    if (overdueCount > 0) return '$overdueCount overdue!';
    if (failedCount > 0) return '$failedCount failed';
    if (pendingCount > 0) return '$pendingCount pending';
    return 'Unknown';
  }

  String get statusColor {
    if (overdueCount > 0) return 'red';
    if (failedCount > 0) return 'orange';
    if (!isOnline) return 'grey';
    if (isSyncing) return 'blue';
    if (isFullySynced) return 'green';
    if (pendingCount > 0) return 'yellow';
    return 'grey';
  }

  SyncStatus copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingCount,
    int? failedCount,
    int? overdueCount,
    DateTime? lastSyncAt,
    String? lastError,
    DateTime? nextScheduledSync,
  }) {
    return SyncStatus(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      overdueCount: overdueCount ?? this.overdueCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: lastError ?? this.lastError,
      nextScheduledSync: nextScheduledSync ?? this.nextScheduledSync,
    );
  }
}

class SyncResult {
  final bool success;
  final String? errorCode;
  final String? errorMessage;
  final DateTime? syncedAt;
  final Map<String, dynamic>? serverResponse;

  const SyncResult({
    required this.success,
    this.errorCode,
    this.errorMessage,
    this.syncedAt,
    this.serverResponse,
  });

  factory SyncResult.success({
    DateTime? syncedAt,
    Map<String, dynamic>? serverResponse,
  }) {
    return SyncResult(
      success: true,
      syncedAt: syncedAt ?? DateTime.now(),
      serverResponse: serverResponse,
    );
  }

  factory SyncResult.failure({
    required String errorCode,
    required String errorMessage,
  }) {
    return SyncResult(
      success: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    if (success) return 'SyncResult(success)';
    return 'SyncResult(failed: $errorCode - $errorMessage)';
  }
}

class AuditLogEntry {
  final String id;
  final String studyId;
  final String eventType;
  final Map<String, dynamic> eventDetails;
  final DateTime timestamp;
  final String appVersion;
  final String platform;
  final String osVersion;
  final bool isSynced;

  AuditLogEntry({
    String? id,
    required this.studyId,
    required this.eventType,
    required this.eventDetails,
    DateTime? timestamp,
    required this.appVersion,
    required this.platform,
    required this.osVersion,
    this.isSynced = false,
  })  : id = id ?? 'log_${DateTime.now().millisecondsSinceEpoch}',
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'study_id': studyId,
      'event_type': eventType,
      'event_details': eventDetails.toString(),
      'timestamp': timestamp.toIso8601String(),
      'app_version': appVersion,
      'platform': platform,
      'os_version': osVersion,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  Map<String, dynamic> toApiPayload() {
    return {
      'logId': id,
      'studyId': studyId,
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType,
      'eventDetails': eventDetails,
      'deviceInfo': {
        'platform': platform,
        'osVersion': osVersion,
        'appVersion': appVersion,
      },
    };
  }

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    return AuditLogEntry(
      id: map['id'] as String,
      studyId: map['study_id'] as String,
      eventType: map['event_type'] as String,
      eventDetails: Map<String, dynamic>.from(
        map['event_details'] is String
            ? {'raw': map['event_details']}
            : map['event_details'] as Map,
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
      appVersion: map['app_version'] as String,
      platform: map['platform'] as String,
      osVersion: map['os_version'] as String,
      isSynced: map['is_synced'] == 1,
    );
  }
}

class BatchSyncResult {
  final int totalReceived;
  final int successful;
  final int failed;
  final List<SyncItemResult> results;

  const BatchSyncResult({
    required this.totalReceived,
    required this.successful,
    required this.failed,
    required this.results,
  });

  bool get isFullSuccess => failed == 0;
  bool get isPartialSuccess => successful > 0 && failed > 0;
  bool get isFullFailure => successful == 0 && failed > 0;
}

class SyncItemResult {
  final String itemId;
  final bool success;
  final String? errorCode;
  final String? errorMessage;
  final DateTime? syncedAt;

  const SyncItemResult({
    required this.itemId,
    required this.success,
    this.errorCode,
    this.errorMessage,
    this.syncedAt,
  });
}
