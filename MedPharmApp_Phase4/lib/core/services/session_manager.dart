import 'dart:async';
import 'package:flutter/widgets.dart';
import 'secure_storage_service.dart';
import 'audit_trail_service.dart';


class SessionManager with WidgetsBindingObserver {
  final SecureStorageService _secureStorage;
  final AuditTrailService? _auditService;

  static SessionManager? _instance;

  factory SessionManager({
    SecureStorageService? secureStorage,
    AuditTrailService? auditService,
  }) {
    _instance ??= SessionManager._internal(
      secureStorage ?? SecureStorageService(),
      auditService,
    );
    return _instance!;
  }

  SessionManager._internal(this._secureStorage, this._auditService);

  static const int defaultTimeoutMinutes = 30;
  static const int warningBeforeTimeoutMinutes = 5;

  Timer? _inactivityTimer;
  Timer? _warningTimer;

  final StreamController<SessionState> _stateController =
      StreamController<SessionState>.broadcast();

  Stream<SessionState> get stateStream => _stateController.stream;

  SessionState _currentState = SessionState.active;
  SessionState get currentState => _currentState;

  String? _studyId;

  VoidCallback? _onSessionTimeout;
  VoidCallback? _onWarning;

  Future<void> initialize({
    required String studyId,
    VoidCallback? onSessionTimeout,
    VoidCallback? onWarning,
    int timeoutMinutes = defaultTimeoutMinutes,
  }) async {
    _studyId = studyId;
    _onSessionTimeout = onSessionTimeout;
    _onWarning = onWarning;

    WidgetsBinding.instance.addObserver(this);

    final isTimedOut = await _secureStorage.isSessionTimedOut(
      timeoutMinutes: timeoutMinutes,
    );

    if (isTimedOut) {
      _updateState(SessionState.expired);
    } else {
      await startTracking(timeoutMinutes: timeoutMinutes);
    }

    print('SessionManager initialized for $studyId');
  }

  Future<void> startTracking({
    int timeoutMinutes = defaultTimeoutMinutes,
  }) async {
    await recordActivity();

    _startInactivityTimer(timeoutMinutes);

    _updateState(SessionState.active);
    print('Session tracking started (timeout: $timeoutMinutes min)');
  }

  void stopTracking() {
    _cancelTimers();
    _updateState(SessionState.inactive);
    print('Session tracking stopped');
  }

  Future<void> recordActivity() async {
    await _secureStorage.updateLastActivity();

    if (_currentState == SessionState.active ||
        _currentState == SessionState.warning) {
      _startInactivityTimer(defaultTimeoutMinutes);
    }

    if (_currentState == SessionState.warning) {
      _updateState(SessionState.active);
    }
  }

  void _startInactivityTimer(int timeoutMinutes) {
    _cancelTimers();

    final warningMinutes = timeoutMinutes - warningBeforeTimeoutMinutes;

    if (warningMinutes > 0) {
      _warningTimer = Timer(
        Duration(minutes: warningMinutes),
        _onWarningTimeout,
      );
    }

    _inactivityTimer = Timer(
      Duration(minutes: timeoutMinutes),
      _onInactivityTimeout,
    );
  }

  void _cancelTimers() {
    _warningTimer?.cancel();
    _warningTimer = null;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _onWarningTimeout() {
    print('Session timeout warning');
    _updateState(SessionState.warning);
    _onWarning?.call();
  }

  Future<void> _onInactivityTimeout() async {
    print('Session timed out due to inactivity');

    if (_studyId != null) {
      await _auditService?.logSessionTimeout(_studyId!);
    }

    _updateState(SessionState.expired);
    _onSessionTimeout?.call();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        _cancelTimers();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _onAppResumed() async {
    print('App resumed - checking session');

    final isTimedOut = await _secureStorage.isSessionTimedOut();

    if (isTimedOut) {
      print('Session expired while app was in background');
      _updateState(SessionState.expired);
      _onSessionTimeout?.call();
    } else {
      await startTracking();

      if (_studyId != null) {
        await _auditService?.logAppOpened(_studyId!);
      }
    }
  }

  Future<void> _onAppPaused() async {
    print('App paused - recording last activity');

    await recordActivity();

    _cancelTimers();

    if (_studyId != null) {
      await _auditService?.logAppBackgrounded(_studyId!);
    }
  }

  void _updateState(SessionState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);
      print('Session state: ${newState.name}');
    }
  }

  Future<bool> isSessionValid() async {
    return !await _secureStorage.isSessionTimedOut();
  }

  Future<void> extendSession() async {
    await recordActivity();
    _updateState(SessionState.active);
    print('Session extended');
  }

  Future<void> onLogin(String studyId) async {
    _studyId = studyId;

    final sessionId = _generateSessionId();
    await _secureStorage.saveSessionId(sessionId);

    await recordActivity();

    await startTracking();

    _auditService?.logLogin(studyId, 'normal');

    print('Session started for $studyId');
  }

  Future<void> onBiometricLogin(String studyId) async {
    _studyId = studyId;

    await recordActivity();

    await startTracking();

    _updateState(SessionState.active);

    _auditService?.logLogin(studyId, 'biometric');

    print('Session resumed via biometric for $studyId');
  }

  Future<void> logout({String reason = 'user_initiated'}) async {
    if (_studyId != null) {
      await _auditService?.logLogout(_studyId!, reason);
    }

    stopTracking();

    await _secureStorage.clearSession();

    _studyId = null;
    _updateState(SessionState.inactive);

    print('User logged out: $reason');
  }

  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'session_$timestamp';
  }

  void dispose() {
    _cancelTimers();
    WidgetsBinding.instance.removeObserver(this);
    _stateController.close();
    _instance = null;
  }
}

enum SessionState {
  active,
  warning,
  expired,
  inactive,
}

extension SessionStateExtension on SessionState {
  bool get isActive => this == SessionState.active;
  bool get isExpired => this == SessionState.expired;
  bool get needsReauth =>
      this == SessionState.expired || this == SessionState.inactive;
}
