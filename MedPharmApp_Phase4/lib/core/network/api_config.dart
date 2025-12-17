class ApiConfig {
  static const bool useMockApi = true;

  static const int mockNetworkDelayMs = 800;

  /// Base URL for the API
  /// Production: https://api.medpharm-trials.com/v1
  /// Development: http://localhost:3000
  static const String baseUrl = 'https://api.medpharm-trials.com/v1';

  static const String apiVersion = 'v1';

  static const String enrollmentValidate = '/enrollment/validate';
  static const String enrollmentConsent = '/enrollment/consent';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

  static const String questionnaireConfig = '/questionnaires/config';
  static const String questionnairesAvailable = '/questionnaires/available';

  static const String assessmentsSync = '/assessments/sync';
  static const String assessmentsSyncBatch = '/assessments/sync/batch';

  static const String syncStatus = '/sync/status';
  static const String syncUpload = '/sync/upload';

  static const String alerts = '/alerts';

  static const String auditLog = '/audit/log';
  static const String auditLogBatch = '/audit/log/batch';

  static const int connectionTimeoutSeconds = 30;

  static const int receiveTimeoutSeconds = 30;

  static const int sendTimeoutSeconds = 60;

  static const int maxRetryAttempts = 3;

  static const int retryBaseDelayMs = 1000;

  static const int retryMaxDelayMs = 60000;

  static const double retryBackoffMultiplier = 2.0;

  static const int syncDeadlineHours = 48;

  static const int syncWarningHours = 36;

  static const int autoSyncIntervalMinutes = 360; // 6 hours

  static const int syncBatchSize = 10;

  static const int minRequestIntervalMs = 100;

  static const int maxRequestsPerMinute = 100;

  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  static int calculateRetryDelay(int attemptNumber) {
    final delay =
        retryBaseDelayMs * (retryBackoffMultiplier * attemptNumber).toInt();
    return delay.clamp(retryBaseDelayMs, retryMaxDelayMs);
  }
}

class ApiHeaders {
  static const String contentType = 'Content-Type';
  static const String authorization = 'Authorization';
  static const String appVersion = 'X-App-Version';
  static const String platform = 'X-Platform';
  static const String deviceId = 'X-Device-Id';
  static const String requestId = 'X-Request-Id';

  static const String contentTypeJson = 'application/json';
  static const String bearerPrefix = 'Bearer ';
}

class ApiErrorCodes {
  static const String invalidToken = 'INVALID_TOKEN';
  static const String tokenExpired = 'TOKEN_EXPIRED';
  static const String unauthorized = 'UNAUTHORIZED';

  static const String invalidEnrollmentCode = 'INVALID_ENROLLMENT_CODE';
  static const String codeAlreadyUsed = 'CODE_ALREADY_USED';
  static const String codeExpired = 'CODE_EXPIRED';

  static const String duplicateAssessment = 'DUPLICATE_ASSESSMENT';
  static const String outsideTimeWindow = 'OUTSIDE_TIME_WINDOW';
  static const String incompleteData = 'INCOMPLETE_DATA';
  static const String invalidScore = 'INVALID_SCORE';

  static const String syncConflict = 'SYNC_CONFLICT';
  static const String networkError = 'NETWORK_ERROR';
  static const String timeout = 'TIMEOUT';

  static const String rateLimitExceeded = 'RATE_LIMIT_EXCEEDED';
}

class AlertTypes {
  static const String missedAssessment = 'MISSED_ASSESSMENT';
  static const String syncFailure = 'SYNC_FAILURE';
  static const String highPainScore = 'HIGH_PAIN_SCORE';
  static const String suddenPainIncrease = 'SUDDEN_PAIN_INCREASE';
  static const String consentWithdrawn = 'CONSENT_WITHDRAWN';
}

class AuditEventTypes {
  static const String appInstalled = 'APP_INSTALLED';
  static const String appUninstalled = 'APP_UNINSTALLED';
  static const String userEnrolled = 'USER_ENROLLED';
  static const String consentAccepted = 'CONSENT_ACCEPTED';
  static const String consentWithdrawn = 'CONSENT_WITHDRAWN';
  static const String assessmentStarted = 'ASSESSMENT_STARTED';
  static const String assessmentCompleted = 'ASSESSMENT_COMPLETED';
  static const String assessmentAbandoned = 'ASSESSMENT_ABANDONED';
  static const String notificationReceived = 'NOTIFICATION_RECEIVED';
  static const String notificationOpened = 'NOTIFICATION_OPENED';
  static const String settingsChanged = 'SETTINGS_CHANGED';
  static const String syncInitiated = 'SYNC_INITIATED';
  static const String syncSucceeded = 'SYNC_SUCCEEDED';
  static const String syncFailed = 'SYNC_FAILED';
  static const String dataExported = 'DATA_EXPORTED';
}
