
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../services/database_service.dart';
import '../services/secure_storage_service.dart';

class AuditTrailService {
  final DatabaseService _databaseService;
  final SecureStorageService _secureStorage;

  AuditTrailService(this._databaseService, this._secureStorage);

  Future<void> log({
    required String studyId,
    required AuditAction action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? beforeValue,
    Map<String, dynamic>? afterValue,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final db = await _databaseService.database;
      final sessionId = await _secureStorage.getSessionId();

      final auditLog = AuditLogEntry(
        studyId: studyId,
        action: action,
        entityType: entityType,
        entityId: entityId,
        beforeValue: beforeValue,
        afterValue: afterValue,
        metadata: metadata,
        sessionId: sessionId,
      );

      await db.insert(
        'audit_logs',
        auditLog.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print(
          '📋 Audit: ${action.name} on $entityType${entityId != null ? ' ($entityId)' : ''}');
    } catch (e) {
      print('Error logging audit event: $e');
    }
  }

  Future<void> logEnrollment(String studyId) async {
    await log(
      studyId: studyId,
      action: AuditAction.userEnrolled,
      entityType: 'user',
      entityId: studyId,
      metadata: {
        'enrolled_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logConsentAccepted(String studyId) async {
    await log(
      studyId: studyId,
      action: AuditAction.consentAccepted,
      entityType: 'consent',
      metadata: {
        'accepted_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logConsentWithdrawn(String studyId) async {
    await log(
      studyId: studyId,
      action: AuditAction.consentWithdrawn,
      entityType: 'consent',
      metadata: {
        'withdrawn_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logQuestionnaireOpened(
      String studyId, String questionnaireId) async {
    await log(
      studyId: studyId,
      action: AuditAction.questionnaireOpened,
      entityType: 'questionnaire',
      entityId: questionnaireId,
    );
  }

  Future<void> logAssessmentStarted(String studyId, String assessmentId) async {
    await log(
      studyId: studyId,
      action: AuditAction.assessmentStarted,
      entityType: 'assessment',
      entityId: assessmentId,
    );
  }

  Future<void> logAnswerChanged({
    required String studyId,
    required String assessmentId,
    required String questionId,
    dynamic oldValue,
    dynamic newValue,
  }) async {
    await log(
      studyId: studyId,
      action: AuditAction.answerChanged,
      entityType: 'answer',
      entityId: questionId,
      beforeValue: {'value': oldValue},
      afterValue: {'value': newValue},
      metadata: {
        'assessment_id': assessmentId,
      },
    );
  }

  Future<void> logAssessmentSubmitted(
      String studyId, String assessmentId) async {
    await log(
      studyId: studyId,
      action: AuditAction.assessmentSubmitted,
      entityType: 'assessment',
      entityId: assessmentId,
    );
  }

  Future<void> logAssessmentSavedDraft(
      String studyId, String assessmentId) async {
    await log(
      studyId: studyId,
      action: AuditAction.assessmentSavedDraft,
      entityType: 'assessment',
      entityId: assessmentId,
    );
  }

  Future<void> logSyncStarted(String studyId, int itemCount) async {
    await log(
      studyId: studyId,
      action: AuditAction.syncStarted,
      entityType: 'sync',
      metadata: {
        'item_count': itemCount,
      },
    );
  }

  Future<void> logSyncCompleted(
      String studyId, int successCount, int failedCount) async {
    await log(
      studyId: studyId,
      action: AuditAction.syncCompleted,
      entityType: 'sync',
      metadata: {
        'success_count': successCount,
        'failed_count': failedCount,
      },
    );
  }

  Future<void> logLogin(String studyId, String method) async {
    await log(
      studyId: studyId,
      action: AuditAction.userLoggedIn,
      entityType: 'session',
      metadata: {
        'method': method,
      },
    );
  }

  Future<void> logLogout(String studyId, String reason) async {
    await log(
      studyId: studyId,
      action: AuditAction.userLoggedOut,
      entityType: 'session',
      metadata: {
        'reason': reason,
      },
    );
  }

  Future<void> logSessionTimeout(String studyId) async {
    await log(
      studyId: studyId,
      action: AuditAction.sessionTimeout,
      entityType: 'session',
    );
  }

  Future<void> logAppOpened(String studyId) async {
    await log(
      studyId: studyId,
      action: AuditAction.appOpened,
      entityType: 'app',
    );
  }

  Future<void> logAppBackgrounded(String studyId) async {
    await log(
      studyId: studyId,
      action: AuditAction.appBackgrounded,
      entityType: 'app',
    );
  }

  Future<List<AuditLogEntry>> getLogsForUser(
    String studyId, {
    int limit = 100,
  }) async {
    try {
      final db = await _databaseService.database;

      final results = await db.query(
        'audit_logs',
        where: 'study_id = ?',
        whereArgs: [studyId],
        orderBy: 'timestamp DESC',
        limit: limit,
      );

      return results.map((map) => AuditLogEntry.fromMap(map)).toList();
    } catch (e) {
      print('Error getting audit logs: $e');
      return [];
    }
  }

  Future<List<AuditLogEntry>> getUnsyncedLogs() async {
    try {
      final db = await _databaseService.database;

      final results = await db.query(
        'audit_logs',
        where: 'is_synced = 0',
        orderBy: 'timestamp ASC',
      );

      return results.map((map) => AuditLogEntry.fromMap(map)).toList();
    } catch (e) {
      print('Error getting unsynced audit logs: $e');
      return [];
    }
  }

  Future<void> markAsSynced(List<String> logIds) async {
    if (logIds.isEmpty) return;

    try {
      final db = await _databaseService.database;

      final placeholders = logIds.map((_) => '?').join(',');
      await db.rawUpdate(
        'UPDATE audit_logs SET is_synced = 1, synced_at = ? WHERE id IN ($placeholders)',
        [DateTime.now().toIso8601String(), ...logIds],
      );

      print('Marked ${logIds.length} audit logs as synced');
    } catch (e) {
      print('Error marking logs as synced: $e');
    }
  }

  Future<int> getLogCount(String studyId) async {
    try {
      final db = await _databaseService.database;

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM audit_logs WHERE study_id = ?',
        [studyId],
      );

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error counting audit logs: $e');
      return 0;
    }
  }

  Future<int> clearOldLogs({int retentionDays = 90}) async {
    try {
      final db = await _databaseService.database;

      final cutoffDate = DateTime.now()
          .subtract(Duration(days: retentionDays))
          .toIso8601String();

      final deletedCount = await db.delete(
        'audit_logs',
        where: 'is_synced = 1 AND synced_at < ?',
        whereArgs: [cutoffDate],
      );

      if (deletedCount > 0) {
        print('Cleared $deletedCount old audit logs');
      }

      return deletedCount;
    } catch (e) {
      print('Error clearing old logs: $e');
      return 0;
    }
  }
}

enum AuditAction {
  userEnrolled,
  userLoggedIn,
  userLoggedOut,
  sessionTimeout,

  consentAccepted,
  consentWithdrawn,

  questionnaireOpened,
  assessmentStarted,
  answerChanged,
  assessmentSubmitted,
  assessmentSavedDraft,

  syncStarted,
  syncCompleted,
  syncFailed,

  appOpened,
  appBackgrounded,

  settingsChanged,
  biometricEnabled,
  biometricDisabled,

  dataExported,
  dataDeleted,
}

class AuditLogEntry {
  final String id;
  final String studyId;
  final AuditAction action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? beforeValue;
  final Map<String, dynamic>? afterValue;
  final Map<String, dynamic>? metadata;
  final String? sessionId;
  final DateTime timestamp;
  final bool isSynced;
  final DateTime? syncedAt;

  AuditLogEntry({
    String? id,
    required this.studyId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.beforeValue,
    this.afterValue,
    this.metadata,
    this.sessionId,
    DateTime? timestamp,
    this.isSynced = false,
    this.syncedAt,
  })  : id = id ?? _generateId(),
        timestamp = timestamp ?? DateTime.now();

  static String _generateId() {
    final now = DateTime.now();
    return 'audit_${now.millisecondsSinceEpoch}_${now.microsecond}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'study_id': studyId,
      'action': action.name,
      'entity_type': entityType,
      'entity_id': entityId,
      'before_value': beforeValue != null ? jsonEncode(beforeValue) : null,
      'after_value': afterValue != null ? jsonEncode(afterValue) : null,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
      'session_id': sessionId,
      'timestamp': timestamp.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'synced_at': syncedAt?.toIso8601String(),
    };
  }

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    return AuditLogEntry(
      id: map['id'] as String,
      studyId: map['study_id'] as String,
      action: AuditAction.values.firstWhere(
        (a) => a.name == map['action'],
        orElse: () => AuditAction.settingsChanged,
      ),
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String?,
      beforeValue: map['before_value'] != null
          ? jsonDecode(map['before_value'] as String)
          : null,
      afterValue: map['after_value'] != null
          ? jsonDecode(map['after_value'] as String)
          : null,
      metadata: map['metadata'] != null
          ? jsonDecode(map['metadata'] as String)
          : null,
      sessionId: map['session_id'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
      syncedAt: map['synced_at'] != null
          ? DateTime.parse(map['synced_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'study_id': studyId,
      'action': action.name,
      'entity_type': entityType,
      'entity_id': entityId,
      'before_value': beforeValue,
      'after_value': afterValue,
      'metadata': metadata,
      'session_id': sessionId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AuditLogEntry(id: $id, action: ${action.name}, entityType: $entityType, timestamp: $timestamp)';
  }
}
